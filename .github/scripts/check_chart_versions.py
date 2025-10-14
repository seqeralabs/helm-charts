#!/usr/bin/env python3
import os
import sys
import yaml
import requests

def main():
    charts_to_package = os.environ.get("charts_to_package", "").split()
    if not charts_to_package:
        print("No charts to check.")
        return

    repo_domain = os.environ['TOWER_HELM_CR_REPO_DOMAIN']
    repo_project = os.environ['TOWER_HELM_CR_REPO_PROJECT']
    username = os.environ['TOWER_HELM_CR_USERNAME']
    password = os.environ['TOWER_HELM_CR_PASSWORD']

    any_failure = False
    for chart in charts_to_package:
        print(f"Working on chart '{chart}'")
        chart_yaml_path = os.path.join(chart, 'Chart.yaml')
        with open(chart_yaml_path) as f:
            chart_yaml = yaml.safe_load(f)
            chart_version = chart_yaml['version']

        print(f"Checking existence of chart {chart} version {chart_version}...")

        url = f"https://{repo_domain}/v2/{repo_project}/{chart}/tags/list"
        try:
            response = requests.get(url, auth=(username, password))
            if response.status_code == 404:
                print(f"Chart {chart} not found in repo, which is good.")
                continue

            response.raise_for_status()
            tags = response.json().get('tags', [])
            if chart_version in tags:
                print(f"⚠️ Chart '{chart}' version {chart_version} already exists in the Helm chart repository", file=sys.stderr)

                version_lineno = 0
                with open(chart_yaml_path) as f:
                    for idx_line, line in enumerate(f, 1):
                        if line.strip().startswith('version:'):
                            version_lineno = idx_line
                            break

                if "GITHUB_STEP_SUMMARY" in os.environ:
                    with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as f:
                        f.write(f"⚠️ Workflow failed. Chart '{chart}' version {chart_version} already exists in the Helm chart repository\n")

                print(f"::error file={chart}/Chart.yaml,line={version_lineno}::Version {chart_version} of chart {chart} already exists in the Helm chart repository, please update the value of 'version:' inside Chart.yaml")
                any_failure = True
            else:
                print(f"Chart {chart} version {chart_version} not found in repo")
        except requests.exceptions.RequestException as e:
            print(f"Error checking chart {chart}: {e}", file=sys.stderr)
            any_failure = True

    if any_failure:
        print("Found at least one failure while checking for existence of helm charts in registry, exiting", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
