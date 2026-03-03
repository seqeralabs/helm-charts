CHARTS_DIR := ../../../charts
LOCAL_CHART_DIR := platform
SRC_REGISTRY ?= cr.seqera.io

.PHONY: package-azure-cnab copy-images

# Copy all Seqera container images from the source registry to the Azure registry.
# Source image paths are taken from the helm values files; versions from each Chart.yaml.
# The frontend image is pulled with the -unprivileged tag suffix from the source and pushed
# without it to match the Azure override convention.
# Usage: make copy-images REGISTRY=myregistry.azurecr.io IMAGE_PREFIX=images [SRC_REGISTRY=cr.seqera.io]
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
	 echo "Copying images from $(SRC_REGISTRY) to $(REGISTRY)/$(IMAGE_PREFIX)..." && \
	 echo "  Platform: $${PLATFORM_TAG}, Studios: $${STUDIOS_TAG}, Pipeline Optimization: $${PIPEOPT_TAG}" && \
	 set -e && \
	 echo -n "[1/6] $(SRC_REGISTRY)/private/nf-tower-enterprise/backend:$${PLATFORM_TAG} → $(REGISTRY)/$(IMAGE_PREFIX)/platform/backend:$${PLATFORM_TAG} ... " && \
	 skopeo copy --quiet "docker://$(SRC_REGISTRY)/private/nf-tower-enterprise/backend:$${PLATFORM_TAG}" "docker://$(REGISTRY)/$(IMAGE_PREFIX)/platform/backend:$${PLATFORM_TAG}" && \
	 echo "✓" && \
	 echo -n "[2/6] $(SRC_REGISTRY)/private/nf-tower-enterprise/frontend:$${PLATFORM_TAG}-unprivileged → $(REGISTRY)/$(IMAGE_PREFIX)/platform/frontend:$${PLATFORM_TAG} ... " && \
	 skopeo copy --quiet "docker://$(SRC_REGISTRY)/private/nf-tower-enterprise/frontend:$${PLATFORM_TAG}-unprivileged" "docker://$(REGISTRY)/$(IMAGE_PREFIX)/platform/frontend:$${PLATFORM_TAG}" && \
	 echo "✓" && \
	 echo -n "[3/6] $(SRC_REGISTRY)/private/nf-tower-enterprise/migrate-db:$${PLATFORM_TAG} → $(REGISTRY)/$(IMAGE_PREFIX)/platform/migrate-db:$${PLATFORM_TAG} ... " && \
	 skopeo copy --quiet "docker://$(SRC_REGISTRY)/private/nf-tower-enterprise/migrate-db:$${PLATFORM_TAG}" "docker://$(REGISTRY)/$(IMAGE_PREFIX)/platform/migrate-db:$${PLATFORM_TAG}" && \
	 echo "✓" && \
	 echo -n "[4/6] $(SRC_REGISTRY)/private/nf-tower-enterprise/data-studio/connect-proxy:$${STUDIOS_TAG} → $(REGISTRY)/$(IMAGE_PREFIX)/studios/connect-proxy:$${STUDIOS_TAG} ... " && \
	 skopeo copy --quiet "docker://$(SRC_REGISTRY)/private/nf-tower-enterprise/data-studio/connect-proxy:$${STUDIOS_TAG}" "docker://$(REGISTRY)/$(IMAGE_PREFIX)/studios/connect-proxy:$${STUDIOS_TAG}" && \
	 echo "✓" && \
	 echo -n "[5/6] $(SRC_REGISTRY)/private/nf-tower-enterprise/data-studio/connect-server:$${STUDIOS_TAG} → $(REGISTRY)/$(IMAGE_PREFIX)/studios/connect-server:$${STUDIOS_TAG} ... " && \
	 skopeo copy --quiet "docker://$(SRC_REGISTRY)/private/nf-tower-enterprise/data-studio/connect-server:$${STUDIOS_TAG}" "docker://$(REGISTRY)/$(IMAGE_PREFIX)/studios/connect-server:$${STUDIOS_TAG}" && \
	 echo "✓" && \
	 echo -n "[6/6] $(SRC_REGISTRY)/private/nf-tower-enterprise/groundswell:$${PIPEOPT_TAG} → $(REGISTRY)/$(IMAGE_PREFIX)/pipeline-optimization/groundswell:$${PIPEOPT_TAG} ... " && \
	 skopeo copy --quiet "docker://$(SRC_REGISTRY)/private/nf-tower-enterprise/groundswell:$${PIPEOPT_TAG}" "docker://$(REGISTRY)/$(IMAGE_PREFIX)/pipeline-optimization/groundswell:$${PIPEOPT_TAG}" && \
	 echo "✓" && \
	 echo "✓ All images copied successfully"

# Package CNAB for Azure, replacing all azure image registries, repositories, and tags.
# Registries are set to REGISTRY, repositories to IMAGE_PREFIX/<chart>/<component>,
# and tags to the appVersion from each chart's Chart.yaml.
# Usage: make package-azure-cnab REGISTRY=myregistry.azurecr.io IMAGE_PREFIX=images
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
	 yq -i '.global.azure.images.platformBackend.registry = strenv(REGISTRY) | .global.azure.images.platformBackend.image = strenv(IMAGE_PREFIX) + "/platform/backend" | .global.azure.images.platformBackend.tag = strenv(PLATFORM_TAG) | .global.azure.images.platformBackend.tag style="double"' values.yaml && \
	 yq -i '.global.azure.images.platformFrontend.registry = strenv(REGISTRY) | .global.azure.images.platformFrontend.image = strenv(IMAGE_PREFIX) + "/platform/frontend" | .global.azure.images.platformFrontend.tag = strenv(PLATFORM_TAG) | .global.azure.images.platformFrontend.tag style="double"' values.yaml && \
	 yq -i '.global.azure.images.platformCronMigrateDB.registry = strenv(REGISTRY) | .global.azure.images.platformCronMigrateDB.image = strenv(IMAGE_PREFIX) + "/platform/migrate-db" | .global.azure.images.platformCronMigrateDB.tag = strenv(PLATFORM_TAG) | .global.azure.images.platformCronMigrateDB.tag style="double"' values.yaml && \
	 yq -i '.global.azure.images.studiosProxy.registry = strenv(REGISTRY) | .global.azure.images.studiosProxy.image = strenv(IMAGE_PREFIX) + "/studios/connect-proxy" | .global.azure.images.studiosProxy.tag = strenv(STUDIOS_TAG) | .global.azure.images.studiosProxy.tag style="double"' values.yaml && \
	 yq -i '.global.azure.images.studiosServer.registry = strenv(REGISTRY) | .global.azure.images.studiosServer.image = strenv(IMAGE_PREFIX) + "/studios/connect-server" | .global.azure.images.studiosServer.tag = strenv(STUDIOS_TAG) | .global.azure.images.studiosServer.tag style="double"' values.yaml && \
	 yq -i '.global.azure.images.pipelineOptimization.registry = strenv(REGISTRY) | .global.azure.images.pipelineOptimization.image = strenv(IMAGE_PREFIX) + "/pipeline-optimization/groundswell" | .global.azure.images.pipelineOptimization.tag = strenv(PIPEOPT_TAG) | .global.azure.images.pipelineOptimization.tag style="double"' values.yaml && \
	 yq -i '.global.azure.images.pipelineOptimizationMigrateDB.registry = strenv(REGISTRY) | .global.azure.images.pipelineOptimizationMigrateDB.image = strenv(IMAGE_PREFIX) + "/pipeline-optimization/groundswell" | .global.azure.images.pipelineOptimizationMigrateDB.tag = strenv(PIPEOPT_TAG) | .global.azure.images.pipelineOptimizationMigrateDB.tag style="double"' values.yaml && \
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
	@export CHART_VERSION=$$(yq '.version' $(CHARTS_DIR)/platform/Chart.yaml) && \
	 yq -i '.version = strenv(CHART_VERSION)' manifest.yaml
	/usr/bin/docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $$(pwd):/data -v ~/.azure:/root/.azure -w /data mcr.microsoft.com/container-package-app:1.3.41 bash -c "az acr login -n $(REGISTRY) && cpa buildbundle; chmod -R o+X .cnab"
