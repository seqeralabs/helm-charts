#!/usr/bin/env python3
"""
Pre-commit hook to draft CHANGELOG.md entries with Claude Code.

This hook looks for staged chart changes that do not yet include a staged
CHANGELOG.md update, asks Claude Code to draft Keep a Changelog entries for
each affected chart, inserts the generated entries into the chart's
CHANGELOG.md, and stages the result.
"""

from __future__ import annotations

import json
import os
import re
import shlex
import shutil
import subprocess
import sys
from datetime import date
from pathlib import Path
from typing import Dict, Iterable, List, Sequence, Set


SKIP_FILENAMES = {"CHANGELOG.md", "README.md", ".helmignore"}
VALID_CATEGORIES = (
    "Added",
    "Changed",
    "Deprecated",
    "Removed",
    "Fixed",
    "Security",
)
DEFAULT_CATEGORY = "Changed"
MAX_DIFF_CHARS = 20000
MAX_CHANGELOG_CONTEXT_CHARS = 6000
CLAUDE_BIN_ENV = "CLAUDE_CHANGELOG_WRITER_BIN"


def run_git(args: Sequence[str], *, input_text: str | None = None) -> str:
    """Run a git command in the repository and return stdout."""
    result = subprocess.run(
        ["git", *args],
        input=input_text,
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout


def get_staged_files() -> List[str]:
    """Get list of staged files from git."""
    output = run_git(["diff", "--cached", "--name-only", "--diff-filter=ACMR"])
    return [line for line in output.strip().splitlines() if line]


def get_chart_directories() -> Set[Path]:
    """
    Find all directories containing Chart.yaml files.

    Includes both top-level charts and source subcharts, while skipping cached
    content and packaged dependencies.
    """
    charts: Set[Path] = set()
    repo_root = Path.cwd()

    for chart_file in repo_root.glob("**/Chart.yaml"):
        chart_dir = chart_file.parent

        if "/.helm_ls_cache/" in str(chart_dir):
            continue

        parent_dir = chart_dir.parent
        if parent_dir.name == "charts":
            if list(parent_dir.glob(f"{chart_dir.name}*.tgz")):
                if not ((chart_dir / "templates").exists() or (chart_dir / "tests").exists()):
                    continue

        charts.add(chart_dir)

    return charts


def get_modified_charts(staged_files: Iterable[str], charts: Set[Path]) -> Set[Path]:
    """Identify chart directories that have staged non-doc changes."""
    modified_charts: Set[Path] = set()
    repo_root = Path.cwd()

    for chart_dir in charts:
        for file_path in staged_files:
            abs_file = repo_root / file_path

            try:
                abs_file.relative_to(chart_dir)
            except ValueError:
                continue

            if abs_file.name in SKIP_FILENAMES:
                continue

            modified_charts.add(chart_dir)
            break

    return modified_charts


def get_charts_missing_changelog_update(
    staged_files: List[str], modified_charts: Set[Path]
) -> List[Path]:
    """Return modified charts whose CHANGELOG.md is not yet staged."""
    repo_root = Path.cwd()
    staged_set = set(staged_files)
    missing: List[Path] = []

    for chart_dir in sorted(modified_charts):
        changelog_rel = str(chart_dir.relative_to(repo_root) / "CHANGELOG.md")
        if changelog_rel not in staged_set:
            missing.append(chart_dir)

    return missing


def get_staged_chart_files(chart_dir: Path, staged_files: Iterable[str]) -> List[str]:
    """Return staged, non-doc files belonging to a chart."""
    repo_root = Path.cwd()
    chart_files: List[str] = []

    for file_path in staged_files:
        abs_file = repo_root / file_path

        try:
            abs_file.relative_to(chart_dir)
        except ValueError:
            continue

        if abs_file.name in SKIP_FILENAMES:
            continue

        chart_files.append(file_path)

    return sorted(chart_files)


def get_staged_diff(file_paths: Sequence[str]) -> str:
    """Return the staged diff for the given files."""
    if not file_paths:
        return ""

    diff = run_git(["diff", "--cached", "--unified=0", "--", *file_paths])
    if len(diff) <= MAX_DIFF_CHARS:
        return diff

    return diff[:MAX_DIFF_CHARS] + "\n\n[diff truncated]\n"


def get_chart_version(chart_dir: Path) -> str:
    """Read the chart version from Chart.yaml without external dependencies."""
    chart_yaml = chart_dir / "Chart.yaml"
    for line in chart_yaml.read_text(encoding="utf-8").splitlines():
        match = re.match(r"^version:\s*[\"']?([^\"'#]+)", line)
        if match:
            return match.group(1).strip()

    raise ValueError(f"Could not find version in {chart_yaml}")


def resolve_claude_command() -> List[str]:
    """Resolve the Claude Code binary to invoke."""
    configured = os.environ.get(CLAUDE_BIN_ENV)
    if configured:
        return shlex.split(configured)

    claude_path = shutil.which("claude")
    if claude_path:
        return [claude_path]

    raise FileNotFoundError(
        "Claude Code CLI was not found in PATH. "
        f"Install `claude` or set {CLAUDE_BIN_ENV} to the command to run."
    )


def build_prompt(
    chart_dir: Path,
    version: str,
    staged_chart_files: Sequence[str],
    changelog_text: str,
    staged_diff: str,
) -> str:
    """Build the prompt sent to Claude Code."""
    repo_root = Path.cwd()
    relative_chart = chart_dir.relative_to(repo_root)
    changelog_context = changelog_text[:MAX_CHANGELOG_CONTEXT_CHARS]

    return f"""You are drafting release notes for a Helm chart CHANGELOG.md entry.

Return strict JSON only, with no markdown fences and no explanation, in exactly this shape:
{{
  "entries": [
    {{"category": "Changed", "text": "..." }}
  ]
}}

Rules:
- Use only these categories: {", ".join(VALID_CATEGORIES)}.
- Write 1 to 4 concise bullet texts total.
- Match the existing Keep a Changelog style in the provided CHANGELOG.md.
- Describe only the staged changes shown here.
- Do not include version numbers or dates unless they are essential to the change itself.
- Prefer "Changed" unless another category is clearly better.
- Keep each bullet self-contained and user-facing.

Chart path: {relative_chart}
Chart version: {version}
Staged files:
{os.linesep.join(f"- {path}" for path in staged_chart_files)}

Existing CHANGELOG.md context:
{changelog_context}

Staged diff:
{staged_diff}
"""


def call_claude(prompt: str) -> Dict[str, object]:
    """Call Claude Code in print mode and parse the structured response."""
    command = [
        *resolve_claude_command(),
        "-p",
        "--output-format",
        "json",
        "--max-turns",
        "1",
    ]

    result = subprocess.run(
        command,
        input=prompt,
        capture_output=True,
        text=True,
        check=True,
    )

    payload = json.loads(result.stdout)
    if payload.get("is_error"):
        raise RuntimeError(payload.get("result") or "Claude Code returned an error")

    content = payload.get("result")
    if not isinstance(content, str):
        raise ValueError("Claude Code JSON response did not include a text result")

    parsed = json.loads(content)
    if not isinstance(parsed, dict):
        raise ValueError("Claude Code result must be a JSON object")

    return parsed


def normalize_entries(raw_entries: object) -> List[Dict[str, str]]:
    """Validate and normalize Claude output."""
    if not isinstance(raw_entries, list):
        raise ValueError("Claude Code result must contain an 'entries' list")

    entries: List[Dict[str, str]] = []
    seen = set()

    for raw_entry in raw_entries:
        if not isinstance(raw_entry, dict):
            raise ValueError("Each changelog entry must be a JSON object")

        category = str(raw_entry.get("category", DEFAULT_CATEGORY)).strip().title()
        if category not in VALID_CATEGORIES:
            category = DEFAULT_CATEGORY

        text = str(raw_entry.get("text", "")).strip()
        text = re.sub(r"^\s*[-*]\s*", "", text)
        text = re.sub(r"\s+", " ", text).strip()

        if not text:
            continue

        key = (category, text)
        if key in seen:
            continue

        seen.add(key)
        entries.append({"category": category, "text": text})

    if not entries:
        raise ValueError("Claude Code did not produce any changelog entries")

    return entries


def find_release_block_bounds(content: str, version: str) -> tuple[int, int] | None:
    """Return the slice bounds for a release block, if present."""
    heading_pattern = re.compile(rf"^## \[{re.escape(version)}\] - .*$", re.MULTILINE)
    heading_match = heading_pattern.search(content)
    if not heading_match:
        return None

    next_heading_pattern = re.compile(r"^## \[", re.MULTILINE)
    next_heading_match = next_heading_pattern.search(content, heading_match.end())

    start = heading_match.start()
    end = next_heading_match.start() if next_heading_match else len(content)
    return start, end


def merge_entries_into_release_block(release_block: str, entries: Sequence[Dict[str, str]]) -> str:
    """Insert generated entries into an existing release block."""
    updated = release_block.rstrip()

    for category in VALID_CATEGORIES:
        category_entries = [entry["text"] for entry in entries if entry["category"] == category]
        if not category_entries:
            continue

        category_pattern = re.compile(
            rf"(^### {re.escape(category)}\n\n)(.*?)(?=\n### |\n## |\Z)",
            re.MULTILINE | re.DOTALL,
        )
        match = category_pattern.search(updated)

        if match:
            existing_body = match.group(2).rstrip()
            existing_lines = [line.strip() for line in existing_body.splitlines() if line.strip()]
            missing_lines = [
                f"- {text}"
                for text in category_entries
                if f"- {text}" not in existing_lines
            ]
            if not missing_lines:
                continue

            new_body = existing_body + ("\n" if existing_body else "") + "\n".join(missing_lines)
            updated = updated[:match.start()] + match.group(1) + new_body + updated[match.end():]
            continue

        insert_block = f"\n\n### {category}\n\n" + "\n".join(f"- {text}" for text in category_entries)
        updated += insert_block

    return updated + "\n\n"


def create_release_block(version: str, entries: Sequence[Dict[str, str]]) -> str:
    """Create a new release block for the current chart version."""
    lines = [f"## [{version}] - {date.today().isoformat()}"]

    for category in VALID_CATEGORIES:
        category_entries = [entry["text"] for entry in entries if entry["category"] == category]
        if not category_entries:
            continue

        lines.extend(["", f"### {category}", ""])
        lines.extend(f"- {text}" for text in category_entries)

    return "\n".join(lines).rstrip() + "\n\n"


def insert_release_block(content: str, release_block: str) -> str:
    """Insert a new release block before the first existing release heading."""
    first_release = re.search(r"^## \[", content, re.MULTILINE)
    if not first_release:
        return content.rstrip() + "\n\n" + release_block

    return content[:first_release.start()] + release_block + content[first_release.start():]


def update_changelog(chart_dir: Path, version: str, entries: Sequence[Dict[str, str]]) -> bool:
    """Update a chart changelog in place and stage it. Returns True if changed."""
    changelog_path = chart_dir / "CHANGELOG.md"
    original = changelog_path.read_text(encoding="utf-8")

    release_bounds = find_release_block_bounds(original, version)
    if release_bounds:
        start, end = release_bounds
        release_block = original[start:end]
        merged = merge_entries_into_release_block(release_block, entries)
        updated = original[:start] + merged + original[end:]
    else:
        updated = insert_release_block(original, create_release_block(version, entries))

    if updated == original:
        return False

    changelog_path.write_text(updated, encoding="utf-8")
    run_git(["add", str(changelog_path.relative_to(Path.cwd()))])
    return True


def main() -> int:
    """Main entry point for the pre-commit hook."""
    staged_files = get_staged_files()
    if not staged_files:
        return 0

    charts = get_chart_directories()
    modified_charts = get_modified_charts(staged_files, charts)
    charts_to_update = get_charts_missing_changelog_update(staged_files, modified_charts)

    if not charts_to_update:
        return 0

    try:
        resolve_claude_command()
    except FileNotFoundError as exc:
        print(f"Failed to draft changelog entries: {exc}", file=sys.stderr)
        return 1

    drafted_any = False

    for chart_dir in charts_to_update:
        staged_chart_files = get_staged_chart_files(chart_dir, staged_files)
        if not staged_chart_files:
            continue

        version = get_chart_version(chart_dir)
        changelog_path = chart_dir / "CHANGELOG.md"
        changelog_text = changelog_path.read_text(encoding="utf-8")
        staged_diff = get_staged_diff(staged_chart_files)
        prompt = build_prompt(chart_dir, version, staged_chart_files, changelog_text, staged_diff)

        try:
            response = call_claude(prompt)
            entries = normalize_entries(response.get("entries"))
            changed = update_changelog(chart_dir, version, entries)
        except (json.JSONDecodeError, subprocess.CalledProcessError, RuntimeError, ValueError) as exc:
            relative_chart = chart_dir.relative_to(Path.cwd())
            print(
                f"Failed to draft changelog entries for {relative_chart}: {exc}",
                file=sys.stderr,
            )
            return 1

        if changed:
            drafted_any = True
            relative_changelog = changelog_path.relative_to(Path.cwd())
            print(f"Drafted changelog entries in {relative_changelog}")

    if drafted_any:
        print(
            "Review the generated CHANGELOG.md updates and re-run the commit if "
            "pre-commit stops after file modifications."
        )

    return 0


if __name__ == "__main__":
    sys.exit(main())
