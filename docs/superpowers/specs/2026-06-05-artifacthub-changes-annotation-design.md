# ArtifactHub Changes Annotation — Design Spec

**Date:** 2026-06-05
**Branch:** chiusole/add-artifacthub-support
**Scope:** All charts in the repo (platform + all subcharts)

---

## Goal

Inject the `artifacthub.io/changes` annotation into each chart's `Chart.yaml` during CI, so ArtifactHub can display a structured changelog for every chart version published to the OCI registry.

The annotation is injected ephemerally in the CI working tree — it is **not committed** back to the repo. `Chart.yaml` in source stays clean.

---

## Components

### 1. New script: `.github/scripts/inject_artifacthub_changes.py`

**Inputs:**
- `charts_to_package` environment variable (space-separated chart paths, set by `extract_charts.py`)
- Each chart's `CHANGELOG.md` and `Chart.yaml`

**Behaviour per chart:**

1. Read `CHANGELOG.md`. Extract the top version block: everything between the first `## [x.y.z] - date` heading and the next `## [` heading (or end of file).
2. Cross-check: verify the version in that heading matches `version` in `Chart.yaml`. If they differ, **fail with an error** — mismatched versions produce wrong data in the published chart.
3. Parse the block into sections by `### <Kind>` headings. Map to ArtifactHub kinds:

   | CHANGELOG header | ArtifactHub kind |
   |---|---|
   | Added | `added` |
   | Changed | `changed` |
   | Deprecated | `deprecated` |
   | Removed | `removed` |
   | Fixed | `fixed` |
   | Security | `security` |

4. Each bullet (`- <text>`) becomes one entry: `{kind: <kind>, description: "<text>"}`. Leading `- ` stripped, backticks left as-is.
5. Serialize the list as a YAML string and write it into `Chart.yaml` under `annotations["artifacthub.io/changes"]` using `yq e '.annotations["artifacthub.io/changes"] = strenv(CHANGES_YAML)' -i`.

**Skip conditions (warn, don't fail):**
- Chart has no `CHANGELOG.md`
- Top version block is empty (no bullet entries)

**Error conditions (fail the build):**
- CHANGELOG top-version does not match `Chart.yaml` version
- `yq` is not available

---

### 2. Workflow change: `build-helm-charts.yaml`

Insert one new step between "Extract list of changed Helm charts" and "Build Helm charts":

```yaml
- name: Inject ArtifactHub changes annotation
  if: env.charts_to_package != ''
  run: python3 .github/scripts/inject_artifacthub_changes.py
```

No new secrets or variables required. `yq` is already available in the CI environment (used in the existing build step).

---

## Data flow

```
CHANGELOG.md (top version block)
    │
    ▼
inject_artifacthub_changes.py
    │  parse sections → list of {kind, description}
    │  serialize to YAML string
    ▼
yq → Chart.yaml (in working tree, not committed)
    │
    ▼
helm package → .tgz contains annotation
    │
    ▼
helm push → OCI registry → ArtifactHub reads annotation
```

---

## Example output annotation

Given this CHANGELOG block:

```markdown
## [0.34.0] - 2026-05-26

### Changed

- Update Platform application version to v26.1.0.
- Bump bitnami/common to 2.40.0.

### Fixed

- Do not inject `ANTHROPIC_API_KEY` env var when apiKey is empty.
```

The injected annotation value (a YAML string embedded in Chart.yaml):

```yaml
annotations:
  artifacthub.io/changes: |
    - kind: changed
      description: Update Platform application version to v26.1.0.
    - kind: changed
      description: Bump bitnami/common to 2.40.0.
    - kind: fixed
      description: Do not inject `ANTHROPIC_API_KEY` env var when apiKey is empty.
```

---

## What is NOT in scope

- Backfilling historical versions — only the current version's changes are injected per build.
- Committing the annotation back to source — purely a CI-time ephemeral modification.
- Other ArtifactHub annotations (e.g. `artifacthub.io/links`, `artifacthub.io/maintainers`) — separate concern.
