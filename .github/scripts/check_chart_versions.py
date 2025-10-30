#!/usr/bin/env python3
import os
import sys
import yaml
import requests

def get_registry_token(repo_hostname, repo_project, chart, repo_username, repo_password):
    """Get an authentication token for the Docker/OCI registry."""
    # First, try to get the authentication realm from the registry
    test_url = f"https://{repo_hostname}/v2/"
    response = requests.get(test_url)

    if response.status_code == 401 and 'WWW-Authenticate' in response.headers:
        # Parse the WWW-Authenticate header to get the token endpoint
        auth_header = response.headers['WWW-Authenticate']
        print(f"Auth challenge: {auth_header}")

        # Extract realm, service, and scope from the header
        # Example: Bearer realm="https://auth.example.com/token",service="registry.example.com"
        import re
        realm_match = re.search(r'realm="([^"]+)"', auth_header)
        service_match = re.search(r'service="([^"]+)"', auth_header)

        if realm_match:
            token_url = realm_match.group(1)
            params = {
                'scope': f'repository:{repo_project}{chart}:pull',
            }
            if service_match:
                params['service'] = service_match.group(1)

            print(f"Requesting token from: {token_url}")
            token_response = requests.get(
                token_url,
                params=params,
                auth=(repo_username, repo_password)
            )
            token_response.raise_for_status()
            token_data = token_response.json()
            return token_data.get('token') or token_data.get('access_token')

    return None

def main():
    charts_to_package = os.environ.get("charts_to_package", "").split()
    if not charts_to_package:
        print("No charts to check.")
        return

    repo_hostname = os.environ['REPO_HOSTNAME']
    repo_project = os.environ['REPO_PROJECT']
    repo_username = os.environ['REPO_USERNAME']
    repo_password = os.environ['REPO_PASSWORD']

    any_failure = False
    for chart in charts_to_package:
        print(f"Working on chart '{chart}'")
        chart_yaml_path = os.path.join(chart, 'Chart.yaml')
        with open(chart_yaml_path) as f:
            chart_yaml = yaml.safe_load(f)
            # Force chart version to string to avoid issues with YAML parsing the version as a
            # number, e.g. version: 1.2 becomes 1.2 (float) instead of "1.2" (string)
            chart_version = str(chart_yaml['version'])

        print(f"Checking existence of chart {chart} version {chart_version}...")

        # Get authentication token
        token = get_registry_token(repo_hostname, repo_project, chart, repo_username, repo_password)

        headers = {}
        if token:
            headers['Authorization'] = f'Bearer {token}'
            print(f"Using bearer token authentication")

        url = f"https://{repo_hostname}/v2/{repo_project}/{chart}/tags/list"
        try:
            response = requests.get(url, headers=headers)
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
