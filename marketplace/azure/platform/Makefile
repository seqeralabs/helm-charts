CHARTS_DIR := ../../../charts
LOCAL_CHART_DIR := platform

.PHONY: package-azure-cnab

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
