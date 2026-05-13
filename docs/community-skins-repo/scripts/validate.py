#!/usr/bin/env python3
"""Validate every skins/<id>/palette.json against schema.json.

Used by .github/workflows/validate.yml on every PR. Exits non-zero if
any palette is malformed or doesn't match the schema; otherwise prints
a one-line summary per palette.

Dependencies: only `jsonschema` (pip-installed in the workflow).
"""

import json
import sys
from pathlib import Path

try:
    from jsonschema import Draft7Validator
except ImportError:
    print("error: pip install jsonschema", file=sys.stderr)
    sys.exit(2)


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    schema_path = root / "schema.json"
    skins_dir = root / "skins"

    if not schema_path.exists():
        print(f"error: missing {schema_path}", file=sys.stderr)
        return 2
    if not skins_dir.exists():
        print(f"error: missing {skins_dir}", file=sys.stderr)
        return 2

    schema = json.loads(schema_path.read_text())
    validator = Draft7Validator(schema)

    palettes = sorted(skins_dir.glob("*/palette.json"))
    if not palettes:
        print("error: no skins/*/palette.json files found", file=sys.stderr)
        return 2

    failed = 0
    for p in palettes:
        skin_id = p.parent.name
        if not skin_id.replace("-", "").isalnum() or not skin_id.islower():
            print(f"✗ {skin_id}: id must be lowercase with hyphens only")
            failed += 1
            continue
        try:
            data = json.loads(p.read_text())
        except json.JSONDecodeError as e:
            print(f"✗ {skin_id}: invalid JSON — {e}")
            failed += 1
            continue
        errors = sorted(validator.iter_errors(data), key=lambda e: e.path)
        if errors:
            for e in errors:
                loc = "/".join(str(x) for x in e.path) or "<root>"
                print(f"✗ {skin_id}: {loc}: {e.message}")
            failed += 1
        else:
            print(f"✓ {skin_id}")

    if failed:
        print(f"\n{failed} skin(s) failed validation", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
