CHARTS_DIR := ../../../charts
LOCAL_CHART_DIR := platform
SRC_REGISTRY ?= cr.seqera.io

# Optional image overrides as registry/repository:tag.
# When set, these take precedence over the appVersion from Chart.yaml.
# Example: IMAGE_BACKEND=cr.seqera.io/private/nf-tower-enterprise/backend:24.1.0
IMAGE_BACKEND ?=
IMAGE_FRONTEND ?=
IMAGE_CRON_MIGRATEDB ?=
IMAGE_STUDIOS_PROXY ?=
IMAGE_STUDIOS_SERVER ?=
IMAGE_PIPELINE_OPTIMIZATION ?=
# Optional CNAB bundle version override. When set, takes precedence over the version from Chart.yaml.
BUNDLE_VERSION ?=

.PHONY: package-azure-cnab copy-images

# Copy all Seqera container images from the source registry to the Azure registry.
# Source image paths are taken from the helm values files; versions from each Chart.yaml.
# The frontend image is pulled with the -unprivileged tag suffix from the source and pushed
# without it to match the Azure override convention.
# When IMAGE_* overrides are set, those images are used as-is instead of the default source paths.
# Usage: make copy-images REGISTRY=myregistry.azurecr.io IMAGE_PREFIX=images [SRC_REGISTRY=cr.seqera.io]
# Optional overrides (registry/repository:tag): IMAGE_BACKEND IMAGE_FRONTEND IMAGE_CRON_MIGRATEDB
#                                                IMAGE_STUDIOS_PROXY IMAGE_STUDIOS_SERVER IMAGE_PIPELINE_OPTIMIZATION
copy-images:
	@if [ -z "$(REGISTRY)" ]; then \
		echo "Error: REGISTRY is required. Usage: make copy-images REGISTRY=myregistry.azurecr.io IMAGE_PREFIX=images"; \
		exit 1; \
	fi
	@if [ -z "$(IMAGE_PREFIX)" ]; then \
		echo "Error: IMAGE_PREFIX is required. Usage: make copy-images REGISTRY=myregistry.azurecr.io IMAGE_PREFIX=images"; \
		exit 1; \
	fi
	@PLATFORM_TAG=$$(yq '.appVersion' $(CHARTS_DIR)/platform/Chart.yaml) && \
	 STUDIOS_TAG=$$(yq '.appVersion' $(CHARTS_DIR)/platform/charts/studios/Chart.yaml) && \
	 PIPEOPT_TAG=$$(yq '.appVersion' $(CHARTS_DIR)/platform/charts/pipeline-optimization/Chart.yaml) && \
	 echo "Copying images to $(REGISTRY)/$(IMAGE_PREFIX)..." && \
	 set -e && \
	 \
	 if [ -n "$(IMAGE_BACKEND)" ]; then \
	   SRC_BACKEND="$(IMAGE_BACKEND)"; \
	 else \
	   SRC_BACKEND="$(SRC_REGISTRY)/private/nf-tower-enterprise/backend:$${PLATFORM_TAG}"; \
	 fi && \
	 DST_BACKEND_TAG=$$(echo "$${SRC_BACKEND}" | rev | cut -d: -f1 | rev) && \
	 echo -n "[1/6] $${SRC_BACKEND} → $(REGISTRY)/$(IMAGE_PREFIX)/platform/backend:$${DST_BACKEND_TAG} ... " && \
	 skopeo copy --quiet "docker://$${SRC_BACKEND}" "docker://$(REGISTRY)/$(IMAGE_PREFIX)/platform/backend:$${DST_BACKEND_TAG}" && \
	 echo "✓" && \
	 \
	 if [ -n "$(IMAGE_FRONTEND)" ]; then \
	   SRC_FRONTEND="$(IMAGE_FRONTEND)"; \
	   DST_FRONTEND_TAG=$$(echo "$${SRC_FRONTEND}" | rev | cut -d: -f1 | rev); \
	 else \
	   SRC_FRONTEND="$(SRC_REGISTRY)/private/nf-tower-enterprise/frontend:$${PLATFORM_TAG}-unprivileged"; \
	   DST_FRONTEND_TAG="$${PLATFORM_TAG}"; \
	 fi && \
	 echo -n "[2/6] $${SRC_FRONTEND} → $(REGISTRY)/$(IMAGE_PREFIX)/platform/frontend:$${DST_FRONTEND_TAG} ... " && \
	 skopeo copy --quiet "docker://$${SRC_FRONTEND}" "docker://$(REGISTRY)/$(IMAGE_PREFIX)/platform/frontend:$${DST_FRONTEND_TAG}" && \
	 echo "✓" && \
	 \
	 if [ -n "$(IMAGE_CRON_MIGRATEDB)" ]; then \
	   SRC_MIGRATEDB="$(IMAGE_CRON_MIGRATEDB)"; \
	 else \
	   SRC_MIGRATEDB="$(SRC_REGISTRY)/private/nf-tower-enterprise/migrate-db:$${PLATFORM_TAG}"; \
	 fi && \
	 DST_MIGRATEDB_TAG=$$(echo "$${SRC_MIGRATEDB}" | rev | cut -d: -f1 | rev) && \
	 echo -n "[3/6] $${SRC_MIGRATEDB} → $(REGISTRY)/$(IMAGE_PREFIX)/platform/migrate-db:$${DST_MIGRATEDB_TAG} ... " && \
	 skopeo copy --quiet "docker://$${SRC_MIGRATEDB}" "docker://$(REGISTRY)/$(IMAGE_PREFIX)/platform/migrate-db:$${DST_MIGRATEDB_TAG}" && \
	 echo "✓" && \
	 \
	 if [ -n "$(IMAGE_STUDIOS_PROXY)" ]; then \
	   SRC_STUDIOS_PROXY="$(IMAGE_STUDIOS_PROXY)"; \
	 else \
	   SRC_STUDIOS_PROXY="$(SRC_REGISTRY)/private/nf-tower-enterprise/data-studio/connect-proxy:$${STUDIOS_TAG}"; \
	 fi && \
	 DST_STUDIOS_PROXY_TAG=$$(echo "$${SRC_STUDIOS_PROXY}" | rev | cut -d: -f1 | rev) && \
	 echo -n "[4/6] $${SRC_STUDIOS_PROXY} → $(REGISTRY)/$(IMAGE_PREFIX)/studios/connect-proxy:$${DST_STUDIOS_PROXY_TAG} ... " && \
	 skopeo copy --quiet "docker://$${SRC_STUDIOS_PROXY}" "docker://$(REGISTRY)/$(IMAGE_PREFIX)/studios/connect-proxy:$${DST_STUDIOS_PROXY_TAG}" && \
	 echo "✓" && \
	 \
	 if [ -n "$(IMAGE_STUDIOS_SERVER)" ]; then \
	   SRC_STUDIOS_SERVER="$(IMAGE_STUDIOS_SERVER)"; \
	 else \
	   SRC_STUDIOS_SERVER="$(SRC_REGISTRY)/private/nf-tower-enterprise/data-studio/connect-server:$${STUDIOS_TAG}"; \
	 fi && \
	 DST_STUDIOS_SERVER_TAG=$$(echo "$${SRC_STUDIOS_SERVER}" | rev | cut -d: -f1 | rev) && \
	 echo -n "[5/6] $${SRC_STUDIOS_SERVER} → $(REGISTRY)/$(IMAGE_PREFIX)/studios/connect-server:$${DST_STUDIOS_SERVER_TAG} ... " && \
	 skopeo copy --quiet "docker://$${SRC_STUDIOS_SERVER}" "docker://$(REGISTRY)/$(IMAGE_PREFIX)/studios/connect-server:$${DST_STUDIOS_SERVER_TAG}" && \
	 echo "✓" && \
	 \
	 if [ -n "$(IMAGE_PIPELINE_OPTIMIZATION)" ]; then \
	   SRC_PIPEOPT="$(IMAGE_PIPELINE_OPTIMIZATION)"; \
	 else \
	   SRC_PIPEOPT="$(SRC_REGISTRY)/private/nf-tower-enterprise/groundswell:$${PIPEOPT_TAG}"; \
	 fi && \
	 DST_PIPEOPT_TAG=$$(echo "$${SRC_PIPEOPT}" | rev | cut -d: -f1 | rev) && \
	 echo -n "[6/6] $${SRC_PIPEOPT} → $(REGISTRY)/$(IMAGE_PREFIX)/pipeline-optimization/groundswell:$${DST_PIPEOPT_TAG} ... " && \
	 skopeo copy --quiet "docker://$${SRC_PIPEOPT}" "docker://$(REGISTRY)/$(IMAGE_PREFIX)/pipeline-optimization/groundswell:$${DST_PIPEOPT_TAG}" && \
	 echo "✓" && \
	 echo "✓ All images copied successfully"

# Package CNAB for Azure, replacing all azure image registries, repositories, and tags.
# Registries are set to REGISTRY, repositories to IMAGE_PREFIX/<chart>/<component>,
# and tags to the appVersion from each chart's Chart.yaml (overridable via IMAGE_* variables).
# Usage: make package-azure-cnab REGISTRY=myregistry.azurecr.io IMAGE_PREFIX=images
# Optional overrides (registry/repository:tag): IMAGE_BACKEND IMAGE_FRONTEND IMAGE_CRON_MIGRATEDB
#                                                IMAGE_STUDIOS_PROXY IMAGE_STUDIOS_SERVER IMAGE_PIPELINE_OPTIMIZATION
package-azure-cnab:
	@if [ -z "$(REGISTRY)" ]; then \
		echo "Error: REGISTRY is required. Usage: make package-azure-cnab REGISTRY=myregistry.azurecr.io IMAGE_PREFIX=images"; \
		exit 1; \
	fi
	@if [ -z "$(IMAGE_PREFIX)" ]; then \
		echo "Error: IMAGE_PREFIX is required. Usage: make package-azure-cnab REGISTRY=myregistry.azurecr.io IMAGE_PREFIX=images"; \
		exit 1; \
	fi
	@echo "Copying charts locally..."
	@rm -rf seqera-common $(LOCAL_CHART_DIR)
	@cp -r $(CHARTS_DIR)/seqera-common .
	@cp -r $(CHARTS_DIR)/platform $(LOCAL_CHART_DIR)
	@find . -name .helmignore -delete  # Remove .helmignore files to remove warnings about symlinks

	@echo "Packaging CNAB for Azure with registry: $(REGISTRY), image prefix: $(IMAGE_PREFIX)..."
	@cd $(LOCAL_CHART_DIR) && \
	 export REGISTRY="$(REGISTRY)" && \
	 export IMAGE_PREFIX="$(IMAGE_PREFIX)" && \
	 export PLATFORM_TAG=$$(yq '.appVersion' Chart.yaml) && \
	 export STUDIOS_TAG=$$(yq '.appVersion' charts/studios/Chart.yaml) && \
	 export PIPEOPT_TAG=$$(yq '.appVersion' charts/pipeline-optimization/Chart.yaml) && \
	 \
	 if [ -n "$(IMAGE_BACKEND)" ]; then \
	   export BACKEND_REGISTRY=$$(echo "$(IMAGE_BACKEND)" | cut -d/ -f1) && \
	   export BACKEND_IMAGE=$$(echo "$(IMAGE_BACKEND)" | sed 's|:[^:]*$$||' | cut -d/ -f2-) && \
	   export BACKEND_TAG=$$(echo "$(IMAGE_BACKEND)" | rev | cut -d: -f1 | rev); \
	 else \
	   export BACKEND_REGISTRY="$${REGISTRY}" && \
	   export BACKEND_IMAGE="$${IMAGE_PREFIX}/platform/backend" && \
	   export BACKEND_TAG="$${PLATFORM_TAG}"; \
	 fi && \
	 \
	 if [ -n "$(IMAGE_FRONTEND)" ]; then \
	   export FRONTEND_REGISTRY=$$(echo "$(IMAGE_FRONTEND)" | cut -d/ -f1) && \
	   export FRONTEND_IMAGE=$$(echo "$(IMAGE_FRONTEND)" | sed 's|:[^:]*$$||' | cut -d/ -f2-) && \
	   export FRONTEND_TAG=$$(echo "$(IMAGE_FRONTEND)" | rev | cut -d: -f1 | rev); \
	 else \
	   export FRONTEND_REGISTRY="$${REGISTRY}" && \
	   export FRONTEND_IMAGE="$${IMAGE_PREFIX}/platform/frontend" && \
	   export FRONTEND_TAG="$${PLATFORM_TAG}"; \
	 fi && \
	 \
	 if [ -n "$(IMAGE_CRON_MIGRATEDB)" ]; then \
	   export CRON_MIGRATEDB_REGISTRY=$$(echo "$(IMAGE_CRON_MIGRATEDB)" | cut -d/ -f1) && \
	   export CRON_MIGRATEDB_IMAGE=$$(echo "$(IMAGE_CRON_MIGRATEDB)" | sed 's|:[^:]*$$||' | cut -d/ -f2-) && \
	   export CRON_MIGRATEDB_TAG=$$(echo "$(IMAGE_CRON_MIGRATEDB)" | rev | cut -d: -f1 | rev); \
	 else \
	   export CRON_MIGRATEDB_REGISTRY="$${REGISTRY}" && \
	   export CRON_MIGRATEDB_IMAGE="$${IMAGE_PREFIX}/platform/migrate-db" && \
	   export CRON_MIGRATEDB_TAG="$${PLATFORM_TAG}"; \
	 fi && \
	 \
	 if [ -n "$(IMAGE_STUDIOS_PROXY)" ]; then \
	   export STUDIOS_PROXY_REGISTRY=$$(echo "$(IMAGE_STUDIOS_PROXY)" | cut -d/ -f1) && \
	   export STUDIOS_PROXY_IMAGE=$$(echo "$(IMAGE_STUDIOS_PROXY)" | sed 's|:[^:]*$$||' | cut -d/ -f2-) && \
	   export STUDIOS_PROXY_TAG=$$(echo "$(IMAGE_STUDIOS_PROXY)" | rev | cut -d: -f1 | rev); \
	 else \
	   export STUDIOS_PROXY_REGISTRY="$${REGISTRY}" && \
	   export STUDIOS_PROXY_IMAGE="$${IMAGE_PREFIX}/studios/connect-proxy" && \
	   export STUDIOS_PROXY_TAG="$${STUDIOS_TAG}"; \
	 fi && \
	 \
	 if [ -n "$(IMAGE_STUDIOS_SERVER)" ]; then \
	   export STUDIOS_SERVER_REGISTRY=$$(echo "$(IMAGE_STUDIOS_SERVER)" | cut -d/ -f1) && \
	   export STUDIOS_SERVER_IMAGE=$$(echo "$(IMAGE_STUDIOS_SERVER)" | sed 's|:[^:]*$$||' | cut -d/ -f2-) && \
	   export STUDIOS_SERVER_TAG=$$(echo "$(IMAGE_STUDIOS_SERVER)" | rev | cut -d: -f1 | rev); \
	 else \
	   export STUDIOS_SERVER_REGISTRY="$${REGISTRY}" && \
	   export STUDIOS_SERVER_IMAGE="$${IMAGE_PREFIX}/studios/connect-server" && \
	   export STUDIOS_SERVER_TAG="$${STUDIOS_TAG}"; \
	 fi && \
	 \
	 if [ -n "$(IMAGE_PIPELINE_OPTIMIZATION)" ]; then \
	   export PIPEOPT_REGISTRY=$$(echo "$(IMAGE_PIPELINE_OPTIMIZATION)" | cut -d/ -f1) && \
	   export PIPEOPT_IMAGE=$$(echo "$(IMAGE_PIPELINE_OPTIMIZATION)" | sed 's|:[^:]*$$||' | cut -d/ -f2-) && \
	   export PIPEOPT_OVERRIDE_TAG=$$(echo "$(IMAGE_PIPELINE_OPTIMIZATION)" | rev | cut -d: -f1 | rev); \
	 else \
	   export PIPEOPT_REGISTRY="$${REGISTRY}" && \
	   export PIPEOPT_IMAGE="$${IMAGE_PREFIX}/pipeline-optimization/groundswell" && \
	   export PIPEOPT_OVERRIDE_TAG="$${PIPEOPT_TAG}"; \
	 fi && \
	 \
	 yq -i '.global.azure.images.platformBackend.registry = strenv(BACKEND_REGISTRY) | .global.azure.images.platformBackend.image = strenv(BACKEND_IMAGE) | .global.azure.images.platformBackend.tag = strenv(BACKEND_TAG) | .global.azure.images.platformBackend.tag style="double"' values.yaml && \
	 yq -i '.global.azure.images.platformFrontend.registry = strenv(FRONTEND_REGISTRY) | .global.azure.images.platformFrontend.image = strenv(FRONTEND_IMAGE) | .global.azure.images.platformFrontend.tag = strenv(FRONTEND_TAG) | .global.azure.images.platformFrontend.tag style="double"' values.yaml && \
	 yq -i '.global.azure.images.platformCronMigrateDB.registry = strenv(CRON_MIGRATEDB_REGISTRY) | .global.azure.images.platformCronMigrateDB.image = strenv(CRON_MIGRATEDB_IMAGE) | .global.azure.images.platformCronMigrateDB.tag = strenv(CRON_MIGRATEDB_TAG) | .global.azure.images.platformCronMigrateDB.tag style="double"' values.yaml && \
	 yq -i '.global.azure.images.studiosProxy.registry = strenv(STUDIOS_PROXY_REGISTRY) | .global.azure.images.studiosProxy.image = strenv(STUDIOS_PROXY_IMAGE) | .global.azure.images.studiosProxy.tag = strenv(STUDIOS_PROXY_TAG) | .global.azure.images.studiosProxy.tag style="double"' values.yaml && \
	 yq -i '.global.azure.images.studiosServer.registry = strenv(STUDIOS_SERVER_REGISTRY) | .global.azure.images.studiosServer.image = strenv(STUDIOS_SERVER_IMAGE) | .global.azure.images.studiosServer.tag = strenv(STUDIOS_SERVER_TAG) | .global.azure.images.studiosServer.tag style="double"' values.yaml && \
	 yq -i '.global.azure.images.pipelineOptimization.registry = strenv(PIPEOPT_REGISTRY) | .global.azure.images.pipelineOptimization.image = strenv(PIPEOPT_IMAGE) | .global.azure.images.pipelineOptimization.tag = strenv(PIPEOPT_OVERRIDE_TAG) | .global.azure.images.pipelineOptimization.tag style="double"' values.yaml && \
	 yq -i '.global.azure.images.pipelineOptimizationMigrateDB.registry = strenv(PIPEOPT_REGISTRY) | .global.azure.images.pipelineOptimizationMigrateDB.image = strenv(PIPEOPT_IMAGE) | .global.azure.images.pipelineOptimizationMigrateDB.tag = strenv(PIPEOPT_OVERRIDE_TAG) | .global.azure.images.pipelineOptimizationMigrateDB.tag style="double"' values.yaml && \
	 yq -i '.agent-backend.enabled = false | .initContainerDependencies.enabled = false | .studios.initContainerDependencies.enabled = false | .pipeline-optimization.initContainerDependencies.enabled = false | .agent-backend.initContainerDependencies.enabled = false' values.yaml && \
	 yq -i 'del(.global.azure.images.agentBackend) | del(.global.azure.images.waitForCron) | del(.global.azure.images.waitForPlatform) | del(.global.azure.images.waitForMySQL) | del(.global.azure.images.waitForRedis)' values.yaml
	@echo "Building and unpacking dependencies..."
	@$(MAKE) -C $(LOCAL_CHART_DIR) rebuild-deps-and-unpack
	@find . -depth -name .claude -type d -exec rm -rf "{}" \; # Remove dev files
	@find . -depth -name .helm_ls_cache -type d -exec rm -rf "{}" \;
	@find . -depth -name .debug -type d -exec rm -rf "{}" \;
	@find . -depth -name .vscode -type d -exec rm -rf "{}" \;
	@find . -name .helmignore -delete
	@find . -name NOTES.txt -delete    # Remove NOTES.txt files to prevent the static helm analyzer to report failures due to missing requirements at packaging time
	@echo "✓ Local chart prepared with Azure image overrides"
	@echo "Updating manifest version..."
	@if [ -n "$(BUNDLE_VERSION)" ]; then \
	   export CHART_VERSION="$(BUNDLE_VERSION)"; \
	 else \
	   export CHART_VERSION=$$(yq '.version' $(CHARTS_DIR)/platform/Chart.yaml); \
	 fi && \
	 yq -i '.version = strenv(CHART_VERSION)' manifest.yaml
	/usr/bin/docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $$(pwd):/data -v ~/.azure:/root/.azure -w /data mcr.microsoft.com/container-package-app:1.3.41 bash -c "az acr login -n $(REGISTRY) && cpa buildbundle; chmod -R o+X .cnab"
