#!/usr/bin/env python3
"""
Pre-commit hook to remind users to update CHANGELOG.md when chart files are modified.

This script simply reminds users to update CHANGELOG.md files for any charts
that have been modified. It always succeeds but prints a reminder message.

Exit codes:
- 0: Always succeeds (just a reminder)
"""

import subprocess
import sys
from pathlib import Path
from typing import Set, List


def get_staged_files() -> List[str]:
    """Get list of staged files from git."""
    result = subprocess.run(
        ["git", "diff", "--cached", "--name-only", "--diff-filter=ACMR"],
        capture_output=True,
        text=True,
        check=True
    )
    return [f for f in result.stdout.strip().split("\n") if f]


def get_chart_directories() -> Set[Path]:
    """
    Find all directories containing Chart.yaml files.
    Returns set of chart directory paths.
    Includes both top-level charts and subcharts in */charts/* directories.
    """
    charts = set()
    repo_root = Path.cwd()

    # Find all Chart.yaml files
    for chart_file in repo_root.glob("**/Chart.yaml"):
        chart_dir = chart_file.parent

        # Exclude cache directories
        if "/.helm_ls_cache/" in str(chart_dir):
            continue

        # For charts in a charts/ directory, check if they have source files
        # to distinguish them from downloaded dependencies
        parent_charts_dir = chart_dir.parent
        if parent_charts_dir.name == "charts":
            # If there's a matching .tgz file AND no source directories, skip it
            if list(parent_charts_dir.glob(f"{chart_dir.name}*.tgz")):
                if not ((chart_dir / "templates").exists() or (chart_dir / "tests").exists()):
                    continue

        charts.add(chart_dir)

    return charts


def get_modified_charts(staged_files: List[str], charts: Set[Path]) -> Set[Path]:
    """
    Identify which charts have modifications based on staged files.

    Returns set of chart directories that have staged changes.
    """
    modified_charts = set()
    repo_root = Path.cwd()

    for chart_dir in charts:
        for file_path in staged_files:
            abs_file = repo_root / file_path

            # Check if this file is within the chart directory
            try:
                rel_path = abs_file.relative_to(chart_dir)

                # Skip if it's the CHANGELOG.md or README.md itself
                if abs_file.name in ["CHANGELOG.md", "README.md", ".helmignore"]:
                    continue

                # This file belongs to this chart
                modified_charts.add(chart_dir)
                break
            except ValueError:
                # File is not in this chart directory
                continue

    return modified_charts


def main():
    """Main entry point for pre-commit hook."""
    staged_files = get_staged_files()

    if not staged_files:
        return 0

    charts = get_chart_directories()
    modified_charts = get_modified_charts(staged_files, charts)

    if not modified_charts:
        return 0

    # Just print a friendly reminder
    print("📝 Reminder: The following charts have been modified:")
    print()

    for chart_dir in sorted(modified_charts):
        relative_path = chart_dir.relative_to(Path.cwd())
        changelog_path = chart_dir / "CHANGELOG.md"

        if changelog_path.exists():
            print(f"  📦 {relative_path}/")
            print(f"     Don't forget to update {relative_path}/CHANGELOG.md")
        else:
            print(f"  📦 {relative_path}/")
            print(f"     ⚠️  CHANGELOG.md does not exist - consider creating one")
        print()

    print("💡 Remember to:")
    print("   1. Document your changes in each chart's CHANGELOG.md")
    print("   2. Follow the format in https://keepachangelog.com/")
    print("   3. Stage your CHANGELOG.md changes with: git add <chart>/CHANGELOG.md")
    print()

    return 0


if __name__ == "__main__":
    sys.exit(main())
