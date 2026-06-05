#!/usr/bin/env python3
"""
Inject ArtifactHub changes annotation into Chart.yaml.

Reads charts_to_package env var, parses each chart's CHANGELOG.md top version
block, and writes artifacthub.io/changes annotation into Chart.yaml using yq.
The modification is ephemeral — not committed back to the repo.
"""
import os
import re
import subprocess
import sys
from typing import Optional


KIND_MAP = {
    "added": "added",
    "changed": "changed",
    "deprecated": "deprecated",
    "removed": "removed",
    "fixed": "fixed",
    "security": "security",
}


def parse_top_version_block(changelog_text: str) -> tuple[Optional[str], list[dict]]:
    """
    Extract the top version block from a Keep-a-Changelog formatted file.

    Returns (version_string, list_of_change_dicts).
    version_string is e.g. "1.0.6". Returns (None, []) if no version block found.

    Each change dict: {"kind": <str>, "description": <str>}

    Handles:
    - Normal ### Kind sections
    - Bullets directly under the ## version heading (no section header) → kind="changed"
    - Multi-line bullets (continuation lines appended with a space)
    """
    lines = changelog_text.splitlines()

    # Find the first ## [x.y.z] heading
    version_line_idx = None
    version_string = None
    version_pattern = re.compile(r"^## \[([^\]]+)\]")
    for i, line in enumerate(lines):
        m = version_pattern.match(line)
        if m:
            version_string = m.group(1)
            version_line_idx = i
            break

    if version_line_idx is None:
        return None, []

    # Collect lines until the next ## [ heading
    block_lines = []
    for line in lines[version_line_idx + 1:]:
        if version_pattern.match(line):
            break
        block_lines.append(line)

    changes = _parse_block(block_lines)
    return version_string, changes


def _parse_block(block_lines: list[str]) -> list[dict]:
    """
    Parse a version block into change entries.

    Sections start with '### <Kind>'. Bullets start with '- '.
    Continuation lines (non-empty, not a new bullet or heading) are appended to the
    current bullet. Bullets outside any section default to kind='changed'.
    """
    changes = []
    current_kind = "changed"
    current_bullet: Optional[str] = None

    section_pattern = re.compile(r"^### (.+)$")
    bullet_pattern = re.compile(r"^- (.+)$")

    def flush_bullet():
        nonlocal current_bullet
        if current_bullet is not None:
            text = current_bullet.strip()
            if text:
                changes.append({"kind": current_kind, "description": text})
            current_bullet = None

    for line in block_lines:
        section_match = section_pattern.match(line)
        bullet_match = bullet_pattern.match(line)

        if section_match:
            flush_bullet()
            heading = section_match.group(1).strip().lower()
            current_kind = KIND_MAP.get(heading, "changed")
        elif bullet_match:
            flush_bullet()
            current_bullet = bullet_match.group(1)
        elif line.strip() == "":
            # Blank line ends the current bullet
            flush_bullet()
        else:
            # Continuation line
            if current_bullet is not None:
                current_bullet += " " + line.strip()

    flush_bullet()
    return changes
