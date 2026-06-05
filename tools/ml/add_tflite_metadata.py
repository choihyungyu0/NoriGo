"""Attach ML Kit image-labeling metadata to the call bell TFLite model."""

from __future__ import annotations

import argparse
import importlib.util
from pathlib import Path
import shutil
import sys
import types


DEFAULT_MODEL = Path("build/ml/call_bell_labeler.tflite")
DEFAULT_LABELS = Path("build/ml/call_bell_labels.txt")
DEFAULT_OUTPUT = DEFAULT_MODEL
IMAGE_SIZE = (224, 224)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Attach TFLite metadata required by ML Kit custom labeling."
    )
    parser.add_argument("--model", type=Path, default=DEFAULT_MODEL)
    parser.add_argument("--labels", type=Path, default=DEFAULT_LABELS)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    return parser.parse_args()


def _install_imp_compat() -> None:
    if "imp" in sys.modules:
        return

    imp = types.ModuleType("imp")

    def find_module(name: str, path: object = None) -> object:
        spec = importlib.util.find_spec(name)
        if spec is None:
            raise ImportError(name)
        return spec

    imp.find_module = find_module  # type: ignore[attr-defined]
    sys.modules["imp"] = imp


def _load_tflite_support_modules():
    _install_imp_compat()
    try:
        from tflite_support import flatbuffers
        from tflite_support import metadata as metadata_tools
        from tflite_support import metadata_schema_py_generated as metadata_fb
    except ModuleNotFoundError as error:
        raise SystemExit(
            "tflite-support is required to attach ML Kit metadata.\n"
            "Install it in the training environment, then rerun this script."
        ) from error
    return flatbuffers, metadata_tools, metadata_fb


def _build_metadata_buffer(
    flatbuffers,
    metadata_tools,
    metadata_fb,
    labels_path: Path,
) -> bytes:
    input_image_size = metadata_fb.ImageSizeT()
    input_image_size.width = IMAGE_SIZE[0]
    input_image_size.height = IMAGE_SIZE[1]

    image_properties = metadata_fb.ImagePropertiesT()
    image_properties.colorSpace = metadata_fb.ColorSpaceType.RGB
    image_properties.defaultSize = input_image_size

    input_content = metadata_fb.ContentT()
    input_content.contentPropertiesType = metadata_fb.ContentProperties.ImageProperties
    input_content.contentProperties = image_properties

    normalization = metadata_fb.NormalizationOptionsT()
    normalization.mean = [0.0]
    normalization.std = [1.0]

    input_process_unit = metadata_fb.ProcessUnitT()
    input_process_unit.optionsType = metadata_fb.ProcessUnitOptions.NormalizationOptions
    input_process_unit.options = normalization

    input_metadata = metadata_fb.TensorMetadataT()
    input_metadata.name = "image"
    input_metadata.description = "RGB image resized to 224x224."
    input_metadata.content = input_content
    input_metadata.processUnits = [input_process_unit]

    label_file = metadata_fb.AssociatedFileT()
    label_file.name = labels_path.name
    label_file.description = "Call bell class labels."
    label_file.type = metadata_fb.AssociatedFileType.TENSOR_VALUE_LABELS

    output_metadata = metadata_fb.TensorMetadataT()
    output_metadata.name = "probability"
    output_metadata.description = "Probabilities for call bell classes."
    output_metadata.associatedFiles = [label_file]

    subgraph_metadata = metadata_fb.SubGraphMetadataT()
    subgraph_metadata.inputTensorMetadata = [input_metadata]
    subgraph_metadata.outputTensorMetadata = [output_metadata]

    model_metadata = metadata_fb.ModelMetadataT()
    model_metadata.name = "NoriGo call bell labeler"
    model_metadata.description = "Prototype restaurant call bell classifier."
    model_metadata.version = "prototype"
    model_metadata.subgraphMetadata = [subgraph_metadata]

    builder = flatbuffers.Builder(0)
    builder.Finish(
        model_metadata.Pack(builder),
        metadata_tools.MetadataPopulator.METADATA_FILE_IDENTIFIER,
    )
    return bytes(builder.Output())


def attach_metadata(model_path: Path, labels_path: Path, output_path: Path) -> None:
    if not model_path.is_file():
        raise SystemExit(f"Model not found: {model_path}")
    if not labels_path.is_file():
        raise SystemExit(f"Labels file not found: {labels_path}")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    if model_path.resolve() != output_path.resolve():
        shutil.copyfile(model_path, output_path)

    flatbuffers, metadata_tools, metadata_fb = _load_tflite_support_modules()
    metadata_buffer = _build_metadata_buffer(
        flatbuffers,
        metadata_tools,
        metadata_fb,
        labels_path,
    )

    populator = metadata_tools.MetadataPopulator.with_model_file(str(output_path))
    populator.load_metadata_buffer(bytearray(metadata_buffer))
    packed_files = set(populator.get_packed_associated_file_list())
    if labels_path.name not in packed_files:
        populator.load_associated_files([str(labels_path)])
    populator.populate()


def main() -> None:
    args = parse_args()
    attach_metadata(args.model, args.labels, args.output)
    print(f"Attached ML Kit metadata: {args.output}")


if __name__ == "__main__":
    main()
