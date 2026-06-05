# ArtifactHub Changes Annotation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Inject `artifacthub.io/changes` annotations into each chart's `Chart.yaml` during CI so ArtifactHub displays a structured changelog for every published chart version.

**Architecture:** A new Python script `.github/scripts/inject_artifacthub_changes.py` reads `charts_to_package` from the environment, parses the top version block from each chart's `CHANGELOG.md`, maps Keep-a-Changelog section headings to ArtifactHub kinds, and uses `yq` to inject the annotation into `Chart.yaml` in-place before `helm package` runs. The modification is ephemeral (not committed).

**Tech Stack:** Python 3, `yq` v4 (mikefarah/yq, already in CI), GitHub Actions workflow YAML.

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `.github/scripts/inject_artifacthub_changes.py` | Parse CHANGELOG, inject annotation via yq |
| Modify | `.github/workflows/build-helm-charts.yaml` | Add new step before "Build Helm charts" |

---

### Task 1: Write and test the CHANGELOG parser

**Files:**
- Create: `.github/scripts/inject_artifacthub_changes.py`

The parser must handle:
- Normal sections: `### Added`, `### Changed`, `### Fixed`, `### Removed`, `### Deprecated`, `### Security`
- Bullets that span multiple lines (continuation lines indented or starting without `- `)
- Version blocks with no recognised `### Kind` headers (e.g. `[0.5.0]` in agent-backend CHANGELOG which has bullets directly under the version heading with no section header) — treat as `changed`
- Bullets containing backtick-quoted text, markdown links, pipes (`|`), and asterisks — emit them as plain text (no escaping needed for YAML scalar string)

- [ ] **Step 1: Create the script with the CHANGELOG parsing function**

Create `.github/scripts/inject_artifacthub_changes.py`:

```python
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
```

- [ ] **Step 2: Write tests for the parser**

Create `.github/scripts/test_inject_artifacthub_changes.py`:

```python
#!/usr/bin/env python3
"""Tests for inject_artifacthub_changes CHANGELOG parser."""
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from inject_artifacthub_changes import parse_top_version_block


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
    assert len(changes) == 1
    assert changes[0]["kind"] == "changed"
    assert "Redesign provider configuration" in changes[0]["description"]
    assert "structured routing layer" in changes[0]["description"]


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
```

- [ ] **Step 3: Run the tests — expect them to fail (function not yet complete)**

```bash
cd /home/alberto/repos/helm-charts
python3 .github/scripts/test_inject_artifacthub_changes.py
```

Expected: failures or import errors since the script only has the parser but `parse_top_version_block` is defined — tests should pass for the parser. If any test fails, fix the parser logic before proceeding.

- [ ] **Step 4: Verify all tests pass**

```bash
python3 .github/scripts/test_inject_artifacthub_changes.py
```

Expected output ends with: `N passed, 0 failed`

- [ ] **Step 5: Commit**

```bash
git add .github/scripts/inject_artifacthub_changes.py .github/scripts/test_inject_artifacthub_changes.py
git commit -m "feat: add ArtifactHub changes annotation injector (parser + tests)"
```

---

### Task 2: Add YAML serialisation and yq injection

**Files:**
- Modify: `.github/scripts/inject_artifacthub_changes.py` — add `changes_to_yaml_string`, `get_chart_version`, and `inject_annotation` functions

- [ ] **Step 1: Add the serialisation and injection helpers to the script**

Append these functions to `.github/scripts/inject_artifacthub_changes.py` (before `if __name__ == "__main__":`):

```python
def changes_to_yaml_string(changes: list[dict]) -> str:
    """
    Serialise a list of change dicts to a YAML string suitable for the
    artifacthub.io/changes annotation value.

    Example output:
      - kind: fixed
        description: Do not inject ANTHROPIC_API_KEY env var.
    """
    lines = []
    for entry in changes:
        # Escape double-quotes in description for safe YAML scalar
        desc = entry["description"].replace('"', '\\"')
        lines.append(f'- kind: {entry["kind"]}')
        lines.append(f'  description: "{desc}"')
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
```

- [ ] **Step 2: Add tests for serialisation**

Append to `.github/scripts/test_inject_artifacthub_changes.py`:

```python
from inject_artifacthub_changes import changes_to_yaml_string


def test_changes_to_yaml_string_basic():
    changes = [
        {"kind": "fixed", "description": "Fix the thing."},
        {"kind": "changed", "description": "Update dependency."},
    ]
    result = changes_to_yaml_string(changes)
    assert result == (
        '- kind: fixed\n'
        '  description: "Fix the thing."\n'
        '- kind: changed\n'
        '  description: "Update dependency."'
    )


def test_changes_to_yaml_string_escapes_double_quotes():
    changes = [{"kind": "fixed", "description": 'Fix "quoted" value.'}]
    result = changes_to_yaml_string(changes)
    assert '\\\"quoted\\\"' in result or '\\"quoted\\"' in result


def test_changes_to_yaml_string_empty():
    assert changes_to_yaml_string([]) == ""
```

- [ ] **Step 3: Run tests**

```bash
cd /home/alberto/repos/helm-charts
python3 .github/scripts/test_inject_artifacthub_changes.py
```

Expected: all tests pass, `N passed, 0 failed`

- [ ] **Step 4: Commit**

```bash
git add .github/scripts/inject_artifacthub_changes.py .github/scripts/test_inject_artifacthub_changes.py
git commit -m "feat: add YAML serialisation and yq injection helpers"
```

---

### Task 3: Add the main entrypoint and version cross-check

**Files:**
- Modify: `.github/scripts/inject_artifacthub_changes.py` — add `main()` function

- [ ] **Step 1: Add `main()` to the script**

Append to `.github/scripts/inject_artifacthub_changes.py`:

```python
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
```

- [ ] **Step 2: Add integration test against a real chart directory**

Append to `.github/scripts/test_inject_artifacthub_changes.py`:

```python
import tempfile
import shutil
import subprocess

from inject_artifacthub_changes import main as inject_main


def test_main_injects_annotation_into_real_chart():
    """End-to-end: create a temp chart dir, run main(), verify yq can read back the annotation."""
    tmpdir = tempfile.mkdtemp()
    try:
        # Minimal Chart.yaml
        with open(os.path.join(tmpdir, "Chart.yaml"), "w") as f:
            f.write("apiVersion: v2\nname: test-chart\nversion: 1.2.3\n")

        # Matching CHANGELOG.md
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

        os.environ["charts_to_package"] = tmpdir
        result = inject_main()
        assert result == 0, "main() should return 0"

        # Read back the annotation with yq
        proc = subprocess.run(
            ["yq", '-r', '.annotations["artifacthub.io/changes"]', os.path.join(tmpdir, "Chart.yaml")],
            capture_output=True, text=True, check=True,
        )
        annotation = proc.stdout.strip()
        assert "fixed" in annotation
        assert "Fix the widget" in annotation
        assert "added" in annotation
        assert "Add new feature" in annotation
        # Should NOT contain entries from the second version block
        assert "Something old" not in annotation
    finally:
        del os.environ["charts_to_package"]
        shutil.rmtree(tmpdir)


def test_main_fails_on_version_mismatch():
    tmpdir = tempfile.mkdtemp()
    try:
        with open(os.path.join(tmpdir, "Chart.yaml"), "w") as f:
            f.write("apiVersion: v2\nname: test-chart\nversion: 1.0.0\n")
        with open(os.path.join(tmpdir, "CHANGELOG.md"), "w") as f:
            f.write("## [9.9.9] - 2026-06-05\n\n### Fixed\n\n- Something.\n")

        os.environ["charts_to_package"] = tmpdir
        result = inject_main()
        assert result == 1, "main() should return 1 on version mismatch"
    finally:
        del os.environ["charts_to_package"]
        shutil.rmtree(tmpdir)


def test_main_skips_missing_changelog():
    tmpdir = tempfile.mkdtemp()
    try:
        with open(os.path.join(tmpdir, "Chart.yaml"), "w") as f:
            f.write("apiVersion: v2\nname: test-chart\nversion: 1.0.0\n")
        # No CHANGELOG.md

        os.environ["charts_to_package"] = tmpdir
        result = inject_main()
        assert result == 0, "main() should return 0 (warn, not fail) when CHANGELOG is missing"
    finally:
        del os.environ["charts_to_package"]
        shutil.rmtree(tmpdir)
```

- [ ] **Step 3: Run all tests**

```bash
cd /home/alberto/repos/helm-charts
python3 .github/scripts/test_inject_artifacthub_changes.py
```

Expected: all tests pass, `N passed, 0 failed`

- [ ] **Step 4: Smoke-test against the real platform chart**

```bash
cd /home/alberto/repos/helm-charts
charts_to_package="charts/platform" python3 .github/scripts/inject_artifacthub_changes.py
```

Expected output: `Injected artifacthub.io/changes for charts/platform (N entries)`

Verify the annotation was written:

```bash
yq -r '.annotations["artifacthub.io/changes"]' charts/platform/Chart.yaml
```

Expected: a YAML list of `kind`/`description` entries matching the top block of `charts/platform/CHANGELOG.md`.

Restore Chart.yaml (the CI working tree modification must not be committed):

```bash
git checkout charts/platform/Chart.yaml
```

- [ ] **Step 5: Commit**

```bash
git add .github/scripts/inject_artifacthub_changes.py .github/scripts/test_inject_artifacthub_changes.py
git commit -m "feat: add main() with version cross-check and integration tests"
```

---

### Task 4: Wire the script into the CI workflow

**Files:**
- Modify: `.github/workflows/build-helm-charts.yaml` — add one step after "Extract list of changed Helm charts"

- [ ] **Step 1: Add the new workflow step**

In `.github/workflows/build-helm-charts.yaml`, find this block (around line 34):

```yaml
      - name: Extract list of changed Helm charts
        id: extract-charts
        # This script defines the charts_to_package env var with a space-separated list of charts to
        # package based on the changed files
        run: python3 .github/scripts/extract_charts.py

      - name: Run chart test linter
```

Replace it with:

```yaml
      - name: Extract list of changed Helm charts
        id: extract-charts
        # This script defines the charts_to_package env var with a space-separated list of charts to
        # package based on the changed files
        run: python3 .github/scripts/extract_charts.py

      - name: Inject ArtifactHub changes annotation
        if: env.charts_to_package != ''
        run: python3 .github/scripts/inject_artifacthub_changes.py

      - name: Run chart test linter
```

- [ ] **Step 2: Verify the workflow YAML is valid**

```bash
cd /home/alberto/repos/helm-charts
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/build-helm-charts.yaml'))" && echo "YAML valid"
```

Expected: `YAML valid`

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/build-helm-charts.yaml
git commit -m "ci: inject artifacthub.io/changes annotation before helm package"
```

---

## Self-Review Checklist

- [x] **Spec coverage**
  - Parse top version block → Task 1
  - Map Keep-a-Changelog headings to ArtifactHub kinds → Task 1
  - Bullets with multi-line continuation → Task 1 (test included)
  - Version cross-check (mismatch = fail) → Task 3
  - Skip on missing CHANGELOG (warn, not fail) → Task 3
  - Skip on empty version block → Task 3
  - yq injection (ephemeral, not committed) → Task 2 + Task 3 smoke test includes `git checkout`
  - Applies to all charts (reads `charts_to_package`) → Task 3 main()
  - Workflow step added before "Build Helm charts" → Task 4

- [x] **Placeholders:** None found.

- [x] **Type consistency:** `parse_top_version_block` returns `(str | None, list[dict])` — used consistently in `main()`. `changes_to_yaml_string` accepts `list[dict]` — consistent. `inject_annotation` takes `str, str` — consistent.
