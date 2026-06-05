"""Validate the local NoriGo call bell image dataset.

This script intentionally uses only the Python standard library so it can run
before TensorFlow or image tooling is installed.
"""

from __future__ import annotations

import argparse
from collections import defaultdict
from dataclasses import dataclass
from hashlib import sha256
from pathlib import Path
import sys


LABELS = ("not_restaurant_call_bell", "restaurant_call_bell")
SPLITS = ("train", "val", "test")
IMAGE_EXTENSIONS = {".bmp", ".jpeg", ".jpg", ".png", ".webp"}
GENERATED_NAME_HINTS = ("chatgpt", "dall-e", "dalle", "midjourney", "stable diffusion")


@dataclass(frozen=True)
class ImageEntry:
    split: str
    label: str
    path: Path
    digest: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate the NoriGo call bell classifier dataset."
    )
    parser.add_argument("--data-dir", default="ml_data/call_bell")
    parser.add_argument(
        "--max-class-ratio",
        type=float,
        default=2.0,
        help="Warn when the larger class is this many times the smaller class.",
    )
    return parser.parse_args()


def image_files(directory: Path) -> list[Path]:
    return sorted(
        path
        for path in directory.iterdir()
        if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS
    )


def file_digest(path: Path) -> str:
    hasher = sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def main() -> int:
    args = parse_args()
    data_dir = Path(args.data_dir)
    errors: list[str] = []
    warnings: list[str] = []
    entries: list[ImageEntry] = []
    counts: dict[tuple[str, str], int] = {}

    if not data_dir.is_dir():
        errors.append(f"Dataset directory is missing: {data_dir}")
    else:
        for split in SPLITS:
            for label in LABELS:
                directory = data_dir / split / label
                if not directory.is_dir():
                    errors.append(f"Missing folder: {directory}")
                    counts[(split, label)] = 0
                    continue

                files = image_files(directory)
                counts[(split, label)] = len(files)
                for path in files:
                    entries.append(
                        ImageEntry(
                            split=split,
                            label=label,
                            path=path,
                            digest=file_digest(path),
                        )
                    )

    print("Call bell dataset summary")
    print(f"Data dir: {data_dir}")
    for split in SPLITS:
        print(f"\n{split}:")
        for label in LABELS:
            print(f"  {label}: {counts.get((split, label), 0)}")

    for split in ("train", "val"):
        split_counts = [counts.get((split, label), 0) for label in LABELS]
        if any(count == 0 for count in split_counts):
            errors.append(f"{split} has an empty class folder.")
            continue
        smaller = min(split_counts)
        larger = max(split_counts)
        if smaller > 0 and larger / smaller > args.max_class_ratio:
            warnings.append(
                f"{split} class imbalance is {larger}:{smaller}; add more images "
                "to the smaller class when possible."
            )

    test_total = sum(counts.get(("test", label), 0) for label in LABELS)
    if test_total == 0:
        warnings.append(
            "test is empty. Keep it empty until you have real camera photos for "
            "final evaluation."
        )

    generated_entries = [
        entry
        for entry in entries
        if any(hint in entry.path.name.lower() for hint in GENERATED_NAME_HINTS)
    ]
    if generated_entries:
        warnings.append(
            f"{len(generated_entries)} image file names look AI-generated. "
            "Generated images are acceptable for prototyping, but real camera "
            "photos are needed before trusting service quality."
        )

    by_digest: dict[str, list[ImageEntry]] = defaultdict(list)
    for entry in entries:
        by_digest[entry.digest].append(entry)
    duplicate_groups = [group for group in by_digest.values() if len(group) > 1]
    if duplicate_groups:
        cross_split_groups = [
            group for group in duplicate_groups if len({entry.split for entry in group}) > 1
        ]
        warnings.append(
            f"{len(duplicate_groups)} exact duplicate image group(s) found. "
            "Remove duplicates before final training if they are not intentional."
        )
        if cross_split_groups:
            warnings.append(
                f"{len(cross_split_groups)} duplicate group(s) cross split boundaries. "
                "Move or remove them to avoid train/validation leakage."
            )
        preview = duplicate_groups[:5]
        print("\nDuplicate preview:")
        for index, group in enumerate(preview, start=1):
            print(f"  group {index}:")
            for entry in group[:4]:
                print(f"    {entry.split}/{entry.label}/{entry.path.name}")
            if len(group) > 4:
                print(f"    ... {len(group) - 4} more")

    if warnings:
        print("\nWarnings:")
        for warning in warnings:
            print(f"  - {warning}")

    if errors:
        print("\nErrors:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print("\nOK: dataset folders are valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
