"""Train a custom restaurant call bell classifier for NoriGo.

The expected dataset structure is:

ml_data/call_bell/
  train/
    not_restaurant_call_bell/
    restaurant_call_bell/
  val/
    not_restaurant_call_bell/
    restaurant_call_bell/
  test/
    not_restaurant_call_bell/
    restaurant_call_bell/
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from typing import Any


LABELS = ["not_restaurant_call_bell", "restaurant_call_bell"]
IMAGE_SIZE = (224, 224)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Train and export the NoriGo call bell TFLite classifier."
    )
    parser.add_argument("--data-dir", default="ml_data/call_bell")
    parser.add_argument("--output-dir", default="build/ml")
    parser.add_argument("--epochs", type=int, default=12)
    parser.add_argument("--fine-tune-epochs", type=int, default=4)
    parser.add_argument("--batch-size", type=int, default=24)
    parser.add_argument("--learning-rate", type=float, default=0.0003)
    return parser.parse_args()


def import_tensorflow():
    try:
        import tensorflow as tf  # type: ignore

        return tf
    except ModuleNotFoundError:
        print(
            "TensorFlow is not installed.\n\n"
            "Install it in a Python virtual environment, then rerun:\n\n"
            "  python -m venv .venv\n"
            "  .\\.venv\\Scripts\\Activate.ps1\n"
            "  python -m pip install --upgrade pip\n"
            "  python -m pip install tensorflow\n"
            "  python tools/ml/train_call_bell_classifier.py\n",
            file=sys.stderr,
        )
        raise SystemExit(1)


def assert_dataset(data_dir: Path) -> None:
    missing: list[str] = []
    for split in ["train", "val", "test"]:
        for label in LABELS:
            path = data_dir / split / label
            if not path.is_dir():
                missing.append(str(path))
    if missing:
        print("Dataset folders are missing:", file=sys.stderr)
        for path in missing:
            print(f"  - {path}", file=sys.stderr)
        raise SystemExit(1)


def dataset_from_directory(tf: Any, directory: Path, batch_size: int, shuffle: bool):
    return tf.keras.utils.image_dataset_from_directory(
        directory,
        labels="inferred",
        label_mode="int",
        class_names=LABELS,
        color_mode="rgb",
        batch_size=batch_size,
        image_size=IMAGE_SIZE,
        shuffle=shuffle,
    )


def build_model(tf: Any, learning_rate: float):
    inputs = tf.keras.Input(shape=(IMAGE_SIZE[0], IMAGE_SIZE[1], 3))
    augmentation_layers = [
        tf.keras.layers.RandomFlip("horizontal"),
        tf.keras.layers.RandomRotation(0.06),
        tf.keras.layers.RandomZoom(0.12),
    ]
    if hasattr(tf.keras.layers, "RandomBrightness"):
        augmentation_layers.append(tf.keras.layers.RandomBrightness(0.18))
    augmentation = tf.keras.Sequential(augmentation_layers, name="augmentation")

    backbone = tf.keras.applications.MobileNetV2(
        input_shape=(IMAGE_SIZE[0], IMAGE_SIZE[1], 3),
        include_top=False,
        weights="imagenet",
    )
    backbone.trainable = False

    x = augmentation(inputs)
    x = tf.keras.applications.mobilenet_v2.preprocess_input(x)
    x = backbone(x, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(0.25)(x)
    outputs = tf.keras.layers.Dense(1, activation="sigmoid")(x)

    model = tf.keras.Model(inputs, outputs, name="norigo_call_bell_labeler")
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate),
        loss=tf.keras.losses.BinaryCrossentropy(),
        metrics=[tf.keras.metrics.BinaryAccuracy(name="accuracy")],
    )
    return model, backbone


def confusion_matrix(tf: Any, model: Any, dataset: Any) -> list[list[int]]:
    y_true: list[int] = []
    y_pred: list[int] = []
    for images, labels in dataset:
        probabilities = model.predict(images, verbose=0).reshape(-1)
        y_true.extend(int(value) for value in labels.numpy().reshape(-1))
        y_pred.extend(int(value >= 0.5) for value in probabilities)
    matrix = tf.math.confusion_matrix(
        y_true,
        y_pred,
        num_classes=2,
        dtype=tf.int32,
    )
    return matrix.numpy().astype(int).tolist()


def write_labels(path: Path) -> None:
    path.write_text("\n".join(LABELS) + "\n", encoding="utf-8")


def main() -> None:
    args = parse_args()
    tf = import_tensorflow()

    data_dir = Path(args.data_dir)
    output_dir = Path(args.output_dir)
    assert_dataset(data_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    train_ds = dataset_from_directory(
        tf,
        data_dir / "train",
        args.batch_size,
        shuffle=True,
    )
    val_ds = dataset_from_directory(tf, data_dir / "val", args.batch_size, shuffle=False)
    test_ds = dataset_from_directory(
        tf,
        data_dir / "test",
        args.batch_size,
        shuffle=False,
    )

    autotune = tf.data.AUTOTUNE
    train_ds = train_ds.prefetch(autotune)
    val_ds = val_ds.prefetch(autotune)
    test_ds = test_ds.prefetch(autotune)

    model, backbone = build_model(tf, args.learning_rate)
    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_accuracy",
            patience=4,
            restore_best_weights=True,
        )
    ]
    history = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=args.epochs,
        callbacks=callbacks,
    )

    if args.fine_tune_epochs > 0:
        backbone.trainable = True
        for layer in backbone.layers[:-24]:
            layer.trainable = False
        model.compile(
            optimizer=tf.keras.optimizers.Adam(args.learning_rate * 0.1),
            loss=tf.keras.losses.BinaryCrossentropy(),
            metrics=[tf.keras.metrics.BinaryAccuracy(name="accuracy")],
        )
        fine_tune_history = model.fit(
            train_ds,
            validation_data=val_ds,
            epochs=args.fine_tune_epochs,
            callbacks=callbacks,
        )
        for key, values in fine_tune_history.history.items():
            history.history.setdefault(key, []).extend(values)

    val_loss, val_accuracy = model.evaluate(val_ds, verbose=0)
    test_loss, test_accuracy = model.evaluate(test_ds, verbose=0)
    matrix = confusion_matrix(tf, model, test_ds)

    tflite_path = output_dir / "call_bell_labeler.tflite"
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_path.write_bytes(converter.convert())

    labels_path = output_dir / "call_bell_labels.txt"
    metrics_path = output_dir / "call_bell_metrics.json"
    write_labels(labels_path)
    metrics = {
        "labels": LABELS,
        "validation_accuracy": float(val_accuracy),
        "validation_loss": float(val_loss),
        "test_accuracy": float(test_accuracy),
        "test_loss": float(test_loss),
        "confusion_matrix": matrix,
        "image_size": IMAGE_SIZE,
        "epochs_requested": args.epochs,
        "fine_tune_epochs_requested": args.fine_tune_epochs,
    }
    metrics_path.write_text(
        json.dumps(metrics, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    print(f"Validation accuracy: {val_accuracy:.4f}")
    print(f"Test accuracy: {test_accuracy:.4f}")
    print("Confusion matrix [rows=true, cols=predicted]:")
    print(matrix)
    print(f"Exported model: {tflite_path}")
    print(f"Exported labels: {labels_path}")
    print(f"Saved metrics: {metrics_path}")


if __name__ == "__main__":
    main()
