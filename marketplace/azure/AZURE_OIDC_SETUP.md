# Azure OIDC Setup for GitHub Actions

This guide explains how to let GitHub Actions authenticate to Azure **without storing any passwords or secrets**. It uses OIDC (OpenID Connect) — the same approach AWS uses with IAM Roles for service accounts.

## How it works (the 30-second version)

```
GitHub Actions                          Azure
─────────────                          ─────
1. Workflow starts
2. Requests a short-lived token  ──►
   from GitHub's OIDC provider
3.                                     Azure checks:
                                       "Is this token from GitHub? ✓
                                        Is it from the right repo? ✓
                                        Is it from the right branch? ✓"
4.                               ◄──   Azure grants access
5. Workflow pushes to ACR
```

Instead of storing a password in GitHub Secrets, you tell Azure: *"trust tokens coming from this specific GitHub repo"*. Each workflow run gets a fresh, short-lived token that expires in minutes.

## Prerequisites

- **Azure CLI** installed locally (or use [Azure Cloud Shell](https://shell.azure.com) in your browser)
- An Azure account with permission to create App Registrations and assign roles
- The `gh` CLI (optional, for setting GitHub secrets from the terminal)

## Step 1: Log in to Azure

```bash
az login
```

This opens a browser for you to authenticate. Once done, verify your account:

```bash
az account show --query '{subscriptionId:id, tenantId:tenantId, name:name}' -o table
```

Write down the **Subscription ID** and **Tenant ID** — you'll need them later.

## Step 2: Create an App Registration

An **App Registration** is Azure's version of a "service account". It's the identity that GitHub Actions will use.

```bash
az ad app create --display-name "github-actions-azure-marketplace-helm-charts"
```

Now retrieve the **Application (Client) ID**:

```bash
APP_ID=$(az ad app list --display-name "github-actions-azure-marketplace-helm-charts" --query '[0].appId' -o tsv)
echo "Client ID: ${APP_ID}"
```

> **What is this?** Think of the App Registration as creating a "user" for your CI pipeline. The Client ID is like its username.

## Step 3: Create a Service Principal

A **Service Principal** is the part of the App Registration that can actually be given permissions. You need both.

```bash
az ad sp create --id "${APP_ID}"
```

> **Why two things?** Azure separates identity (App Registration) from permissions (Service Principal). The App Registration defines *who* you are; the Service Principal defines *what you can do*. You always need both.

## Step 4: Create a Federated Credential

This is the key step. You're telling Azure: *"when you receive an OIDC token from GitHub Actions, and it comes from this specific repo, trust it as this App Registration."*

Since the workflow is triggered manually (`workflow_dispatch`), you need to specify which branch(es) can run it. Typically this is `master`:

```bash
GITHUB_ORG="seqeralabs"
GITHUB_REPO="helm-charts"

az ad app federated-credential create \
  --id "${APP_ID}" \
  --parameters '{
    "name": "github-actions-master",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'"${GITHUB_ORG}/${GITHUB_REPO}"':ref:refs/heads/master",
    "audiences": ["api://AzureADTokenExchange"],
    "description": "Allow GitHub Actions on master branch to authenticate"
  }'
```

### Important: the `subject` must match exactly

The `subject` field must precisely match how GitHub identifies the workflow run. Different triggers produce different subjects:

| Trigger | Subject format |
|---------|---------------|
| Push/dispatch on a branch | `repo:org/repo:ref:refs/heads/BRANCH_NAME` |
| Pull request | `repo:org/repo:pull_request` |
| GitHub Environment | `repo:org/repo:environment:ENV_NAME` |
| Tag | `repo:org/repo:ref:refs/tags/TAG_NAME` |

If the workflow might be triggered from other branches too, add a federated credential for each one. You can have up to 20 per App Registration.

### Verify your federated credentials

```bash
az ad app federated-credential list --id "${APP_ID}" -o table
```

## Step 5: Grant permission to push to ACR

The workflow needs to push CNAB bundles to the Azure Container Registry. Assign the **AcrPush** role (allows pull + push):

```bash
ACR_NAME="<define your ACR name>"  # Replace with your ACR name
ACR_RESOURCE_GROUP="<define your resource group>"  # Replace with the actual resource group

# Get the ACR's resource ID
ACR_ID=$(az acr show --name "${ACR_NAME}" --resource-group "${ACR_RESOURCE_GROUP}" --query 'id' -o tsv)

# Assign the AcrPush role
az role assignment create \
  --assignee "${APP_ID}" \
  --role "AcrPush" \
  --scope "${ACR_ID}"
```

> **Available ACR roles:**
> - `AcrPull` — pull only
> - `AcrPush` — pull + push (what we need)
> - `AcrDelete` — delete images
>
> Avoid `Owner` or `Contributor` — they're far too broad for this use case.

## Step 6: Add secrets to the GitHub repository

Go to the repo **Settings → Secrets and variables → Actions** and add these three values:

| Secret name | Value | How to get it |
|------------|-------|---------------|
| `AZURE_CLIENT_ID` | The Application (Client) ID from Step 2 | `echo ${APP_ID}` |
| `AZURE_TENANT_ID` | Your Azure AD Tenant ID | `az account show --query tenantId -o tsv` |
| `AZURE_SUBSCRIPTION_ID` | Your Azure Subscription ID | `az account show --query id -o tsv` |

Or via the `gh` CLI:

```bash
TENANT_ID=$(az account show --query 'tenantId' -o tsv)
SUBSCRIPTION_ID=$(az account show --query 'id' -o tsv)

gh secret set AZURE_CLIENT_ID       --repo "${GITHUB_ORG}/${GITHUB_REPO}" --body "${APP_ID}"
gh secret set AZURE_TENANT_ID       --repo "${GITHUB_ORG}/${GITHUB_REPO}" --body "${TENANT_ID}"
gh secret set AZURE_SUBSCRIPTION_ID --repo "${GITHUB_ORG}/${GITHUB_REPO}" --body "${SUBSCRIPTION_ID}"
```

> **Note:** These are not passwords — they're identifiers (like a username or account number). We store them as GitHub Secrets to keep them out of logs and to have a single source of truth.

## Step 7: Run the workflow

Go to the repository **Actions** tab, select **"Package Azure CNAB"**, and click **"Run workflow"**.

Or via `gh`:

```bash
gh workflow run "Package Azure CNAB" --repo "${GITHUB_ORG}/${GITHUB_REPO}"
```

## Troubleshooting

### "AADSTS70021: No matching federated identity record found"

The OIDC token's `subject` claim doesn't match any federated credential. Most common causes:

- **Wrong branch name** — you configured `refs/heads/main` but the repo uses `master` (or vice versa).
- **Triggered from an unexpected branch** — `workflow_dispatch` uses the branch you select in the UI. If you run it from a feature branch, you need a federated credential for that branch too.

To debug, add this step to the workflow temporarily:

```yaml
- name: Debug OIDC token
  run: |
    TOKEN=$(curl -s -H "Authorization: bearer ${ACTIONS_ID_TOKEN_REQUEST_TOKEN}" \
      "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=api://AzureADTokenExchange" | jq -r '.value')
    echo "${TOKEN}" | cut -d. -f2 | base64 -d 2>/dev/null | jq '{sub, aud, iss}'
```

This prints the actual `sub` (subject) claim so you can see what Azure is receiving.

### "Authorization failed" when pushing to ACR

The Service Principal doesn't have the `AcrPush` role. Verify:

```bash
az role assignment list --assignee "${APP_ID}" --all -o table
```

### "Permission 'id-token: write' is required"

The workflow is missing the `permissions` block. The workflow file already includes this — if it still fails, check if your organization has a policy that restricts `id-token` permissions.

## Reference: complete setup script

Copy-paste version of all Azure CLI commands from above:

```bash
#!/usr/bin/env bash
set -euo pipefail

# ─── Configuration ─────────────────────────────────────────────
APP_NAME="github-actions-azure-marketplace-helm-charts"
GITHUB_ORG="seqeralabs"
GITHUB_REPO="helm-charts"
BRANCH="master"
ACR_NAME="<define your ACR name>"  # Replace with your ACR name
ACR_RESOURCE_GROUP="<define your resource group>"  # Replace with the actual resource group
# ───────────────────────────────────────────────────────────────

# Create App Registration
az ad app create --display-name "${APP_NAME}"
APP_ID=$(az ad app list --display-name "${APP_NAME}" --query '[0].appId' -o tsv)

# Create Service Principal
az ad sp create --id "${APP_ID}"

# Add federated credential for the master branch
az ad app federated-credential create \
  --id "${APP_ID}" \
  --parameters '{
    "name": "github-actions-'"${BRANCH}"'",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'"${GITHUB_ORG}/${GITHUB_REPO}"':ref:refs/heads/'"${BRANCH}"'",
    "audiences": ["api://AzureADTokenExchange"],
    "description": "GitHub Actions OIDC for '"${BRANCH}"'"
  }'

# Assign AcrPush role
ACR_ID=$(az acr show --name "${ACR_NAME}" --resource-group "${ACR_RESOURCE_GROUP}" --query 'id' -o tsv)
az role assignment create --assignee "${APP_ID}" --role "AcrPush" --scope "${ACR_ID}"

# Print what to put in GitHub Secrets
TENANT_ID=$(az account show --query 'tenantId' -o tsv)
SUBSCRIPTION_ID=$(az account show --query 'id' -o tsv)

echo ""
echo "=== Add these as GitHub Actions secrets ==="
echo "  AZURE_CLIENT_ID:       ${APP_ID}"
echo "  AZURE_TENANT_ID:       ${TENANT_ID}"
echo "  AZURE_SUBSCRIPTION_ID: ${SUBSCRIPTION_ID}"
```
