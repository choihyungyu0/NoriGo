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
IMAGE_EXTENSIONS = {".bmp", ".jpeg", ".jpg", ".png", ".webp"}


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


def image_count(directory: Path) -> int:
    return sum(
        1
        for path in directory.iterdir()
        if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS
    )


def split_image_count(data_dir: Path, split: str) -> int:
    return sum(image_count(data_dir / split / label) for label in LABELS)


def class_weights(data_dir: Path) -> dict[int, float]:
    counts = [image_count(data_dir / "train" / label) for label in LABELS]
    total = sum(counts)
    if total == 0 or any(count == 0 for count in counts):
        return {}
    return {
        index: total / (len(LABELS) * count)
        for index, count in enumerate(counts)
    }


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


def build_augmentation(tf: Any):
    augmentation_layers = [
        tf.keras.layers.RandomFlip("horizontal"),
        tf.keras.layers.RandomRotation(0.06),
        tf.keras.layers.RandomZoom(0.12),
    ]
    if hasattr(tf.keras.layers, "RandomBrightness"):
        augmentation_layers.append(tf.keras.layers.RandomBrightness(0.18))
    return tf.keras.Sequential(augmentation_layers, name="augmentation")


def build_model(tf: Any, learning_rate: float):
    inputs = tf.keras.Input(shape=(IMAGE_SIZE[0], IMAGE_SIZE[1], 3))
    backbone = tf.keras.applications.MobileNetV2(
        input_shape=(IMAGE_SIZE[0], IMAGE_SIZE[1], 3),
        include_top=False,
        weights="imagenet",
    )
    backbone.trainable = False

    x = tf.keras.applications.mobilenet_v2.preprocess_input(inputs)
    x = backbone(x, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(0.25)(x)
    outputs = tf.keras.layers.Dense(len(LABELS), activation="softmax")(x)

    model = tf.keras.Model(inputs, outputs, name="norigo_call_bell_labeler")
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate),
        loss=tf.keras.losses.SparseCategoricalCrossentropy(),
        metrics=[tf.keras.metrics.SparseCategoricalAccuracy(name="accuracy")],
    )
    return model, backbone


def confusion_matrix(tf: Any, model: Any, dataset: Any) -> list[list[int]]:
    y_true: list[int] = []
    y_pred: list[int] = []
    for images, labels in dataset:
        probabilities = model.predict(images, verbose=0)
        y_true.extend(int(value) for value in labels.numpy().reshape(-1))
        y_pred.extend(int(value) for value in tf.argmax(probabilities, axis=1).numpy())
    matrix = tf.math.confusion_matrix(
        y_true,
        y_pred,
        num_classes=2,
        dtype=tf.int32,
    )
    return matrix.numpy().astype(int).tolist()


def write_labels(path: Path) -> None:
    path.write_text("\n".join(LABELS) + "\n", encoding="utf-8")


def attach_mlkit_metadata(tflite_path: Path, labels_path: Path) -> bool:
    try:
        from add_tflite_metadata import attach_metadata

        attach_metadata(tflite_path, labels_path, tflite_path)
        return True
    except Exception as error:
        print(
            "Warning: exported TFLite model, but could not attach ML Kit "
            f"metadata ({type(error).__name__}: {error}).",
            file=sys.stderr,
        )
        return False


def main() -> None:
    args = parse_args()
    tf = import_tensorflow()

    data_dir = Path(args.data_dir)
    output_dir = Path(args.output_dir)
    assert_dataset(data_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    weights = class_weights(data_dir)

    train_ds = dataset_from_directory(
        tf,
        data_dir / "train",
        args.batch_size,
        shuffle=True,
    )
    val_ds = dataset_from_directory(tf, data_dir / "val", args.batch_size, shuffle=False)
    test_ds = None
    if split_image_count(data_dir, "test") > 0:
        test_ds = dataset_from_directory(
            tf,
            data_dir / "test",
            args.batch_size,
            shuffle=False,
        )

    autotune = tf.data.AUTOTUNE
    augmentation = build_augmentation(tf)
    train_ds = train_ds.map(
        lambda images, labels: (augmentation(images, training=True), labels),
        num_parallel_calls=autotune,
    )
    train_ds = train_ds.prefetch(autotune)
    val_ds = val_ds.prefetch(autotune)
    if test_ds is not None:
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
        class_weight=weights or None,
    )

    if args.fine_tune_epochs > 0:
        backbone.trainable = True
        for layer in backbone.layers[:-24]:
            layer.trainable = False
        model.compile(
            optimizer=tf.keras.optimizers.Adam(args.learning_rate * 0.1),
            loss=tf.keras.losses.SparseCategoricalCrossentropy(),
            metrics=[tf.keras.metrics.SparseCategoricalAccuracy(name="accuracy")],
        )
        fine_tune_history = model.fit(
            train_ds,
            validation_data=val_ds,
            epochs=args.fine_tune_epochs,
            callbacks=callbacks,
            class_weight=weights or None,
        )
        for key, values in fine_tune_history.history.items():
            history.history.setdefault(key, []).extend(values)

    val_loss, val_accuracy = model.evaluate(val_ds, verbose=0)
    test_loss = None
    test_accuracy = None
    matrix = None
    if test_ds is not None:
        test_loss, test_accuracy = model.evaluate(test_ds, verbose=0)
        matrix = confusion_matrix(tf, model, test_ds)

    tflite_path = output_dir / "call_bell_labeler.tflite"
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_path.write_bytes(converter.convert())

    labels_path = output_dir / "call_bell_labels.txt"
    metrics_path = output_dir / "call_bell_metrics.json"
    write_labels(labels_path)
    metadata_attached = attach_mlkit_metadata(tflite_path, labels_path)
    metrics = {
        "labels": LABELS,
        "validation_accuracy": float(val_accuracy),
        "validation_loss": float(val_loss),
        "test_accuracy": None if test_accuracy is None else float(test_accuracy),
        "test_loss": None if test_loss is None else float(test_loss),
        "confusion_matrix": matrix,
        "image_size": IMAGE_SIZE,
        "epochs_requested": args.epochs,
        "fine_tune_epochs_requested": args.fine_tune_epochs,
        "class_weights": weights,
        "mlkit_metadata_attached": metadata_attached,
    }
    metrics_path.write_text(
        json.dumps(metrics, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    print(f"Validation accuracy: {val_accuracy:.4f}")
    if test_accuracy is None:
        print("Test accuracy: skipped because test split is empty")
    else:
        print(f"Test accuracy: {test_accuracy:.4f}")
        print("Confusion matrix [rows=true, cols=predicted]:")
        print(matrix)
    print(f"Exported model: {tflite_path}")
    print(f"Exported labels: {labels_path}")
    print(f"ML Kit metadata attached: {metadata_attached}")
    print(f"Saved metrics: {metrics_path}")


if __name__ == "__main__":
    main()
