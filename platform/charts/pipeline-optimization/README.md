# pipeline-optimization

A Helm chart to deploy the Seqera Pipeline Optimization service (referred to as Groundswell in Platform configuration files).

![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.4.7](https://img.shields.io/badge/AppVersion-0.4.7-informational?style=flat-square)

> [!WARNING]
> This chart is currently still in development and breaking changes are expected.
> The public API SHOULD NOT be considered stable.

## Requirements and configuration

For an overview of the Seqera Pipeline Optimization service architecture and its requirements, refer to the [Seqera documentation](https://docs.seqera.io/platform-enterprise/enterprise/configuration/pipeline_optimization).

The chart does not automatically define `cr.seqera.io` as the registry where to take the images from: instructions are available to [vendor the Seqera container images to your private registry](https://docs.seqera.io/platform-enterprise/enterprise/prerequisites/common#vendoring-seqera-container-images-to-your-own-registry).

The required values to set in order to have a working installation are:
- The `.image` and the `.dbMigrationInitContainer.image` sections to point to your container registry.
- Container registry credentials under the `.global.imageCredentials` section (can be the credentials for cr.seqera.io or your private registry where you vendored the images to).
  * These credentials will be used by all the subcharts unless overridden in the specific subchart.
  * Multiple credentials can be specified to cover different registries.
  * Specific pull secrets can be defined in each `.image` section to extend the global credentials.
  * Image pull secrets defined in the specific `.image` section will be added to the global ones, not replacing them.
- The Pipeline Optimization service database connection details under the `.database` section.
- The database connection details for the Platform MySQL database under the `.platformDatabase` section.

The Helm chart comes with several requirement checks that will validate the provided configuration before proceeding with the installation.

By default the chart selects the Platform application images defined in the `appVersion` field of the `Chart.yaml` file, currently set as `0.4.7`.

When a sensitive value is required (e.g. the database password), you can either provide it directly in the values file or reference an existing Kubernetes Secret containing the value. The key names to use in the provided Secret are specified in the values file comments.
Sensitive values provided as plain text by the user are always stored in a Kubernetes Secret created by the chart. When an external Secret is referenced, the chart instructs the components to read the sensitive value from the external Secret directly, without storing copies of the sensitive value in the chart-created Secret.

## Installing the chart

To install the chart with the release name `my-release`:

```console
helm install my-release oci://public.cr.seqera.io/charts/pipeline-optimization \
  --version 0.1.1 \
  --namespace my-namespace \
  --create-namespace
```

For a list of available chart versions, see the chart repository: https://public.cr.seqera.io/repo/charts/pipeline-optimization

## Examples

Refer to the [examples directory](./examples) for different scenarios of installing the Pipeline Optimization chart.
The examples provided are showcasing possible configurations of the helm chart, and are not representative of a full installation.
Please refer to the [Seqera Pipeline Optimization documentation](https://docs.seqera.io/platform-enterprise/enterprise/configuration/pipeline_optimization) for complete installation instructions.

## Upgrading the chart

When upgrading between versions, please refer to the [CHANGELOG.md](CHANGELOG.md) for breaking changes and migration instructions.

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| oci://registry-1.docker.io/bitnamicharts | common | 2.x.x |

## Values

<table>
	<thead>
		<th>Key</th>
		<th>Type</th>
		<th>Default</th>
		<th>Description</th>
	</thead>
	<tbody>
		<tr>
			<td>global.imageCredentials</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Optional credentials to log in and fetch images from a private registry. These credentials are shared with all the subcharts automatically.  <pre><code> - registry: ""</br>   username: ""</br>   password: ""</br>   email: someone@example.com  # Optional </code></pre></td>
		</tr>
		<tr>
			<td>database.host</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Pipeline Optimization MySQL database hostname</td>
		</tr>
		<tr>
			<td>database.port</td>
			<td>int</td>
			<td><pre lang="json">
3306
</pre>
</td>
			<td>Pipeline Optimization MySQL database port</td>
		</tr>
		<tr>
			<td>database.name</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Pipeline Optimization MySQL database name</td>
		</tr>
		<tr>
			<td>database.username</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Pipeline Optimization MySQL database username</td>
		</tr>
		<tr>
			<td>database.password</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Pipeline Optimization MySQL database password</td>
		</tr>
		<tr>
			<td>database.existingSecretName</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Name of an existing secret containing credentials for the Pipeline Optimization MySQL database Note: the secret must already exist in the same namespace at the time of deployment, it can't be created by this chart with extraDeploy, since this chart performs a lookup on the Kubernetes API server at install/upgrade time</td>
		</tr>
		<tr>
			<td>database.existingSecretKey</td>
			<td>string</td>
			<td><pre lang="">
"SWELL_DB_PASSWORD"
</pre>
</td>
			<td>Key in the existing secret containing the password for the Pipeline Optimization MySQL database</td>
		</tr>
		<tr>
			<td>database.dialect</td>
			<td>string</td>
			<td><pre lang="json">
"mysql"
</pre>
</td>
			<td>Pipeline Optimization database dialect. Currently only 'mysql' is supported</td>
		</tr>
		<tr>
			<td>platformDatabase.host</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Platform MySQL database hostname</td>
		</tr>
		<tr>
			<td>platformDatabase.port</td>
			<td>int</td>
			<td><pre lang="json">
3306
</pre>
</td>
			<td>Platform MySQL database port</td>
		</tr>
		<tr>
			<td>platformDatabase.name</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Platform MySQL database name</td>
		</tr>
		<tr>
			<td>platformDatabase.username</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Platform MySQL database username. Can be a read-only user, since Platform Optimization does not perform write operations on the Platform database</td>
		</tr>
		<tr>
			<td>platformDatabase.password</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Platform MySQL database password</td>
		</tr>
		<tr>
			<td>platformDatabase.existingSecretName</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Name of an existing secret containing credentials for the Platform MySQL database Note: the secret must already exist in the same namespace at the time of deployment, it can't be created by this chart with extraDeploy, since this chart performs a lookup on the Kubernetes API server at install/upgrade time</td>
		</tr>
		<tr>
			<td>platformDatabase.existingSecretKey</td>
			<td>string</td>
			<td><pre lang="">
"TOWER_DB_PASSWORD"
</pre>
</td>
			<td>Key in the existing secret containing the password for the Platform MySQL database</td>
		</tr>
		<tr>
			<td>image.registry</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Pipeline Optimization container image registry</td>
		</tr>
		<tr>
			<td>image.repository</td>
			<td>string</td>
			<td><pre lang="json">
"private/nf-tower-enterprise/groundswell"
</pre>
</td>
			<td>Pipeline Optimization container image repository</td>
		</tr>
		<tr>
			<td>image.tag</td>
			<td>string</td>
			<td><pre lang="">
"{{ .chart.AppVersion }}"
</pre>
</td>
			<td>Pipeline Optimization container image tag</td>
		</tr>
		<tr>
			<td>image.digest</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Pipeline Optimization container image digest in the format <code>sha256:1234abcdef</code></td>
		</tr>
		<tr>
			<td>image.pullPolicy</td>
			<td>string</td>
			<td><pre lang="json">
"IfNotPresent"
</pre>
</td>
			<td>imagePullPolicy for the Pipeline Optimization container Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images</td>
		</tr>
		<tr>
			<td>image.pullSecrets</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/  <pre><code> pullSecrets:<br>   - myRegistryKeySecretName </code></pre></td>
		</tr>
		<tr>
			<td>dbMigrationInitContainer.image.registry</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Migrate DB init container image registry</td>
		</tr>
		<tr>
			<td>dbMigrationInitContainer.image.repository</td>
			<td>string</td>
			<td><pre lang="json">
"private/nf-tower-enterprise/groundswell"
</pre>
</td>
			<td>Migrate DB init container image repository</td>
		</tr>
		<tr>
			<td>dbMigrationInitContainer.image.tag</td>
			<td>string</td>
			<td><pre lang="">
"{{ .chart.AppVersion }}"
</pre>
</td>
			<td>Migrate DB init container image tag</td>
		</tr>
		<tr>
			<td>dbMigrationInitContainer.image.digest</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Migrate DB init container image digest in the format <code>sha256:1234abcdef</code></td>
		</tr>
		<tr>
			<td>dbMigrationInitContainer.image.pullPolicy</td>
			<td>string</td>
			<td><pre lang="json">
"IfNotPresent"
</pre>
</td>
			<td>imagePullPolicy for the Migrate DB init container Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images</td>
		</tr>
		<tr>
			<td>dbMigrationInitContainer.command</td>
			<td>list</td>
			<td><pre lang="json">
[
  "/opt/groundswell/bin/migrate-db.sh"
]
</pre>
</td>
			<td>Command to run to migrate the database schema</td>
		</tr>
		<tr>
			<td>dbMigrationInitContainer.args</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td></td>
		</tr>
		<tr>
			<td>service.type</td>
			<td>string</td>
			<td><pre lang="json">
"ClusterIP"
</pre>
</td>
			<td>Pipeline Optimization Service type Note: ingresses using AWS ALB require the service to be NodePort</td>
		</tr>
		<tr>
			<td>service.http.name</td>
			<td>string</td>
			<td><pre lang="json">
"http"
</pre>
</td>
			<td>Service name to use</td>
		</tr>
		<tr>
			<td>service.http.port</td>
			<td>int</td>
			<td><pre lang="json">
8090
</pre>
</td>
			<td>Service port number</td>
		</tr>
		<tr>
			<td>service.http.targetPort</td>
			<td>int</td>
			<td><pre lang="json">
8090
</pre>
</td>
			<td>Port on the pod/container that the Service forwards traffic to (can be a number or named port, distinct from the Service's external port).</td>
		</tr>
		<tr>
			<td>service.http.nodePort</td>
			<td>string</td>
			<td><pre lang="json">
null
</pre>
</td>
			<td>Service node port, only used when service.type is Nodeport or LoadBalancer Choose port between 30000-32767, unless the cluster was configured differently than default</td>
		</tr>
		<tr>
			<td>service.extraServices</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Other services that should live in the Service object https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service  <pre><code> extraServices:<br> - name: myspecialservice<br>   port: 1234<br>   targetPort: 5678<br>   nodePort: null </code></pre></td>
		</tr>
		<tr>
			<td>service.extraOptions</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Extra Service options to place under .spec (for example, clusterIP, loadBalancerIP, externalTrafficPolicy, externalIPs). Evaluated as a template</td>
		</tr>
		<tr>
			<td>initContainers</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Additional init containers for the pipeline optimization pod. Evaluated as a template</td>
		</tr>
		<tr>
			<td>command</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Override default container command (useful when using custom images)</td>
		</tr>
		<tr>
			<td>args</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Override default container args (useful when using custom images)</td>
		</tr>
		<tr>
			<td>podLabels</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional labels for the pipeline optimization pod. Evaluated as a template</td>
		</tr>
		<tr>
			<td>podAnnotations</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional annotations for the pipeline optimization pod. Evaluated as a template</td>
		</tr>
		<tr>
			<td>commonAnnotations</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Annotations to add to all deployed objects</td>
		</tr>
		<tr>
			<td>commonLabels</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Labels to add to all deployed objects</td>
		</tr>
		<tr>
			<td>configMapAnnotations</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Annotations to add specifically to the ConfigMap</td>
		</tr>
		<tr>
			<td>configMapLabels</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Labels to add specifically to the ConfigMap</td>
		</tr>
		<tr>
			<td>extraOptionsSpec</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Extra options to place under .spec (e.g. replicas, strategy, revisionHistoryLimit, etc). Evaluated as a template  <pre><code> extraOptionsSpec:<br>   replicas: 2<br>   strategy:<br>     rollingUpdate:<br>       maxUnavailable: x<br>       maxSurge: y </code></pre></td>
		</tr>
		<tr>
			<td>extraOptionsTemplateSpec</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Extra options to place under .spec.template.spec (e.g. nodeSelector, affinity, restartPolicy, etc). Evaluated as a template  <pre><code> extraOptionsTemplateSpec:<br>   nodeSelector:<br>     service: myspecialnodegroup </code></pre></td>
		</tr>
		<tr>
			<td>extraEnvVars</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Extra environment variables to set on the pipeline optimization pod  <pre><code> extraEnvVars:<br>   - name: "CUSTOM_ENV_VAR"<br>     value: "set-a-value-here" </code></pre></td>
		</tr>
		<tr>
			<td>extraEnvVarsCMs</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>ConfigMap containing extra env vars</td>
		</tr>
		<tr>
			<td>extraEnvVarsSecrets</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Secret containing extra env vars</td>
		</tr>
		<tr>
			<td>extraVolumes</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Extra volumes to be added to the deployment (evaluated as template). Requires setting <code>extraVolumeMounts</code></td>
		</tr>
		<tr>
			<td>extraVolumeMounts</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Extra volume mounts to add to the container (evaluated as template). Normally used with <code>extraVolumes</code></td>
		</tr>
		<tr>
			<td>podSecurityContext.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable pod Security Context</td>
		</tr>
		<tr>
			<td>podSecurityContext.fsGroup</td>
			<td>int</td>
			<td><pre lang="json">
101
</pre>
</td>
			<td>Sets the GID that Kubernetes will apply to mounted volumes and created files so processes in the pod can share group-owned access</td>
		</tr>
		<tr>
			<td>containerSecurityContext.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable container Security Context</td>
		</tr>
		<tr>
			<td>containerSecurityContext.runAsUser</td>
			<td>int</td>
			<td><pre lang="json">
101
</pre>
</td>
			<td>UID the container processes run as (overrides container image default)</td>
		</tr>
		<tr>
			<td>containerSecurityContext.runAsNonRoot</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Boolean that requires the container to run as a non-root UID (prevents starting if UID 0)</td>
		</tr>
		<tr>
			<td>containerSecurityContext.readOnlyRootFilesystem</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Mounts the container root filesystem read-only to prevent in-place writes or tampering</td>
		</tr>
		<tr>
			<td>containerSecurityContext.capabilities</td>
			<td>object</td>
			<td><pre lang="json">
{
  "drop": [
    "ALL"
  ]
}
</pre>
</td>
			<td>Fine-grained Linux kernel privileges to add or drop for the container</td>
		</tr>
		<tr>
			<td>resources</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Container requests and limits for different resources like CPU or memory <code>.requests</code> are the minimum CPU/memory resources the scheduler uses to place a pod; the kubelet then guarantees at least these resources to the pod. <code>.limits</code> are the maximum resources a container is allowed to use Ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ Seqera recommends configuring resources to match the expected workload. The following are sensible defaults to start with  <pre><code> resources:<br>   requests:<br>     cpu: "1"<br>     memory: "1000Mi"<br>   limits:<br>     memory: "1000Mi" </code></pre></td>
		</tr>
		<tr>
			<td>startupProbe.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
false
</pre>
</td>
			<td>Enable startup probe</td>
		</tr>
		<tr>
			<td>startupProbe.httpGet.path</td>
			<td>string</td>
			<td><pre lang="json">
"/api/v1/health"
</pre>
</td>
			<td>HTTP GET path for startup probe</td>
		</tr>
		<tr>
			<td>startupProbe.httpGet.port</td>
			<td>string</td>
			<td><pre lang="json">
"{{ .Values.service.http.targetPort }}"
</pre>
</td>
			<td>HTTP GET port for startup probe. Evaluated as a template</td>
		</tr>
		<tr>
			<td>startupProbe.initialDelaySeconds</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Longer initial wait to accommodate slow-starting apps</td>
		</tr>
		<tr>
			<td>startupProbe.periodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
10
</pre>
</td>
			<td>Often set longer to avoid frequent checks while starting</td>
		</tr>
		<tr>
			<td>startupProbe.timeoutSeconds</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>Can be longer to allow slow initialization responses</td>
		</tr>
		<tr>
			<td>startupProbe.failureThreshold</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Consecutive failures during startup before killing the container (instead of immediate restarts)</td>
		</tr>
		<tr>
			<td>startupProbe.successThreshold</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Number of consecutive successes required to consider startup complete and enable liveness/readiness</td>
		</tr>
		<tr>
			<td>readinessProbe.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable readiness probe</td>
		</tr>
		<tr>
			<td>readinessProbe.httpGet.path</td>
			<td>string</td>
			<td><pre lang="json">
"/api/v1/health"
</pre>
</td>
			<td>HTTP GET path for readiness probe</td>
		</tr>
		<tr>
			<td>readinessProbe.httpGet.port</td>
			<td>string</td>
			<td><pre lang="json">
"{{ .Values.service.http.targetPort }}"
</pre>
</td>
			<td>HTTP GET port for readiness probe. Evaluated as a template</td>
		</tr>
		<tr>
			<td>readinessProbe.initialDelaySeconds</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Delay before first check (normal start timing)</td>
		</tr>
		<tr>
			<td>readinessProbe.periodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Regular check interval during normal operation</td>
		</tr>
		<tr>
			<td>readinessProbe.timeoutSeconds</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>Short timeout to detect unresponsive containers for readiness</td>
		</tr>
		<tr>
			<td>readinessProbe.failureThreshold</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Consecutive failures before marking the container Unready (no restart)</td>
		</tr>
		<tr>
			<td>readinessProbe.successThreshold</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Number of consecutive successes required to mark the container Ready after failures</td>
		</tr>
		<tr>
			<td>livenessProbe.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable liveness probe</td>
		</tr>
		<tr>
			<td>livenessProbe.httpGet.path</td>
			<td>string</td>
			<td><pre lang="json">
"/api/v1/health"
</pre>
</td>
			<td>HTTP GET path for liveness probe</td>
		</tr>
		<tr>
			<td>livenessProbe.httpGet.port</td>
			<td>string</td>
			<td><pre lang="json">
"{{ .Values.service.http.targetPort }}"
</pre>
</td>
			<td>HTTP GET port for liveness probe. Evaluated as a template</td>
		</tr>
		<tr>
			<td>livenessProbe.initialDelaySeconds</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Delay before first check (normal start timing)</td>
		</tr>
		<tr>
			<td>livenessProbe.periodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
10
</pre>
</td>
			<td>Regular check interval during normal operation</td>
		</tr>
		<tr>
			<td>livenessProbe.timeoutSeconds</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>Short timeout to detect hung containers quickly</td>
		</tr>
		<tr>
			<td>livenessProbe.failureThreshold</td>
			<td>int</td>
			<td><pre lang="json">
10
</pre>
</td>
			<td>Consecutive failures before restarting the container</td>
		</tr>
		<tr>
			<td>livenessProbe.successThreshold</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Typically 1 (usually ignored)</td>
		</tr>
		<tr>
			<td>initContainerDependencies.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable init containers that coordinate startup dependencies (for example, wait for database readiness before starting, etc)</td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForMySQL.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable wait for MySQL init container before starting pipeline optimization and cron</td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForMySQL.image.registry</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Override default wait for MySQL init container image</td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForMySQL.image.repository</td>
			<td>string</td>
			<td><pre lang="json">
"mysql"
</pre>
</td>
			<td></td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForMySQL.image.tag</td>
			<td>string</td>
			<td><pre lang="json">
"9"
</pre>
</td>
			<td></td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForMySQL.image.digest</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td></td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForMySQL.image.pullPolicy</td>
			<td>string</td>
			<td><pre lang="json">
"IfNotPresent"
</pre>
</td>
			<td></td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForMySQL.securityContext.runAsUser</td>
			<td>int</td>
			<td><pre lang="json">
101
</pre>
</td>
			<td>UID the container processes run as (overrides container image default)</td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForMySQL.securityContext.runAsNonRoot</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Require the container to run as a non-root UID (prevents starting if UID 0)</td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForMySQL.securityContext.readOnlyRootFilesystem</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Mount the container root filesystem read-only to prevent in-place writes or tampering</td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForMySQL.securityContext.capabilities</td>
			<td>object</td>
			<td><pre lang="json">
{
  "drop": [
    "ALL"
  ]
}
</pre>
</td>
			<td>Fine-grained Linux kernel privileges to add or drop for the container</td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForMySQL.resources</td>
			<td>object</td>
			<td><pre lang="json">
{
  "limits": {
    "memory": "100Mi"
  },
  "requests": {
    "cpu": "0.5",
    "memory": "50Mi"
  }
}
</pre>
</td>
			<td>Container requests and limits for different resources like CPU or memory</td>
		</tr>
		<tr>
			<td>serviceAccount.name</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Name of an existing ServiceAccount. If not set, a new ServiceAccount is generated based on the release name</td>
		</tr>
		<tr>
			<td>serviceAccount.annotations</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional annotations for the Platform ServiceAccount to generate</td>
		</tr>
		<tr>
			<td>serviceAccount.imagePullSecretNames</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Names of Secrets containing credentials to pull images from registries</td>
		</tr>
		<tr>
			<td>serviceAccount.automountServiceAccountToken</td>
			<td>bool</td>
			<td><pre lang="json">
false
</pre>
</td>
			<td>Automount service account token when the server service account is generated</td>
		</tr>
	</tbody>
</table>

## Licensing

Seqera® and Nextflow® are registered trademarks of Seqera Labs.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
