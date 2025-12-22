#!/usr/bin/env python3
import json
import os
import sys

def set_github_env(name, value):
    if "GITHUB_ENV" in os.environ:
        with open(os.environ["GITHUB_ENV"], "a") as f:
            f.write(f"{name}<<EOF\n{value}\nEOF\n")

def main():
    try:
        with open('.github/outputs/all_changed_and_modified_files.json') as f:
            changed_files = json.load(f)
    except FileNotFoundError:
        print("'.github/outputs/all_changed_and_modified_files.json' not found. Assuming no files changed.")
        set_github_env("charts_to_package", "")
        return

    potential_charts = set()
    for file_path in changed_files:
        # Exclude files in top directories starting with a dot
        if '/' in file_path and not file_path.startswith('.'):
            parts = file_path.split('/')

            # Check if this is a subchart (e.g., platform/charts/pipeline-optimization/...)
            if len(parts) >= 3 and parts[1] == 'charts':
                # This is a subchart path like: parent/charts/subchart/...
                subchart_dir = '/'.join(parts[:3])  # e.g., platform/charts/pipeline-optimization
                potential_charts.add(subchart_dir)
            else:
                # This is a top-level chart
                chart_dir = parts[0]
                potential_charts.add(chart_dir)

    charts_to_package = []
    for chart in sorted(list(potential_charts)):
        if os.path.isfile(os.path.join(chart, 'Chart.yaml')):
            charts_to_package.append(chart)

    charts_string = " ".join(charts_to_package)
    print(f"Charts to package: {charts_string}")

    set_github_env("charts_to_package", charts_string)

if __name__ == "__main__":
    main()
