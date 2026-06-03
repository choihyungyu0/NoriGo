"""Fail if local ML datasets are accidentally bundled as Flutter assets."""

from __future__ import annotations

from pathlib import Path
import sys


PUBSPEC = Path("pubspec.yaml")
FORBIDDEN_ASSETS = (
    "ml_data/",
    "ml_data/call_bell/",
    "train/",
    "val/",
    "test/",
)


def flutter_asset_entries(pubspec_text: str) -> list[str]:
    entries: list[str] = []
    in_assets = False
    assets_indent = 0

    for raw_line in pubspec_text.splitlines():
        line = raw_line.rstrip()
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        indent = len(line) - len(line.lstrip(" "))
        if not in_assets and stripped == "assets:":
            in_assets = True
            assets_indent = indent
            continue

        if in_assets and indent <= assets_indent:
            break

        if in_assets and stripped.startswith("- "):
            entry = stripped[2:].strip().strip("'\"")
            if entry:
                entries.append(entry)

    return entries


def main() -> int:
    if not PUBSPEC.exists():
        print("pubspec.yaml not found.", file=sys.stderr)
        return 1

    entries = flutter_asset_entries(PUBSPEC.read_text(encoding="utf-8"))
    violations = [
        entry
        for entry in entries
        if any(
            entry == forbidden or entry.startswith(forbidden)
            for forbidden in FORBIDDEN_ASSETS
        )
    ]

    if violations:
        print("ML dataset paths must not be bundled as Flutter assets:")
        for entry in violations:
            print(f"  - {entry}")
        return 1

    print("OK: ml_data is not bundled in Flutter assets.")
    if "assets/ml/" in entries:
        print("OK: runtime ML assets use assets/ml/.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
