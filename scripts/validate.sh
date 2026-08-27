#!/usr/bin/env bash
# Mechanical writing-bar checks for SKILL.md files and marketplace names.
# Usage: scripts/validate.sh [ROOT]
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "FAIL: python3 is required" >&2
  exit 1
fi

exec python3 - "$ROOT" <<'PY'
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(sys.argv[1]).resolve()
MAX_LINES = 200
ALLOWED_PLUGINS = {"agentkit", "saaskit"}
ACTION_VERBS = {
    "Adds",
    "Audits",
    "Checks",
    "Configures",
    "Creates",
    "Deploys",
    "Discovers",
    "Exposes",
    "Implements",
    "Installs",
    "Integrates",
    "Manages",
    "Migrates",
    "Picks",
    "Reviews",
    "Runs",
    "Sets",
    "Validates",
}
failures: list[str] = []


def fail(path: Path, message: str) -> None:
    try:
        rel = path.relative_to(ROOT)
    except ValueError:
        rel = path
    failures.append(f"FAIL {rel}: {message}")


def parse_frontmatter(text: str) -> dict[str, str] | None:
    if not text.startswith("---"):
        return None
    nl = text.find("\n")
    if nl < 0:
        return None
    end = text.find("\n---", nl)
    if end < 0:
        return None
    fm = text[nl + 1 : end]
    data: dict[str, str] = {}
    key: str | None = None
    folding = False
    buf: list[str] = []

    def flush() -> None:
        if key is None:
            return
        if folding:
            data[key] = "\n".join(buf).strip()
        else:
            data[key] = buf[0].strip().strip("'\"") if buf else ""

    for line in fm.splitlines():
        m = re.match(r"^([A-Za-z_][\w-]*)\s*:\s*(.*)$", line)
        if m and not line.startswith((" ", "\t")):
            flush()
            key = m.group(1)
            val = m.group(2).strip()
            if val in {">", "|", ">-", "|-", ">+", "|+"}:
                folding = True
                buf = []
            else:
                folding = False
                buf = [val]
            continue
        if key is not None:
            buf.append(line.strip())
    flush()
    return data


def first_word(text: str) -> str:
    cleaned = re.sub(r"\s+", " ", text).strip()
    if not cleaned:
        return ""
    return re.split(r"\s+", cleaned, maxsplit=1)[0].strip("`\"'.,:;!?")


def has_action_verb(description: str) -> bool:
    return first_word(description) in ACTION_VERBS


def check_skill(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    if len(lines) > MAX_LINES:
        fail(path, f"SKILL.md is {len(lines)} lines (max {MAX_LINES})")

    fm = parse_frontmatter(text)
    folder = path.parent.name
    if fm is None:
        fail(path, "missing YAML frontmatter")
        return

    name = fm.get("name", "").strip()
    if name != folder:
        fail(path, f"name does not match folder (got {name!r}, folder {folder!r})")

    desc = fm.get("description", "")
    if not has_action_verb(desc):
        fail(path, "description missing action verb")
    if not re.search(r"Use when", desc, re.I):
        fail(path, "description missing 'Use when'")
    if not re.search(r"It does not", desc, re.I):
        fail(path, "description missing sibling 'It does not'")
    elif not re.search(r"that's\s+`", desc, re.I):
        fail(path, "description missing sibling 'It does not' pointer (that's `name`)")


def iter_json(pattern: str):
    for path in sorted(ROOT.rglob(pattern)):
        if "node_modules" in path.parts:
            continue
        yield path


def check_marketplace(path: Path) -> None:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(path, f"invalid JSON ({exc})")
        return
    for plugin in data.get("plugins") or []:
        name = plugin.get("name", "")
        if name not in ALLOWED_PLUGINS:
            fail(path, f"plugin name {name!r} is not allowed (only agentkit, saaskit)")


def check_plugin_json(path: Path) -> None:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(path, f"invalid JSON ({exc})")
        return
    name = data.get("name", "")
    if name not in ALLOWED_PLUGINS:
        fail(path, f"plugin name {name!r} is not allowed (only agentkit, saaskit)")


skills = [p for p in iter_json("SKILL.md")]
for skill in skills:
    check_skill(skill)
for market in iter_json("marketplace.json"):
    check_marketplace(market)
for plugin in iter_json("plugin.json"):
    check_plugin_json(plugin)

if failures:
    print("\n".join(failures), file=sys.stderr)
    sys.exit(1)

print(f"OK: {len(skills)} skills, marketplace names are agentkit and saaskit")
PY
