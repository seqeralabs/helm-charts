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
  - If not installed, runs: make -C platform install-unittest-plugin
  - Finds all root-level directories containing Chart.yaml
  - For each chart directory, runs: make -C <chart_dir> tests
  - Subcharts are tested through their parent chart's test suite

REQUIREMENTS:
  - helm CLI must be installed
  - Each root chart must have a Makefile with a 'tests' target
  - helm-unittest plugin v1.0.1 (installed automatically if missing)

EXAMPLES:
  Found charts: platform
  Runs: make -C platform tests

NOTE:
  Subcharts (e.g., platform/charts/pipeline-optimization/) are NOT tested
  independently. They should be tested as part of the parent chart's tests.
"""
import subprocess
import sys
import os

def main():
    """
    This script checks if the helm-unittest plugin is installed, installs it if it is not, and runs the helm chart tests in every directory in the root of the repository containing a Chart.yaml file.
    """

    # Check if the helm-unittest plugin is installed
    result = subprocess.run(["helm", "plugin", "list"], capture_output=True, text=True)
    if "unittest" not in result.stdout:
        print("helm-unittest plugin not found. Installing it now...")
        # The makefile for installing the plugin is in the platform directory.
        # I will assume this is the correct place to run this command from.
        install_result = subprocess.run(["make", "-C", "platform", "install-unittest-plugin"])
        if install_result.returncode != 0:
            print("Failed to install helm-unittest plugin.")
            sys.exit(1)

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
    for chart_dir in chart_dirs:
        print(f"Running helm chart tests in {chart_dir}...")
        test_result = subprocess.run(["make", "-C", chart_dir, "tests"])
        if test_result.returncode != 0:
            print(f"Helm chart tests failed in {chart_dir}.")
            failed_charts.append(chart_dir)

    if failed_charts:
        print(f"Helm chart tests failed in the following directories: {', '.join(failed_charts)}")
        sys.exit(1)

    print("All helm chart tests passed successfully.")
    sys.exit(0)

if __name__ == "__main__":
    main()
