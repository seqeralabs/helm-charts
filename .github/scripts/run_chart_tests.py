#!/usr/bin/env python3
"""
Run Helm Chart Unit Tests Script

PURPOSE:
  Executes helm-unittest tests for all root-level Helm charts in the repository.
  Ensures helm-unittest plugin is installed before running tests.

USAGE:
  python3 run_chart_tests.py

INPUTS:
  - Scans repository root directory for Chart.yaml files
  - Only tests root-level charts (e.g., platform/)
  - Does NOT test subcharts (e.g., platform/charts/subchart/)

OUTPUTS:
  - Exit code 0: All chart tests pass
  - Exit code 1: One or more chart tests fail or plugin installation fails
  - Prints test results for each chart

BEHAVIOR:
  - Checks if helm-unittest plugin is installed
  - If not installed, runs: helm plugin install (does not require Makefile)
  - Finds all root-level directories containing Chart.yaml
  - For each chart directory with a Makefile, runs: make -C <chart_dir> tests
  - Skips charts without a Makefile (e.g., library charts with no tests)
  - Subcharts are tested through their parent chart's test suite

REQUIREMENTS:
  - helm CLI must be installed
  - Charts with tests must have a Makefile with a 'tests' target
  - helm-unittest plugin v1.0.1 (installed automatically if missing)

EXAMPLES:
  Found charts: platform, seqera-common
  platform has Makefile - runs: make -C platform tests
  seqera-common has no Makefile - skipped

NOTE:
  Subcharts (e.g., platform/charts/pipeline-optimization/) are NOT tested
  independently. They should be tested as part of the parent chart's tests.
  Library charts without tests (no Makefile) are automatically skipped.
"""
import subprocess
import sys
import os

def main():
    """
    This script checks if the helm-unittest plugin is installed, installs it if it is not, and runs the helm chart tests in every directory in the root of the repository containing a Chart.yaml file and a Makefile.
    """

    # Check if the helm-unittest plugin is installed
    result = subprocess.run(["helm", "plugin", "list"], capture_output=True, text=True)
    if "unittest" not in result.stdout:
        print("helm-unittest plugin not found. Installing it now...")
        # Install the plugin directly without relying on Makefile
        install_result = subprocess.run([
            "helm", "plugin", "install",
            "https://github.com/quintush/helm-unittest",
            "--version", "1.0.1"
        ])
        if install_result.returncode != 0:
            print("Failed to install helm-unittest plugin.")
            sys.exit(1)
        print("helm-unittest plugin installed successfully.")

    # Find all directories in the root containing a Chart.yaml file
    chart_dirs = []
    for item in os.listdir("."):
        if os.path.isdir(item) and "Chart.yaml" in os.listdir(item):
            chart_dirs.append(item)

    if not chart_dirs:
        print("No charts found in the root of the repository.")
        sys.exit(0)

    print(f"Found charts in the following directories: {', '.join(chart_dirs)}")

    failed_charts = []
    skipped_charts = []
    for chart_dir in chart_dirs:
        # Check if Makefile exists in the chart directory
        makefile_path = os.path.join(chart_dir, "Makefile")
        if not os.path.isfile(makefile_path):
            print(f"Skipping {chart_dir} (no Makefile found - likely a library chart with no tests)...")
            skipped_charts.append(chart_dir)
            continue

        print(f"Running helm chart tests in {chart_dir}...")
        test_result = subprocess.run(["make", "-C", chart_dir, "tests"])
        if test_result.returncode != 0:
            print(f"Helm chart tests failed in {chart_dir}.")
            failed_charts.append(chart_dir)

    if skipped_charts:
        print(f"Skipped charts without Makefile: {', '.join(skipped_charts)}")

    if failed_charts:
        print(f"Helm chart tests failed in the following directories: {', '.join(failed_charts)}")
        sys.exit(1)

    print("All helm chart tests passed successfully.")
    sys.exit(0)

if __name__ == "__main__":
    main()
