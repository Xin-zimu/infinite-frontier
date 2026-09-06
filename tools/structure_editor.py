#!/usr/bin/env python3
"""Offline structure-template validator and rotation/mirror preview tool."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


ALLOWED = set(".FWDC EAXR".replace(" ", ""))


def load_catalog(path: Path) -> dict:
    root = json.loads(path.read_text(encoding="utf-8"))
    if root.get("schema_version") != 1:
        raise ValueError("unsupported structure schema version")
    templates = root.get("templates")
    if not isinstance(templates, list) or not templates:
        raise ValueError("templates must be a non-empty array")
    ids: set[str] = set()
    codes: set[int] = set()
    for template in templates:
        structure_id = template.get("id", "")
        code = template.get("code", -1)
        rows = template.get("rows", [])
        if not structure_id or structure_id in ids or not isinstance(code, int) or code < 0 or code in codes:
            raise ValueError("template IDs and codes must be unique")
        if not rows or any(not isinstance(row, str) for row in rows):
            raise ValueError(f"{structure_id}: rows must be non-empty strings")
        width = len(rows[0])
        if width == 0 or any(len(row) != width for row in rows):
            raise ValueError(f"{structure_id}: rows must be rectangular")
        unknown = set("".join(rows)) - ALLOWED
        if unknown:
            raise ValueError(f"{structure_id}: unknown glyphs {sorted(unknown)}")
        ids.add(structure_id)
        codes.add(code)
    return root


def transform(rows: list[str], rotation: int, mirrored: bool) -> list[str]:
    grid = [list(row) for row in rows]
    if mirrored:
        grid = [list(reversed(row)) for row in grid]
    for _ in range(rotation % 4):
        grid = [list(row) for row in zip(*reversed(grid))]
    return ["".join(row) for row in grid]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog", type=Path, default=Path("data/structures.json"))
    parser.add_argument("--template", help="template ID to preview")
    parser.add_argument("--rotation", type=int, choices=range(4), default=0)
    parser.add_argument("--mirror", action="store_true")
    parser.add_argument("--output", type=Path, help="optional transformed text preview")
    args = parser.parse_args()
    root = load_catalog(args.catalog)
    if not args.template:
        print(f"Validated {len(root['templates'])} structure templates.")
        return 0
    template = next((value for value in root["templates"] if value["id"] == args.template), None)
    if template is None:
        raise ValueError(f"unknown template: {args.template}")
    rendered = "\n".join(transform(template["rows"], args.rotation, args.mirror)) + "\n"
    if args.output:
        args.output.write_text(rendered, encoding="utf-8")
    else:
        print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
