#!/usr/bin/env python3
"""Tests for inject_artifacthub_changes CHANGELOG parser."""
import sys
import os
import subprocess
import tempfile
import shutil
import unittest.mock
sys.path.insert(0, os.path.dirname(__file__))

from inject_artifacthub_changes import parse_top_version_block, changes_to_yaml_string
from inject_artifacthub_changes import main as inject_main


def test_single_section():
    text = """# Changelog

## [1.0.6] - 2026-06-02

### Fixed

- Do not inject `ANTHROPIC_API_KEY` env var.

## [1.0.5] - 2026-06-01

### Changed

- Bump bitnami/common.
"""
    version, changes = parse_top_version_block(text)
    assert version == "1.0.6"
    assert changes == [{"kind": "fixed", "description": "Do not inject `ANTHROPIC_API_KEY` env var."}]


def test_multiple_sections():
    text = """## [0.34.0] - 2026-05-26

### Changed

- Update Platform application version to v26.1.0.
- Bump bitnami/common to 2.40.0.

### Fixed

- Fix pod startup failure.

## [0.33.8] - 2026-05-22
"""
    version, changes = parse_top_version_block(text)
    assert version == "0.34.0"
    assert changes == [
        {"kind": "changed", "description": "Update Platform application version to v26.1.0."},
        {"kind": "changed", "description": "Bump bitnami/common to 2.40.0."},
        {"kind": "fixed", "description": "Fix pod startup failure."},
    ]


def test_no_section_headers_defaults_to_changed():
    text = """## [0.5.0] - 2026-05-05

- Add global ingress configuration block.
- Add seqera.ingress.host template helper.

### Changed

- Update bitnami/common to 2.39.0.

## [0.4.11] - 2026-04-30
"""
    version, changes = parse_top_version_block(text)
    assert version == "0.5.0"
    assert changes == [
        {"kind": "changed", "description": "Add global ingress configuration block."},
        {"kind": "changed", "description": "Add seqera.ingress.host template helper."},
        {"kind": "changed", "description": "Update bitnami/common to 2.39.0."},
    ]


def test_multiline_bullet():
    text = """## [1.0.0] - 2026-05-11

### Changed

- **BREAKING**: Redesign provider configuration to support multiple LLM providers. The flat
  Bedrock-only values have been replaced with a structured routing layer.

## [0.5.0] - 2026-05-05
"""
    version, changes = parse_top_version_block(text)
    assert version == "1.0.0"
    assert changes == [
        {
            "kind": "changed",
            "description": "**BREAKING**: Redesign provider configuration to support multiple LLM providers. The flat Bedrock-only values have been replaced with a structured routing layer.",
        }
    ]


def test_no_version_block():
    text = "# Changelog\n\nNo releases yet.\n"
    version, changes = parse_top_version_block(text)
    assert version is None
    assert changes == []


def test_empty_version_block():
    text = """## [0.1.0] - 2026-01-01

## [0.0.1] - 2025-12-01
"""
    version, changes = parse_top_version_block(text)
    assert version == "0.1.0"
    assert changes == []


def test_all_kinds():
    text = """## [2.0.0] - 2026-01-01

### Added

- New feature.

### Deprecated

- Old API.

### Removed

- Deleted config.

### Security

- Patched CVE-2025-1234.

## [1.0.0] - 2025-01-01
"""
    version, changes = parse_top_version_block(text)
    assert version == "2.0.0"
    assert {"kind": "added", "description": "New feature."} in changes
    assert {"kind": "deprecated", "description": "Old API."} in changes
    assert {"kind": "removed", "description": "Deleted config."} in changes
    assert {"kind": "security", "description": "Patched CVE-2025-1234."} in changes


def test_unrecognised_section_heading_defaults_to_changed():
    text = """## [1.0.0] - 2026-01-01

### Bugfixes

- Fixed a thing.

## [0.9.0] - 2025-12-01
"""
    version, changes = parse_top_version_block(text)
    assert version == "1.0.0"
    assert changes == [{"kind": "changed", "description": "Fixed a thing."}]


def test_changes_to_yaml_string_basic():
    changes = [
        {"kind": "fixed", "description": "Fix the thing."},
        {"kind": "changed", "description": "Update dependency."},
    ]
    result = changes_to_yaml_string(changes)
    assert result == (
        "- kind: fixed\n"
        "  description: 'Fix the thing.'\n"
        "- kind: changed\n"
        "  description: 'Update dependency.'"
    )


def test_changes_to_yaml_string_double_quotes_pass_through():
    changes = [{"kind": "fixed", "description": 'Fix "quoted" value.'}]
    result = changes_to_yaml_string(changes)
    assert result == "- kind: fixed\n  description: 'Fix \"quoted\" value.'"


def test_changes_to_yaml_string_escapes_single_quotes():
    changes = [{"kind": "fixed", "description": "Don't break."}]
    result = changes_to_yaml_string(changes)
    assert result == "- kind: fixed\n  description: 'Don''t break.'"


def test_changes_to_yaml_string_empty():
    assert changes_to_yaml_string([]) == ""


def test_main_injects_annotation_into_real_chart():
    """End-to-end: create a temp chart dir, run main(), verify yq can read back the annotation."""
    tmpdir = tempfile.mkdtemp()
    try:
        with open(os.path.join(tmpdir, "Chart.yaml"), "w") as f:
            f.write("apiVersion: v2\nname: test-chart\nversion: 1.2.3\n")

        with open(os.path.join(tmpdir, "CHANGELOG.md"), "w") as f:
            f.write("""# Changelog

## [1.2.3] - 2026-06-05

### Fixed

- Fix the widget.

### Added

- Add new feature.

## [1.2.2] - 2026-06-01

### Changed

- Something old.
""")

        with unittest.mock.patch.dict(os.environ, {"charts_to_package": tmpdir}):
            result = inject_main()
            assert result == 0, "main() should return 0"

            proc = subprocess.run(
                ["yq", "-r", '.annotations["artifacthub.io/changes"]', os.path.join(tmpdir, "Chart.yaml")],
                capture_output=True, text=True, check=True,
            )
            annotation = proc.stdout.strip()
            assert "fixed" in annotation
            assert "Fix the widget" in annotation
            assert "added" in annotation
            assert "Add new feature" in annotation
            assert "Something old" not in annotation
    finally:
        shutil.rmtree(tmpdir)


def test_main_fails_on_version_mismatch():
    tmpdir = tempfile.mkdtemp()
    try:
        with open(os.path.join(tmpdir, "Chart.yaml"), "w") as f:
            f.write("apiVersion: v2\nname: test-chart\nversion: 1.0.0\n")
        with open(os.path.join(tmpdir, "CHANGELOG.md"), "w") as f:
            f.write("## [9.9.9] - 2026-06-05\n\n### Fixed\n\n- Something.\n")

        with unittest.mock.patch.dict(os.environ, {"charts_to_package": tmpdir}):
            result = inject_main()
            assert result == 1, "main() should return 1 on version mismatch"
    finally:
        shutil.rmtree(tmpdir)


def test_main_skips_missing_changelog():
    tmpdir = tempfile.mkdtemp()
    try:
        with open(os.path.join(tmpdir, "Chart.yaml"), "w") as f:
            f.write("apiVersion: v2\nname: test-chart\nversion: 1.0.0\n")
        # No CHANGELOG.md

        with unittest.mock.patch.dict(os.environ, {"charts_to_package": tmpdir}):
            result = inject_main()
            assert result == 0, "main() should return 0 (warn, not fail) when CHANGELOG is missing"
    finally:
        shutil.rmtree(tmpdir)


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    passed = 0
    failed = 0
    for t in tests:
        try:
            t()
            print(f"  PASS  {t.__name__}")
            passed += 1
        except AssertionError as e:
            print(f"  FAIL  {t.__name__}: {e}")
            failed += 1
    print(f"\n{passed} passed, {failed} failed")
    sys.exit(1 if failed else 0)
