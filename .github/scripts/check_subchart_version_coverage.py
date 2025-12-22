#!/usr/bin/env python3
"""
Check Subchart Version Coverage Script

PURPOSE:
  Validates that subchart versions are covered by parent chart dependency version constraints.
  Reminds developers to update parent chart when subchart versions change outside the range.

USAGE:
  charts_to_package="platform platform/charts/pipeline-optimization" \\
  python3 check_subchart_version_coverage.py

REQUIRED ENVIRONMENT VARIABLES:
  - charts_to_package: Space-separated list of chart paths to check

OUTPUTS:
  - Exit code 0: All subchart versions are covered by parent dependencies
  - Exit code 1: One or more subchart versions fall outside parent's dependency range
  - Prints errors when subchart versions don't match constraints
  - GitHub step summary with error details (if in GitHub Actions)

BEHAVIOR:
  - Only checks subcharts (paths containing /charts/)
  - Reads subchart version from subchart's Chart.yaml
  - Reads parent chart dependencies from parent's Chart.yaml
  - Compares subchart version against parent's dependency version constraint
  - Supports x-range constraints (e.g., "0.1.x", "1.x.x")
  - BLOCKING: fails the build if versions don't match constraints

SUPPORTED VERSION CONSTRAINTS:
  - x-range: "0.1.x" matches 0.1.0, 0.1.5 but not 0.2.0
  - x-range: "1.x.x" matches 1.0.0, 1.5.3 but not 2.0.0
  - Exact: "0.1.0" matches only 0.1.0

EXAMPLE:
  Chart path: platform/charts/pipeline-optimization
  Subchart version: 0.2.0
  Parent dependency constraint: "0.1.x"
  Result: ❌ ERROR - version 0.2.0 not covered by constraint "0.1.x" (exit 1)
"""
import os
import sys
import yaml
import re


def parse_version(version_str):
    """Parse a semantic version string into a tuple of integers."""
    version_str = version_str.strip().strip('"').strip("'")
    # Remove any pre-release or build metadata
    version_str = re.split(r'[-+]', version_str)[0]
    parts = version_str.split('.')
    return tuple(int(p) for p in parts)


def check_version_in_x_range(version, constraint):
    """
    Check if version matches an x-range constraint.
    Examples:
      "0.1.x" matches "0.1.0", "0.1.5", but not "0.2.0"
      "1.x.x" matches "1.0.0", "1.5.3", but not "2.0.0"
    """
    constraint = constraint.strip().strip('"').strip("'")

    if not constraint.endswith('.x') and '.x' not in constraint:
        return None  # Not an x-range

    parts = constraint.rstrip('.x').split('.')
    ver_tuple = parse_version(version)

    if len(parts) == 1:
        # "1.x.x" -> major must match
        return ver_tuple[0] == int(parts[0])
    elif len(parts) == 2:
        # "0.1.x" -> major and minor must match
        return ver_tuple[0] == int(parts[0]) and ver_tuple[1] == int(parts[1])

    return False


def check_version_coverage(subchart_version, parent_constraint):
    """Check if subchart version is covered by parent's version constraint."""
    try:
        parent_constraint = parent_constraint.strip().strip('"').strip("'")

        # Handle x-range (e.g., "0.1.x", "1.x.x")
        result = check_version_in_x_range(subchart_version, parent_constraint)
        if result is not None:
            return result

        # For other constraint types, do a simple comparison
        # This is a basic implementation - extend as needed
        return subchart_version == parent_constraint

    except Exception as e:
        print(f"Warning: Could not parse version constraint: {e}")
        return True  # Don't fail on parse errors


def main():
    charts_to_package = os.environ.get("charts_to_package", "").split()
    if not charts_to_package:
        print("No charts to check.")
        return

    errors = []

    for chart_path in charts_to_package:
        # Check if this is a subchart (contains /charts/ in path)
        if '/charts/' not in chart_path:
            continue

        # Parse the subchart path: parent/charts/subchart
        parts = chart_path.split('/')
        if len(parts) < 3 or parts[1] != 'charts':
            continue

        parent_dir = parts[0]
        subchart_name = parts[2]

        # Read subchart version
        subchart_yaml_path = os.path.join(chart_path, 'Chart.yaml')
        if not os.path.isfile(subchart_yaml_path):
            continue

        with open(subchart_yaml_path) as f:
            subchart_yaml = yaml.safe_load(f)
            subchart_version = str(subchart_yaml.get('version', ''))

        # Read parent chart dependencies
        parent_yaml_path = os.path.join(parent_dir, 'Chart.yaml')
        if not os.path.isfile(parent_yaml_path):
            continue

        with open(parent_yaml_path) as f:
            parent_yaml = yaml.safe_load(f)
            dependencies = parent_yaml.get('dependencies', [])

        # Find the dependency for this subchart
        matching_dep = None
        for dep in dependencies:
            if dep.get('name') == subchart_name:
                matching_dep = dep
                break

        if not matching_dep:
            errors.append(
                f"❌ Subchart '{subchart_name}' (version {subchart_version}) is not listed as a dependency in {parent_dir}/Chart.yaml"
            )
            continue

        parent_version_constraint = matching_dep.get('version', '')

        # Check if subchart version is covered by parent's constraint
        if not check_version_coverage(subchart_version, parent_version_constraint):
            errors.append(
                f"❌ Subchart '{subchart_name}' version {subchart_version} is NOT covered by parent chart '{parent_dir}' dependency constraint '{parent_version_constraint}'"
            )
            errors.append(
                f"   💡 Update the version constraint in {parent_dir}/Chart.yaml to cover this version, or bump the parent chart version"
            )

    if errors:
        print("\n" + "="*80)
        print("❌  SUBCHART VERSION COVERAGE ERRORS")
        print("="*80)
        for error in errors:
            print(error)
        print("="*80)
        print("\n⛔ Build failed due to version coverage issues.")
        print("   Subchart versions must be covered by parent chart dependency constraints.")
        print("   Update the parent chart's Chart.yaml dependency version range or bump the parent version.\n")

        # Write to GitHub step summary if available
        if "GITHUB_STEP_SUMMARY" in os.environ:
            with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as f:
                f.write("\n## ❌ Subchart Version Coverage Errors\n\n")
                for error in errors:
                    f.write(f"- {error}\n")
                f.write("\n")

        # Exit with failure
        sys.exit(1)


if __name__ == "__main__":
    main()
