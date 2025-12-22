#!/usr/bin/env python3
import os
import sys
import yaml
import requests
import logging

# Configure logging with simple formatting
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s: %(message)s'
)

def get_registry_token(repo_hostname, repo_project, chart, repo_username, repo_password):
    """Get an authentication token for the Docker/OCI registry."""
    # First, try to get the authentication realm from the registry
    test_url = f"https://{repo_hostname}/v2/"
    response = requests.get(test_url)

    if response.status_code == 401 and 'WWW-Authenticate' in response.headers:
        # Parse the WWW-Authenticate header to get the token endpoint
        auth_header = response.headers['WWW-Authenticate']
        logging.info(f"Auth challenge: {auth_header}")

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

            logging.info(f"Requesting token from: {token_url}")
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
        logging.info("No charts to check.")
        return

    repo_hostname = os.environ['REPO_HOSTNAME']
    repo_project = os.environ['REPO_PROJECT']
    repo_username = os.environ['REPO_USERNAME']
    repo_password = os.environ['REPO_PASSWORD']

    # Make sure to always append a slash at the end of the project path
    repo_project = repo_project.rstrip('/') + '/'

    any_failure = False
    for chart_path in charts_to_package:
        logging.info(f"Working on chart '{chart_path}'")
        chart_yaml_path = os.path.join(chart_path, 'Chart.yaml')
        with open(chart_yaml_path) as f:
            chart_yaml = yaml.safe_load(f)
            # Force chart version to string to avoid issues with YAML parsing the version as a
            # number, e.g. version: 1.2 becomes 1.2 (float) instead of "1.2" (string)
            chart_version = str(chart_yaml['version'])
            # Get the actual chart name from Chart.yaml (important for subcharts)
            chart_name = chart_yaml['name']

        logging.info(f"Checking existence of chart {chart_name} (from {chart_path}) version {chart_version}...")

        # Get authentication token
        token = get_registry_token(repo_hostname, repo_project, chart_name, repo_username, repo_password)

        headers = {}
        if token:
            headers['Authorization'] = f'Bearer {token}'
            logging.info(f"Using bearer token authentication")

        url = f"https://{repo_hostname}/v2/{repo_project}/{chart_name}/tags/list"
        try:
            response = requests.get(url, headers=headers)
            if response.status_code == 404:
                logging.info(f"Chart {chart_name} not found in repo, which is good.")
                continue

            response.raise_for_status()
            tags = response.json().get('tags', [])
            if chart_version in tags:
                logging.error(f"⚠️ Chart '{chart_name}' version {chart_version} already exists in the Helm chart repository")

                version_lineno = 0
                with open(chart_yaml_path) as f:
                    for idx_line, line in enumerate(f):
                        if line.strip().startswith('version:'):
                            version_lineno = idx_line
                            break

                if "GITHUB_STEP_SUMMARY" in os.environ:
                    with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as f:
                        f.write(f"⚠️ Workflow failed. Chart '{chart_name}' version {chart_version} already exists in the Helm chart repository\n")

                logging.error(f"::error file={chart_path}/Chart.yaml,line={version_lineno}::Version {chart_version} of chart {chart_name} already exists in the Helm chart repository, please update the value of 'version:' inside Chart.yaml")
                any_failure = True
            else:
                logging.info(f"Chart {chart_name} version {chart_version} not found in repo")
        except requests.exceptions.RequestException as e:
            logging.error(f"Error checking chart {chart_name}: {e}")
            any_failure = True

    if any_failure:
        logging.error("Found at least one failure while checking for existence of helm charts in registry, exiting")
        sys.exit(1)

if __name__ == "__main__":
    main()
