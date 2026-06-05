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


VALID_KINDS = {"added", "changed", "deprecated", "removed", "fixed", "security"}


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
            current_kind = heading if heading in VALID_KINDS else "changed"
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


def changes_to_yaml_string(changes: list[dict]) -> str:
    """
    Serialise a list of change dicts to a YAML string suitable for the
    artifacthub.io/changes annotation value.

    Uses single-quoted YAML scalars for descriptions so that characters like
    double-quotes, backslashes, and colons are passed through without escaping.
    The only character that needs escaping in single-quoted YAML is a literal
    single-quote, which becomes ''.

    Example output:
      - kind: fixed
        description: 'Do not inject ANTHROPIC_API_KEY env var.'
    """
    lines = []
    for entry in changes:
        escaped = entry["description"].replace("'", "''")
        lines.append(f"- kind: {entry['kind']}")
        lines.append(f"  description: '{escaped}'")
    return "\n".join(lines)


def get_chart_version(chart_dir: str) -> str:
    """Read the version field from Chart.yaml using yq."""
    result = subprocess.run(
        ["yq", "-r", ".version", f"{chart_dir}/Chart.yaml"],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


def inject_annotation(chart_dir: str, yaml_string: str) -> None:
    """
    Inject artifacthub.io/changes annotation into Chart.yaml in-place using yq.
    Uses an environment variable to pass the multiline YAML string safely.
    """
    env = {**os.environ, "CHANGES_YAML": yaml_string}
    subprocess.run(
        [
            "yq",
            "-i",
            '.annotations["artifacthub.io/changes"] = strenv(CHANGES_YAML)',
            f"{chart_dir}/Chart.yaml",
        ],
        env=env,
        check=True,
    )


def main() -> int:
    charts_to_package = os.environ.get("charts_to_package", "").strip()
    if not charts_to_package:
        print("No charts to package — skipping ArtifactHub annotation injection.")
        return 0

    chart_dirs = charts_to_package.split()
    exit_code = 0

    for chart_dir in chart_dirs:
        changelog_path = os.path.join(chart_dir, "CHANGELOG.md")

        if not os.path.isfile(changelog_path):
            print(f"WARNING: {chart_dir}/CHANGELOG.md not found — skipping annotation injection.")
            continue

        with open(changelog_path) as f:
            changelog_text = f.read()

        version_from_changelog, changes = parse_top_version_block(changelog_text)

        if version_from_changelog is None:
            print(f"WARNING: {changelog_path} has no version block — skipping.")
            continue

        try:
            version_from_chart = get_chart_version(chart_dir)
        except subprocess.CalledProcessError as e:
            print(f"ERROR: Could not read version from {chart_dir}/Chart.yaml: {e}", file=sys.stderr)
            exit_code = 1
            continue

        if version_from_changelog != version_from_chart:
            print(
                f"ERROR: Version mismatch in {chart_dir}: "
                f"CHANGELOG.md top version is {version_from_changelog!r} "
                f"but Chart.yaml version is {version_from_chart!r}",
                file=sys.stderr,
            )
            exit_code = 1
            continue

        if not changes:
            print(f"WARNING: {changelog_path} top version block has no entries — skipping injection.")
            continue

        yaml_string = changes_to_yaml_string(changes)

        try:
            inject_annotation(chart_dir, yaml_string)
        except subprocess.CalledProcessError as e:
            print(f"ERROR: yq injection failed for {chart_dir}: {e}", file=sys.stderr)
            exit_code = 1
            continue

        print(f"Injected artifacthub.io/changes for {chart_dir} ({len(changes)} entries)")

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
