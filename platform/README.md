# platform

A Helm chart to deploy Seqera Platform (also referred to as Tower) on Kubernetes.

![Version: 0.22.1](https://img.shields.io/badge/Version-0.22.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v25.3.0](https://img.shields.io/badge/AppVersion-v25.3.0-informational?style=flat-square)

> [!WARNING]
> This chart is currently still in development and breaking changes are expected.
> The public API SHOULD NOT be considered stable.

## Requirements and configuration

For an overview of the Seqera Platform architecture and its requirements, refer to the [Seqera documentation](https://docs.seqera.io/platform-enterprise/enterprise/overview).

The chart does not automatically define `cr.seqera.io` as the registry where to take the images from: instructions are available to [vendor the Seqera container images to your private registry](https://docs.seqera.io/platform-enterprise/enterprise/prerequisites/common#vendoring-seqera-container-images-to-your-own-registry).

The required values to set in order to have a working installation are:
- The `.image` section under the `.backend`, `.frontend`, `.cron` and `.cron.dbMigrationInitContainer` components to point to your container registry.
- Container registry credentials under the `.global.imageCredentials` section (can be the credentials for `cr.seqera.io` or your private registry where you vendored the images to).
  * These credentials will be used by all the subcharts unless overridden in the specific subchart.
  * Multiple credentials can be specified to cover different registries.
  * Specific pull secrets can be defined in each `.image` section to extend the global credentials.
  * Image pull secrets defined in the specific `.image` section will be added to the global ones, not replacing them.
- The database connection details for the Platform MySQL database under the `.platformDatabase` section.
- The redis connection details under the `.redis` section.
- The Seqera license key under the `.platform.licenseString` value, or the name of an existing Secret containing the license key under the `.platform.licenseSecretName` value.

The Helm chart comes with several requirement checks that will validate the provided configuration before proceeding with the installation.

By default the chart selects the Platform application images defined in the `appVersion` field of the `Chart.yaml` file, currently set as `v25.3.0`.

> [!NOTE]
> The Platform chart requires the [unprivileged version](https://docs.seqera.io/platform-enterprise/enterprise/kubernetes#seqera-frontend-unprivileged) of the Seqera Platform frontend image (shipped with `-unprivileged` suffix until Platform v25.3, without any suffix starting from v26.1).

When a sensitive value is required (e.g. the database password, the Seqera license key), you can either provide it directly in the values file or reference an existing Kubernetes Secret containing the value. The key names to use in the provided Secret are specified in the values file comments.
Sensitive values provided as plain text by the user are always stored in a Kubernetes Secret created by the chart. When an external Secret is referenced, the chart instructs the components to read the sensitive value from the external Secret directly, without storing copies of the sensitive value in the chart-created Secret.

## Installing the chart

To install the chart with the release name `my-release`:

```console
helm install my-release oci://public.cr.seqera.io/charts/platform \
  --version 0.22.1 \
  --namespace my-namespace \
  --create-namespace
```

For a list of available chart versions, see the chart repository: https://public.cr.seqera.io/repo/charts/platform

## Examples

Refer to the [examples directory](./examples) for different scenarios of installing the Platform chart.
The examples provided are showcasing possible configurations of the Helm chart, and are not representative of a full installation.
Please refer to the [Seqera Platform documentation](https://docs.seqera.io/platform-enterprise/enterprise/overview) for complete installation instructions.

## Upgrading the chart

When upgrading between versions, please refer to the [CHANGELOG.md](CHANGELOG.md) for breaking changes and migration instructions.

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://charts/pipeline-optimization | pipeline-optimization | 0.1.x |
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
			<td>global.platformExternalDomain</td>
			<td>string</td>
			<td><pre lang="json">
"example.com"
</pre>
</td>
			<td>Domain where Seqera Platform listens</td>
		</tr>
		<tr>
			<td>global.contentDomain</td>
			<td>string</td>
			<td><pre lang="json">
"{{ printf \"user-data.%s\" .Values.global.platformExternalDomain }}"
</pre>
</td>
			<td>Domain where user-created Platform reports are exposed, to avoid Cross-Site Scripting (XSS) attacks. If unset, data is served through the main domain <code>.global.platformExternalDomain</code>. Evaluated as a template</td>
		</tr>
		<tr>
			<td>global.platformServiceAddress</td>
			<td>string</td>
			<td><pre lang="json">
"{{ printf \"%s-backend\" (include \"common.names.fullname\" .) }}"
</pre>
</td>
			<td>Seqera Platform Service name: can be the internal Kubernetes hostname or an external ingress hostname. Evaluated as a template</td>
		</tr>
		<tr>
			<td>global.platformServicePort</td>
			<td>int</td>
			<td><pre lang="json">
8080
</pre>
</td>
			<td>Seqera Platform Service port</td>
		</tr>
		<tr>
			<td>global.imageCredentials</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Optional credentials to log in and fetch images from a private registry. These credentials are shared with all the subcharts automatically  <pre><code> - registry: ""</br>   username: ""</br>   password: ""</br>   email: someone@example.com  # Optional </code></pre></td>
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
			<td>Platform MySQL database username</td>
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
			<td>Name of an existing secret containing credentials for the Platform MySQL database. Note: the secret must already exist in the same namespace at the time of deployment, it can't be created by this chart with extraDeploy, since this chart performs a lookup on the Kubernetes API server at install/upgrade time</td>
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
			<td>platformDatabase.driver</td>
			<td>string</td>
			<td><pre lang="json">
"mariadb"
</pre>
</td>
			<td>Database driver. Possible options: "mariadb" (or its alias "mysql")</td>
		</tr>
		<tr>
			<td>platformDatabase.connectionOptions</td>
			<td>object</td>
			<td><pre lang="json">
{
  "mariadb": [
    "permitMysqlScheme=true"
  ]
}
</pre>
</td>
			<td>Connection options to compose in the driver URL according to the driver used. The only driver that can be set is 'mariadb'</td>
		</tr>
		<tr>
			<td>platformDatabase.connectionOptions.mariadb</td>
			<td>list</td>
			<td><pre lang="json">
[
  "permitMysqlScheme=true"
]
</pre>
</td>
			<td>Connection options to use with the MariaDB driver. For the full list of supported options see: https://mariadb.com/docs/connectors/mariadb-connector-j/about-mariadb-connector-j</td>
		</tr>
		<tr>
			<td>platformDatabase.dialect</td>
			<td>string</td>
			<td><pre lang="json">
"mysql-8"
</pre>
</td>
			<td>Hibernate dialect to use, depending on the database version. Possible options: mysql-8 (default), mariadb-10</td>
		</tr>
		<tr>
			<td>platformDatabase.minPoolSize</td>
			<td>string</td>
			<td><pre lang="json">
"2"
</pre>
</td>
			<td>Connection pool minimum size</td>
		</tr>
		<tr>
			<td>platformDatabase.maxPoolSize</td>
			<td>string</td>
			<td><pre lang="json">
"10"
</pre>
</td>
			<td>Connection pool maximum size</td>
		</tr>
		<tr>
			<td>platformDatabase.maxLifetime</td>
			<td>string</td>
			<td><pre lang="json">
"180000"
</pre>
</td>
			<td>Connection pool maximum lifetime</td>
		</tr>
		<tr>
			<td>platform.YAMLConfigFileContent</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Content to insert into the tower.yml file (you can use <code>\|-</code> YAML multilines). See https://docs.seqera.io/platform-enterprise/enterprise/configuration/overview</td>
		</tr>
		<tr>
			<td>platform.contactEmail</td>
			<td>string</td>
			<td><pre lang="json">
"support@example.com"
</pre>
</td>
			<td>Sender email address for user support</td>
		</tr>
		<tr>
			<td>platform.jwtSeedString</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>JWT seed, defined as string, used to sign authentication tokens Define the value as a String or a Secret, not both at the same time If neither is defined, Helm generates a random 35-character string</td>
		</tr>
		<tr>
			<td>platform.jwtSeedSecretName</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Name of an existing Secret containing the JWT seed. Note: the secret must already exist in the same namespace at the time of deployment, it can't be created by this chart with extraDeploy, since this chart performs a lookup on the Kubernetes API server at install/upgrade time</td>
		</tr>
		<tr>
			<td>platform.jwtSeedSecretKey</td>
			<td>string</td>
			<td><pre lang="">
"TOWER_JWT_SECRET"
</pre>
</td>
			<td>Key in the existing secret containing the JWT seed</td>
		</tr>
		<tr>
			<td>platform.cryptoSeedString</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Crypto seed, defined as string, used to encrypt sensitive data in the database. Note: this needs to be a stable value that doesn't change between deployments, otherwise encrypted data in the database will become inaccessible. Either define the value as a String or a Secret, not both at the same time. If neither is defined, a random 35 characters long string will be generated by Helm</td>
		</tr>
		<tr>
			<td>platform.cryptoSeedSecretName</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Name of an existing Secret containing the crypto seed. Note: the secret must already exist in the same namespace at the time of deployment, it can't be created by this chart with extraDeploy, since this chart performs a lookup on the Kubernetes API server at install/upgrade time</td>
		</tr>
		<tr>
			<td>platform.cryptoSeedSecretKey</td>
			<td>string</td>
			<td><pre lang="">
"TOWER_CRYPTO_SECRETKEY"
</pre>
</td>
			<td>Key in the existing secret containing the crypto seed</td>
		</tr>
		<tr>
			<td>platform.executionBackends</td>
			<td>list</td>
			<td><pre lang="json">
[
  "altair-platform",
  "awsbatch-platform",
  "awscloud-platform",
  "azbatch-platform",
  "azcloud-platform",
  "eks-platform",
  "gke-platform",
  "googlebatch-platform",
  "googlecloud-platform",
  "k8s-platform",
  "local-platform",
  "lsf-platform",
  "moab-platform",
  "slurm-platform"
]
</pre>
</td>
			<td>List of execution backends to enable. At least one is required. See https://docs.seqera.io/platform-enterprise/enterprise/configuration/overview#compute-environments</td>
		</tr>
		<tr>
			<td>platform.licenseString</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Platform license key. A license key is a long alphanumeric string provided by your Seqera account manager Define the value as a String or a Secret, not both at the same time</td>
		</tr>
		<tr>
			<td>platform.licenseSecretName</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Name of an existing Secret containing the Platform license key. Note: the secret must already exist in the same namespace at the time of deployment, it can't be created by this chart with extraDeploy, since this chart performs a lookup on the Kubernetes API server at install/upgrade time</td>
		</tr>
		<tr>
			<td>platform.licenseSecretKey</td>
			<td>string</td>
			<td><pre lang="">
"TOWER_LICENSE"
</pre>
</td>
			<td>Key in the existing secret containing the Platform license key</td>
		</tr>
		<tr>
			<td>platform.smtp.host</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>SMTP server hostname to let users authenticate through email, and to send email notifications for events</td>
		</tr>
		<tr>
			<td>platform.smtp.port</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>SMTP server port</td>
		</tr>
		<tr>
			<td>platform.smtp.user</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>SMTP server username</td>
		</tr>
		<tr>
			<td>platform.smtp.password</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>SMTP server password</td>
		</tr>
		<tr>
			<td>platform.smtp.existingSecretName</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Name of an existing secret containing the SMTP password</td>
		</tr>
		<tr>
			<td>platform.smtp.existingSecretKey</td>
			<td>string</td>
			<td><pre lang="">
"TOWER_SMTP_PASSWORD"
</pre>
</td>
			<td>Key in the existing secret containing the SMTP password</td>
		</tr>
		<tr>
			<td>platform.waveServerUrl</td>
			<td>string</td>
			<td><pre lang="json">
"https://wave.seqera.io"
</pre>
</td>
			<td>URL of the Wave service Platform uses. Evaluated as a template. The Wave service provided by Seqera is <code>https://wave.seqera.io</code></td>
		</tr>
		<tr>
			<td>platform.configMapLabels</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional labels for the ConfigMap objects. Evaluated as a template</td>
		</tr>
		<tr>
			<td>platform.secretLabels</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional labels for the Secret objects. Evaluated as a template</td>
		</tr>
		<tr>
			<td>platform.serviceLabels</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional labels for the Service objects. Evaluated as a template</td>
		</tr>
		<tr>
			<td>platform.configMapAnnotations</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional annotations for the ConfigMap objects. Evaluated as a template</td>
		</tr>
		<tr>
			<td>platform.secretAnnotations</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional annotations for the Secret objects. Evaluated as a template</td>
		</tr>
		<tr>
			<td>platform.serviceAnnotations</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional annotations for the Service objects. Evaluated as a template</td>
		</tr>
		<tr>
			<td>redis.host</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Redis hostname</td>
		</tr>
		<tr>
			<td>redis.port</td>
			<td>int</td>
			<td><pre lang="json">
6379
</pre>
</td>
			<td>Redis port</td>
		</tr>
		<tr>
			<td>redis.password</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Redis password if the installation requires it</td>
		</tr>
		<tr>
			<td>redis.existingSecretName</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Name of an existing secret containing credentials for Redis, as an alternative to the password field. Note: the secret must already exist in the same namespace at the time of deployment, it can't be created by this chart with extraDeploy, since this chart performs a lookup on the Kubernetes API server at install/upgrade time</td>
		</tr>
		<tr>
			<td>redis.existingSecretKey</td>
			<td>string</td>
			<td><pre lang="">
"TOWER_REDIS_PASSWORD"
</pre>
</td>
			<td>Key in the existing secret containing the password for Redis</td>
		</tr>
		<tr>
			<td>redis.enableTls</td>
			<td>bool</td>
			<td><pre lang="json">
false
</pre>
</td>
			<td>Enable TLS when connecting to Redis</td>
		</tr>
		<tr>
			<td>extraDeploy</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Array of extra objects to deploy with the release  <pre><code> extraDeploy:<br>   - apiVersion: v1<br>     kind: MyExtraObjectKind<br>     ...<br>   - apiVersion: v1<br>     kind: AnotherExtraObjectKind<br>     ... </code></pre></td>
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
			<td>backend.image.registry</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Backend container image registry</td>
		</tr>
		<tr>
			<td>backend.image.repository</td>
			<td>string</td>
			<td><pre lang="json">
"private/nf-tower-enterprise/backend"
</pre>
</td>
			<td>Backend container image repository</td>
		</tr>
		<tr>
			<td>backend.image.tag</td>
			<td>string</td>
			<td><pre lang="">
"{{ .chart.AppVersion }}"
</pre>
</td>
			<td>Backend container image tag</td>
		</tr>
		<tr>
			<td>backend.image.digest</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Backend container image digest in the format <code>sha256:1234abcdef</code></td>
		</tr>
		<tr>
			<td>backend.image.pullPolicy</td>
			<td>string</td>
			<td><pre lang="json">
"IfNotPresent"
</pre>
</td>
			<td>imagePullPolicy for the backend container Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images</td>
		</tr>
		<tr>
			<td>backend.image.pullSecrets</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/  <pre><code> pullSecrets:<br>   - myRegistryKeySecretName </code></pre></td>
		</tr>
		<tr>
			<td>backend.micronautEnvironments</td>
			<td>list</td>
			<td><pre lang="json">
[
  "prod",
  "redis",
  "ha"
]
</pre>
</td>
			<td>List of Micronaut Environments to enable on the backend pod</td>
		</tr>
		<tr>
			<td>backend.service.type</td>
			<td>string</td>
			<td><pre lang="json">
"ClusterIP"
</pre>
</td>
			<td>Backend Service type. Note: ingresses using AWS ALB require the service to be NodePort</td>
		</tr>
		<tr>
			<td>backend.service.http.name</td>
			<td>string</td>
			<td><pre lang="json">
"http"
</pre>
</td>
			<td>Service name to use</td>
		</tr>
		<tr>
			<td>backend.service.http.targetPort</td>
			<td>int</td>
			<td><pre lang="json">
8080
</pre>
</td>
			<td>Port on the pod/container that the Service forwards traffic to (can be a number or named port, distinct from the Service's external port). Platform v25.3+ only; previous versions were hardcoded to 8080</td>
		</tr>
		<tr>
			<td>backend.service.http.nodePort</td>
			<td>string</td>
			<td><pre lang="json">
null
</pre>
</td>
			<td>Service node port, only used when service.type is Nodeport or LoadBalancer Choose port between 30000-32767, unless the cluster was configured differently than default</td>
		</tr>
		<tr>
			<td>backend.service.extraServices</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Other services that should live in the Service object https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service  <pre><code> extraServices:<br> - name: myspecialservice<br>   port: 1234<br>   targetPort: 5678<br>   nodePort: null </code></pre></td>
		</tr>
		<tr>
			<td>backend.service.extraOptions</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Extra Service options to place under .spec (for example, clusterIP, loadBalancerIP, externalTrafficPolicy, externalIPs). Evaluated as a template</td>
		</tr>
		<tr>
			<td>backend.initContainers</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Additional init containers for the backend pod. Evaluated as a template</td>
		</tr>
		<tr>
			<td>backend.command</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Override default container command (useful when using custom images)</td>
		</tr>
		<tr>
			<td>backend.args</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Override default container args (useful when using custom images)</td>
		</tr>
		<tr>
			<td>backend.podLabels</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional labels for the backend pod. Evaluated as a template</td>
		</tr>
		<tr>
			<td>backend.podAnnotations</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional annotations for the backend pod. Evaluated as a template</td>
		</tr>
		<tr>
			<td>backend.extraOptionsSpec</td>
			<td>object</td>
			<td><pre lang="json">
{
  "replicas": 3
}
</pre>
</td>
			<td>Extra options to place under .spec (e.g. replicas, strategy, revisionHistoryLimit, etc). Evaluated as a template  <pre><code> extraOptionsSpec:<br>   replicas: 2<br>   strategy:<br>     rollingUpdate:<br>       maxUnavailable: x<br>       maxSurge: y </code></pre></td>
		</tr>
		<tr>
			<td>backend.extraOptionsTemplateSpec</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Extra options to place under .spec.template.spec (e.g. nodeSelector, affinity, restartPolicy, etc). Evaluated as a template  <pre><code> extraOptionsTemplateSpec:<br>   nodeSelector:<br>     service: myspecialnodegroup </code></pre></td>
		</tr>
		<tr>
			<td>backend.extraEnvVars</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Extra environment variables to set on the backend pod  <pre><code> extraEnvVars:<br>   - name: "CUSTOM_ENV_VAR"<br>     value: "set-a-value-here" </code></pre></td>
		</tr>
		<tr>
			<td>backend.extraEnvVarsCMs</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>ConfigMap containing extra env vars</td>
		</tr>
		<tr>
			<td>backend.extraEnvVarsSecrets</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Secret containing extra env vars</td>
		</tr>
		<tr>
			<td>backend.extraVolumes</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Extra volumes to be added to the deployment (evaluated as template). Requires setting <code>extraVolumeMounts</code></td>
		</tr>
		<tr>
			<td>backend.extraVolumeMounts</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Extra volume mounts to add to the container (evaluated as template). Normally used with <code>extraVolumes</code></td>
		</tr>
		<tr>
			<td>backend.podSecurityContext.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable pod Security Context</td>
		</tr>
		<tr>
			<td>backend.podSecurityContext.fsGroup</td>
			<td>int</td>
			<td><pre lang="json">
101
</pre>
</td>
			<td>Sets the GID that Kubernetes will apply to mounted volumes and created files so processes in the pod can share group-owned access</td>
		</tr>
		<tr>
			<td>backend.containerSecurityContext.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable container Security Context</td>
		</tr>
		<tr>
			<td>backend.containerSecurityContext.runAsUser</td>
			<td>int</td>
			<td><pre lang="json">
101
</pre>
</td>
			<td>UID the container processes run as (overrides container image default)</td>
		</tr>
		<tr>
			<td>backend.containerSecurityContext.runAsNonRoot</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Boolean that requires the container to run as a non-root UID (prevents starting if UID 0)</td>
		</tr>
		<tr>
			<td>backend.containerSecurityContext.readOnlyRootFilesystem</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Mounts the container root filesystem read-only to prevent in-place writes or tampering</td>
		</tr>
		<tr>
			<td>backend.containerSecurityContext.capabilities</td>
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
			<td>backend.resources</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Container requests and limits for different resources like CPU or memory <code>.requests</code> are the minimum CPU/memory resources the scheduler uses to place a pod; the kubelet then guarantees at least these resources to the pod. <code>.limits</code> are the maximum resources a container is allowed to use Ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ Seqera recommends configuring resources to match the expected workload. The following are sensible defaults to start with  <pre><code> resources:<br>   requests:<br>     cpu: "1"<br>     memory: "4000Mi"<br>   limits:<br>     memory: "4000Mi" </code></pre></td>
		</tr>
		<tr>
			<td>backend.startupProbe.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
false
</pre>
</td>
			<td>Enable startup probe</td>
		</tr>
		<tr>
			<td>backend.startupProbe.httpGet.path</td>
			<td>string</td>
			<td><pre lang="json">
"/health"
</pre>
</td>
			<td>HTTP GET path for startup probe</td>
		</tr>
		<tr>
			<td>backend.startupProbe.httpGet.port</td>
			<td>string</td>
			<td><pre lang="json">
"{{ .Values.backend.service.http.targetPort }}"
</pre>
</td>
			<td>HTTP GET port for startup probe. Evaluated as a template. Note: before v25.3 this was hardcoded to 8080</td>
		</tr>
		<tr>
			<td>backend.startupProbe.initialDelaySeconds</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Longer initial wait to accommodate slow-starting apps</td>
		</tr>
		<tr>
			<td>backend.startupProbe.periodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
10
</pre>
</td>
			<td>Often set longer to avoid frequent checks while starting</td>
		</tr>
		<tr>
			<td>backend.startupProbe.timeoutSeconds</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>Can be longer to allow slow initialization responses</td>
		</tr>
		<tr>
			<td>backend.startupProbe.failureThreshold</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Consecutive failures during startup before killing the container (instead of immediate restarts)</td>
		</tr>
		<tr>
			<td>backend.startupProbe.successThreshold</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Number of consecutive successes required to consider startup complete and enable liveness/readiness</td>
		</tr>
		<tr>
			<td>backend.readinessProbe.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable readiness probe</td>
		</tr>
		<tr>
			<td>backend.readinessProbe.httpGet.path</td>
			<td>string</td>
			<td><pre lang="json">
"/health"
</pre>
</td>
			<td>HTTP GET path for readiness probe</td>
		</tr>
		<tr>
			<td>backend.readinessProbe.httpGet.port</td>
			<td>string</td>
			<td><pre lang="json">
"{{ .Values.backend.service.http.targetPort }}"
</pre>
</td>
			<td>HTTP GET port for readiness probe. Evaluated as a template. Note: before v25.3 this was hardcoded to 8080</td>
		</tr>
		<tr>
			<td>backend.readinessProbe.initialDelaySeconds</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Delay before first check (normal start timing)</td>
		</tr>
		<tr>
			<td>backend.readinessProbe.periodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Regular check interval during normal operation</td>
		</tr>
		<tr>
			<td>backend.readinessProbe.timeoutSeconds</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>Short timeout to detect unresponsive containers for readiness</td>
		</tr>
		<tr>
			<td>backend.readinessProbe.failureThreshold</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Consecutive failures before marking the container Unready (no restart)</td>
		</tr>
		<tr>
			<td>backend.readinessProbe.successThreshold</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Number of consecutive successes required to mark the container Ready after failures</td>
		</tr>
		<tr>
			<td>backend.livenessProbe.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable liveness probe</td>
		</tr>
		<tr>
			<td>backend.livenessProbe.httpGet.path</td>
			<td>string</td>
			<td><pre lang="json">
"/health"
</pre>
</td>
			<td>HTTP GET path for liveness probe</td>
		</tr>
		<tr>
			<td>backend.livenessProbe.httpGet.port</td>
			<td>string</td>
			<td><pre lang="json">
"{{ .Values.backend.service.http.targetPort }}"
</pre>
</td>
			<td>HTTP GET port for liveness probe. Evaluated as a template. Note: before v25.3 this was hardcoded to 8080</td>
		</tr>
		<tr>
			<td>backend.livenessProbe.initialDelaySeconds</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Delay before first check (normal start timing)</td>
		</tr>
		<tr>
			<td>backend.livenessProbe.periodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
10
</pre>
</td>
			<td>Regular check interval during normal operation</td>
		</tr>
		<tr>
			<td>backend.livenessProbe.timeoutSeconds</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>Short timeout to detect hung containers quickly</td>
		</tr>
		<tr>
			<td>backend.livenessProbe.failureThreshold</td>
			<td>int</td>
			<td><pre lang="json">
10
</pre>
</td>
			<td>Consecutive failures before restarting the container</td>
		</tr>
		<tr>
			<td>backend.livenessProbe.successThreshold</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Typically 1 (usually ignored)</td>
		</tr>
		<tr>
			<td>frontend.image.registry</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Frontend container image registry</td>
		</tr>
		<tr>
			<td>frontend.image.repository</td>
			<td>string</td>
			<td><pre lang="json">
"private/nf-tower-enterprise/frontend"
</pre>
</td>
			<td>Frontend container image repository</td>
		</tr>
		<tr>
			<td>frontend.image.tag</td>
			<td>string</td>
			<td><pre lang="">
"{{ .chart.AppVersion }}-unprivileged"
</pre>
</td>
			<td>Specify a tag to override the version defined in .Chart.appVersion</td>
		</tr>
		<tr>
			<td>frontend.image.digest</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Frontend container image digest in the format <code>sha256:1234abcdef</code></td>
		</tr>
		<tr>
			<td>frontend.image.pullPolicy</td>
			<td>string</td>
			<td><pre lang="json">
"IfNotPresent"
</pre>
</td>
			<td>imagePullPolicy for the frontend container Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images</td>
		</tr>
		<tr>
			<td>frontend.image.pullSecrets</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/  <pre><code> pullSecrets:<br>   - myRegistryKeySecretName </code></pre></td>
		</tr>
		<tr>
			<td>frontend.service.type</td>
			<td>string</td>
			<td><pre lang="json">
"ClusterIP"
</pre>
</td>
			<td>Frontend Service type. Note: ingresses using AWS ALB require the service to be NodePort</td>
		</tr>
		<tr>
			<td>frontend.service.http.name</td>
			<td>string</td>
			<td><pre lang="json">
"http"
</pre>
</td>
			<td>Service name to use</td>
		</tr>
		<tr>
			<td>frontend.service.http.port</td>
			<td>int</td>
			<td><pre lang="json">
80
</pre>
</td>
			<td>Service port</td>
		</tr>
		<tr>
			<td>frontend.service.http.targetPort</td>
			<td>int</td>
			<td><pre lang="json">
8083
</pre>
</td>
			<td>Port on the pod/container that the Service forwards traffic to (can be a number or named port, distinct from the Service's external port)</td>
		</tr>
		<tr>
			<td>frontend.service.http.nodePort</td>
			<td>int</td>
			<td><pre lang="json">
null
</pre>
</td>
			<td>Service node port, only used when service.type is Nodeport or LoadBalancer Choose port between 30000-32767, unless the cluster was configured differently than default</td>
		</tr>
		<tr>
			<td>frontend.service.extraServices</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Other services that should live in the Service object https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service  <pre><code> extraServices:<br> - name: myspecialservice<br>   port: 1234<br>   targetPort: 5678<br>   nodePort: null </code></pre></td>
		</tr>
		<tr>
			<td>frontend.service.extraOptions</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Extra Service options to place under .spec (for example, clusterIP, loadBalancerIP, externalTrafficPolicy, externalIPs). Evaluated as a template</td>
		</tr>
		<tr>
			<td>frontend.initContainers</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Additional init containers for the frontend pod. Evaluated as a template</td>
		</tr>
		<tr>
			<td>frontend.command</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Override default container command (useful when using custom images)</td>
		</tr>
		<tr>
			<td>frontend.args</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Override default container args (useful when using custom images)</td>
		</tr>
		<tr>
			<td>frontend.podLabels</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional labels for the frontend pod. Evaluated as a template</td>
		</tr>
		<tr>
			<td>frontend.podAnnotations</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional annotations for the frontend pod. Evaluated as a template</td>
		</tr>
		<tr>
			<td>frontend.extraOptionsSpec</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Extra options to place under .spec (e.g. revisionHistoryLimit, etc). Evaluated as a template. Note: the cron deployment can only run a single replica and use Recreate strategy  <pre><code> extraOptionsSpec:<br>   replicas: 2<br>   strategy:<br>     rollingUpdate:<br>       maxUnavailable: x<br>       maxSurge: y </code></pre></td>
		</tr>
		<tr>
			<td>frontend.extraOptionsTemplateSpec</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Extra options to place under .spec.template.spec (for example, nodeSelector, affinity, restartPolicy). Evaluated as a template  <pre><code> extraOptionsTemplateSpec:<br>   nodeSelector:<br>     service: myspecialnodegroup </code></pre></td>
		</tr>
		<tr>
			<td>frontend.extraEnvVars</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Extra environment variables to set on the frontend pod  <pre><code> extraEnvVars:<br>   - name: "CUSTOM_ENV_VAR"<br>     value: "set-a-value-here" </code></pre></td>
		</tr>
		<tr>
			<td>frontend.extraEnvVarsCMs</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>ConfigMap containing extra env vars</td>
		</tr>
		<tr>
			<td>frontend.extraEnvVarsSecrets</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Secret containing extra env vars</td>
		</tr>
		<tr>
			<td>frontend.extraVolumes</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Extra volumes to add to the deployment (evaluated as template). Requires setting <code>extraVolumeMounts</code></td>
		</tr>
		<tr>
			<td>frontend.extraVolumeMounts</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Extra volume mounts to add to the container (evaluated as template). Normally used with <code>extraVolumes</code></td>
		</tr>
		<tr>
			<td>frontend.podSecurityContext.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable pod Security Context</td>
		</tr>
		<tr>
			<td>frontend.podSecurityContext.fsGroup</td>
			<td>int</td>
			<td><pre lang="json">
101
</pre>
</td>
			<td>GID that Kubernetes applies to mounted volumes and created files so processes in the pod can share group-owned access</td>
		</tr>
		<tr>
			<td>frontend.containerSecurityContext.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable container Security Context</td>
		</tr>
		<tr>
			<td>frontend.containerSecurityContext.runAsUser</td>
			<td>int</td>
			<td><pre lang="json">
101
</pre>
</td>
			<td>UID the container processes run as (overrides container image default)</td>
		</tr>
		<tr>
			<td>frontend.containerSecurityContext.runAsNonRoot</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Require the container to run as a non-root UID (prevents starting if UID 0)</td>
		</tr>
		<tr>
			<td>frontend.containerSecurityContext.readOnlyRootFilesystem</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Mount the container root filesystem read-only to prevent in-place writes or tampering</td>
		</tr>
		<tr>
			<td>frontend.containerSecurityContext.capabilities</td>
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
			<td>frontend.resources</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Container requests and limits for different resources like CPU or memory <code>.requests</code> are the minimum CPU/memory resources the scheduler uses to place a pod; the kubelet then guarantees at least these resources to the pod. <code>.limits</code> are the maximum resources a container is allowed to use Ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ Seqera recommends configuring resources to match the expected workload. The following are sensible defaults to start with  <pre><code> resources:<br>   requests:<br>     cpu: "200m"<br>     memory: "200Mi"<br>   limits:<br>     memory: "200Mi" </code></pre></td>
		</tr>
		<tr>
			<td>frontend.startupProbe.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
false
</pre>
</td>
			<td>Enable startup probe</td>
		</tr>
		<tr>
			<td>frontend.startupProbe.httpGet.path</td>
			<td>string</td>
			<td><pre lang="json">
"/health"
</pre>
</td>
			<td>HTTP GET path for startup probe</td>
		</tr>
		<tr>
			<td>frontend.startupProbe.httpGet.port</td>
			<td>string</td>
			<td><pre lang="json">
"{{ .Values.frontend.service.http.targetPort }}"
</pre>
</td>
			<td>HTTP GET port for startup probe. Evaluated as a template</td>
		</tr>
		<tr>
			<td>frontend.startupProbe.initialDelaySeconds</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Longer initial wait to accommodate slow-starting apps</td>
		</tr>
		<tr>
			<td>frontend.startupProbe.periodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
10
</pre>
</td>
			<td>Often set longer to avoid frequent checks while starting</td>
		</tr>
		<tr>
			<td>frontend.startupProbe.timeoutSeconds</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>Can be longer to allow slow initialization responses</td>
		</tr>
		<tr>
			<td>frontend.startupProbe.failureThreshold</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Consecutive failures during startup before killing the container (instead of immediate restarts)</td>
		</tr>
		<tr>
			<td>frontend.startupProbe.successThreshold</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Number of consecutive successes required to consider startup complete and enable liveness/readiness</td>
		</tr>
		<tr>
			<td>frontend.readinessProbe.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable readiness probe</td>
		</tr>
		<tr>
			<td>frontend.readinessProbe.httpGet.path</td>
			<td>string</td>
			<td><pre lang="json">
"/health"
</pre>
</td>
			<td>HTTP GET path for readiness probe</td>
		</tr>
		<tr>
			<td>frontend.readinessProbe.httpGet.port</td>
			<td>string</td>
			<td><pre lang="json">
"{{ .Values.frontend.service.http.targetPort }}"
</pre>
</td>
			<td>HTTP GET port for readiness probe. Evaluated as a template</td>
		</tr>
		<tr>
			<td>frontend.readinessProbe.initialDelaySeconds</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Delay before first check (normal start timing)</td>
		</tr>
		<tr>
			<td>frontend.readinessProbe.periodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Regular check interval during normal operation</td>
		</tr>
		<tr>
			<td>frontend.readinessProbe.timeoutSeconds</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>Short timeout to detect unresponsive containers for readiness</td>
		</tr>
		<tr>
			<td>frontend.readinessProbe.failureThreshold</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Consecutive failures before marking the container Unready (no restart)</td>
		</tr>
		<tr>
			<td>frontend.readinessProbe.successThreshold</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Number of consecutive successes required to mark the container Ready after failures</td>
		</tr>
		<tr>
			<td>frontend.livenessProbe.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable liveness probe</td>
		</tr>
		<tr>
			<td>frontend.livenessProbe.httpGet.path</td>
			<td>string</td>
			<td><pre lang="json">
"/health"
</pre>
</td>
			<td>HTTP GET path for liveness probe</td>
		</tr>
		<tr>
			<td>frontend.livenessProbe.httpGet.port</td>
			<td>string</td>
			<td><pre lang="json">
"{{ .Values.frontend.service.http.targetPort }}"
</pre>
</td>
			<td>HTTP GET port for liveness probe. Evaluated as a template</td>
		</tr>
		<tr>
			<td>frontend.livenessProbe.initialDelaySeconds</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Delay before first check (normal start timing)</td>
		</tr>
		<tr>
			<td>frontend.livenessProbe.periodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
10
</pre>
</td>
			<td>Regular check interval during normal operation</td>
		</tr>
		<tr>
			<td>frontend.livenessProbe.timeoutSeconds</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>Short timeout to detect hung containers quickly</td>
		</tr>
		<tr>
			<td>frontend.livenessProbe.failureThreshold</td>
			<td>int</td>
			<td><pre lang="json">
10
</pre>
</td>
			<td>Consecutive failures before restarting the container</td>
		</tr>
		<tr>
			<td>frontend.livenessProbe.successThreshold</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Typically 1 (usually ignored)</td>
		</tr>
		<tr>
			<td>cron.image.registry</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Cron container image registry</td>
		</tr>
		<tr>
			<td>cron.image.repository</td>
			<td>string</td>
			<td><pre lang="json">
"private/nf-tower-enterprise/backend"
</pre>
</td>
			<td>Cron container image repository</td>
		</tr>
		<tr>
			<td>cron.image.tag</td>
			<td>string</td>
			<td><pre lang="">
"{{ .chart.AppVersion }}"
</pre>
</td>
			<td>Cron container image tag</td>
		</tr>
		<tr>
			<td>cron.image.digest</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Cron container image digest in the format <code>sha256:1234abcdef</code></td>
		</tr>
		<tr>
			<td>cron.image.pullPolicy</td>
			<td>string</td>
			<td><pre lang="json">
"IfNotPresent"
</pre>
</td>
			<td>imagePullPolicy for the cron container Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images</td>
		</tr>
		<tr>
			<td>cron.image.pullSecrets</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/  <pre><code> pullSecrets:<br>   - myRegistryKeySecretName </code></pre></td>
		</tr>
		<tr>
			<td>cron.micronautEnvironments</td>
			<td>list</td>
			<td><pre lang="json">
[
  "prod",
  "redis",
  "cron"
]
</pre>
</td>
			<td>List of Micronaut Environments to enable on the cron pod</td>
		</tr>
		<tr>
			<td>cron.service.type</td>
			<td>string</td>
			<td><pre lang="json">
"ClusterIP"
</pre>
</td>
			<td>Cron Service type. Note: ingresses using AWS ALB require the service to be NodePort</td>
		</tr>
		<tr>
			<td>cron.service.http.name</td>
			<td>string</td>
			<td><pre lang="json">
"http"
</pre>
</td>
			<td>Service name to use</td>
		</tr>
		<tr>
			<td>cron.service.http.port</td>
			<td>int</td>
			<td><pre lang="json">
8080
</pre>
</td>
			<td>Service port</td>
		</tr>
		<tr>
			<td>cron.service.http.targetPort</td>
			<td>int</td>
			<td><pre lang="json">
8082
</pre>
</td>
			<td>Port on the pod/container that the Service forwards traffic to (can be a number or named port, distinct from the Service's external port)</td>
		</tr>
		<tr>
			<td>cron.service.http.nodePort</td>
			<td>string</td>
			<td><pre lang="json">
null
</pre>
</td>
			<td>Service node port, only used when service.type is Nodeport or LoadBalancer Choose port between 30000-32767, unless the cluster was configured differently than default</td>
		</tr>
		<tr>
			<td>cron.service.extraServices</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Other services that should live in the Service object https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service  <pre><code> extraServices:<br> - name: myspecialservice<br>   port: 1234<br>   targetPort: 5678<br>   nodePort: null </code></pre></td>
		</tr>
		<tr>
			<td>cron.service.extraOptions</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Extra Service options to place under .spec (for example, clusterIP, loadBalancerIP, externalTrafficPolicy, externalIPs). Evaluated as a template</td>
		</tr>
		<tr>
			<td>cron.initContainers</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Additional init containers for the cron pod. Evaluated as a template</td>
		</tr>
		<tr>
			<td>cron.command</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Override default container command (useful when using custom images)</td>
		</tr>
		<tr>
			<td>cron.args</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Override default container args (useful when using custom images)</td>
		</tr>
		<tr>
			<td>cron.podLabels</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional labels for the cron pod. Evaluated as a template</td>
		</tr>
		<tr>
			<td>cron.podAnnotations</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional annotations for the cron pod. Evaluated as a template</td>
		</tr>
		<tr>
			<td>cron.extraOptionsSpec</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Extra options to place under .spec (for example, revisionHistoryLimit). Evaluated as a template Note that cron deployment needs to have a single replica with Recreate strategy  <pre><code> extraOptionsSpec:<br>   revisionHistoryLimit: 4 </code></pre></td>
		</tr>
		<tr>
			<td>cron.extraOptionsTemplateSpec</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Extra options to place under .spec.template.spec (for example, nodeSelector, affinity, restartPolicy) Evaluated as a template  <pre><code> extraOptionsTemplateSpec:<br>   nodeSelector:<br>     service: myspecialnodegroup </code></pre></td>
		</tr>
		<tr>
			<td>cron.extraEnvVars</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Extra environment variables to set on the cron pod  <pre><code> extraEnvVars:<br>   - name: "CUSTOM_ENV_VAR"<br>     value: "set-a-value-here" </code></pre></td>
		</tr>
		<tr>
			<td>cron.extraEnvVarsCMs</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>ConfigMap containing extra env vars</td>
		</tr>
		<tr>
			<td>cron.extraEnvVarsSecrets</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Secret containing extra env vars</td>
		</tr>
		<tr>
			<td>cron.extraVolumes</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Extra volumes to add to the deployment (evaluated as template). Requires setting <code>extraVolumeMounts</code></td>
		</tr>
		<tr>
			<td>cron.extraVolumeMounts</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Extra volume mounts to add to the container (evaluated as template). Normally used with <code>extraVolumes</code></td>
		</tr>
		<tr>
			<td>cron.podSecurityContext.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable pod Security Context</td>
		</tr>
		<tr>
			<td>cron.podSecurityContext.fsGroup</td>
			<td>int</td>
			<td><pre lang="json">
101
</pre>
</td>
			<td>GID that Kubernetes applies to mounted volumes and created files so processes in the pod can share group-owned access</td>
		</tr>
		<tr>
			<td>cron.containerSecurityContext.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable container Security Context</td>
		</tr>
		<tr>
			<td>cron.containerSecurityContext.runAsUser</td>
			<td>int</td>
			<td><pre lang="json">
101
</pre>
</td>
			<td>UID the container processes run as (overrides container image default)</td>
		</tr>
		<tr>
			<td>cron.containerSecurityContext.runAsNonRoot</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Require the container to run as a non-root UID (prevents starting if UID 0)</td>
		</tr>
		<tr>
			<td>cron.containerSecurityContext.readOnlyRootFilesystem</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Mount the container root filesystem read-only to prevent in-place writes or tampering</td>
		</tr>
		<tr>
			<td>cron.containerSecurityContext.capabilities</td>
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
			<td>cron.resources</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Container requests and limits for different resources like CPU or memory <code>.requests</code> are the minimum CPU/memory resources the scheduler uses to place a pod; the kubelet then guarantees at least these resources to the pod. <code>.limits</code> are the maximum resources a container is allowed to use Ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ Seqera recommends configuring resources to match the expected workload. The following are sensible defaults to start with  <pre><code> resources:<br>   requests:<br>     cpu: "1"<br>     memory: "4000Mi"<br>   limits:<br>     memory: "4000Mi" </code></pre></td>
		</tr>
		<tr>
			<td>cron.startupProbe.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
false
</pre>
</td>
			<td>Enable startup probe</td>
		</tr>
		<tr>
			<td>cron.startupProbe.httpGet.path</td>
			<td>string</td>
			<td><pre lang="json">
"/health"
</pre>
</td>
			<td>HTTP GET path for startup probe</td>
		</tr>
		<tr>
			<td>cron.startupProbe.httpGet.port</td>
			<td>string</td>
			<td><pre lang="json">
"{{ .Values.cron.service.http.targetPort }}"
</pre>
</td>
			<td>HTTP GET port for startup probe. Evaluated as a template</td>
		</tr>
		<tr>
			<td>cron.startupProbe.initialDelaySeconds</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Longer initial wait to accommodate slow-starting apps</td>
		</tr>
		<tr>
			<td>cron.startupProbe.periodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
10
</pre>
</td>
			<td>Often set longer to avoid frequent checks while starting</td>
		</tr>
		<tr>
			<td>cron.startupProbe.timeoutSeconds</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>Can be longer to allow slow initialization responses</td>
		</tr>
		<tr>
			<td>cron.startupProbe.failureThreshold</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Consecutive failures during startup before killing the container (instead of immediate restarts)</td>
		</tr>
		<tr>
			<td>cron.startupProbe.successThreshold</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Number of consecutive successes required to consider startup complete and enable liveness/readiness</td>
		</tr>
		<tr>
			<td>cron.readinessProbe.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable readiness probe</td>
		</tr>
		<tr>
			<td>cron.readinessProbe.httpGet.path</td>
			<td>string</td>
			<td><pre lang="json">
"/health"
</pre>
</td>
			<td>HTTP GET path for readiness probe</td>
		</tr>
		<tr>
			<td>cron.readinessProbe.httpGet.port</td>
			<td>string</td>
			<td><pre lang="json">
"{{ .Values.cron.service.http.targetPort }}"
</pre>
</td>
			<td>HTTP GET port for readiness probe. Evaluated as a template</td>
		</tr>
		<tr>
			<td>cron.readinessProbe.initialDelaySeconds</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Delay before first check (normal start timing)</td>
		</tr>
		<tr>
			<td>cron.readinessProbe.periodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Regular check interval during normal operation</td>
		</tr>
		<tr>
			<td>cron.readinessProbe.timeoutSeconds</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>Short timeout to detect unresponsive containers for readiness</td>
		</tr>
		<tr>
			<td>cron.readinessProbe.failureThreshold</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Consecutive failures before marking the container Unready (no restart)</td>
		</tr>
		<tr>
			<td>cron.readinessProbe.successThreshold</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Number of consecutive successes required to mark the container Ready after failures</td>
		</tr>
		<tr>
			<td>cron.livenessProbe.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable liveness probe</td>
		</tr>
		<tr>
			<td>cron.livenessProbe.httpGet.path</td>
			<td>string</td>
			<td><pre lang="json">
"/health"
</pre>
</td>
			<td>HTTP GET path for liveness probe</td>
		</tr>
		<tr>
			<td>cron.livenessProbe.httpGet.port</td>
			<td>string</td>
			<td><pre lang="json">
"{{ .Values.cron.service.http.targetPort }}"
</pre>
</td>
			<td>HTTP GET port for liveness probe. Evaluated as a template</td>
		</tr>
		<tr>
			<td>cron.livenessProbe.initialDelaySeconds</td>
			<td>int</td>
			<td><pre lang="json">
5
</pre>
</td>
			<td>Delay before first check (normal start timing)</td>
		</tr>
		<tr>
			<td>cron.livenessProbe.periodSeconds</td>
			<td>int</td>
			<td><pre lang="json">
10
</pre>
</td>
			<td>Regular check interval during normal operation</td>
		</tr>
		<tr>
			<td>cron.livenessProbe.timeoutSeconds</td>
			<td>int</td>
			<td><pre lang="json">
3
</pre>
</td>
			<td>Short timeout to detect hung containers quickly</td>
		</tr>
		<tr>
			<td>cron.livenessProbe.failureThreshold</td>
			<td>int</td>
			<td><pre lang="json">
10
</pre>
</td>
			<td>Consecutive failures before restarting the container</td>
		</tr>
		<tr>
			<td>cron.livenessProbe.successThreshold</td>
			<td>int</td>
			<td><pre lang="json">
1
</pre>
</td>
			<td>Typically 1 (usually ignored)</td>
		</tr>
		<tr>
			<td>cron.dbMigrationInitContainer.image.registry</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Database migration container image registry</td>
		</tr>
		<tr>
			<td>cron.dbMigrationInitContainer.image.repository</td>
			<td>string</td>
			<td><pre lang="json">
"private/nf-tower-enterprise/migrate-db"
</pre>
</td>
			<td>Database migration container image repository</td>
		</tr>
		<tr>
			<td>cron.dbMigrationInitContainer.image.tag</td>
			<td>string</td>
			<td><pre lang="">
"{{ .chart.AppVersion }}"
</pre>
</td>
			<td>Specify a tag to override the version defined in .Chart.appVersion</td>
		</tr>
		<tr>
			<td>cron.dbMigrationInitContainer.image.digest</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Database migration container image digest in the format <code>sha256:1234abcdef</code></td>
		</tr>
		<tr>
			<td>cron.dbMigrationInitContainer.image.pullPolicy</td>
			<td>string</td>
			<td><pre lang="json">
"IfNotPresent"
</pre>
</td>
			<td>imagePullPolicy for the database migration init container Ref: https://kubernetes.io/docs/concepts/containers/images/#pre-pulled-images</td>
		</tr>
		<tr>
			<td>cron.dbMigrationInitContainer.image.pullSecrets</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>List of imagePullSecrets Secrets must be created in the same namespace, for example using the .extraDeploy array Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/  <pre><code> pullSecrets:<br>   - myRegistryKeySecretName </code></pre></td>
		</tr>
		<tr>
			<td>cron.dbMigrationInitContainer.command</td>
			<td>list</td>
			<td><pre lang="json">
[
  "/bin/sh",
  "-c",
  "/migrate-db.sh"
]
</pre>
</td>
			<td>Override default container command (useful when using custom images)</td>
		</tr>
		<tr>
			<td>cron.dbMigrationInitContainer.args</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Override default container args (useful when using custom images)</td>
		</tr>
		<tr>
			<td>cron.dbMigrationInitContainer.extraEnvVars</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Extra environment variables to set on the cron pod  <pre><code> extraEnvVars:<br>   - name: "CUSTOM_ENV_VAR"<br>     value: "set-a-value-here" </code></pre></td>
		</tr>
		<tr>
			<td>cron.dbMigrationInitContainer.extraEnvVarsCMs</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>ConfigMap containing extra env vars</td>
		</tr>
		<tr>
			<td>cron.dbMigrationInitContainer.extraEnvVarsSecrets</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Secret containing extra env vars</td>
		</tr>
		<tr>
			<td>cron.dbMigrationInitContainer.extraVolumes</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Extra volumes to add to the deployment (evaluated as template). Requires setting <code>extraVolumeMounts</code></td>
		</tr>
		<tr>
			<td>cron.dbMigrationInitContainer.extraVolumeMounts</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Extra volume mounts to add to the container (evaluated as template). Normally used with <code>extraVolumes</code></td>
		</tr>
		<tr>
			<td>cron.dbMigrationInitContainer.containerSecurityContext.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable container Security Context</td>
		</tr>
		<tr>
			<td>cron.dbMigrationInitContainer.containerSecurityContext.runAsUser</td>
			<td>int</td>
			<td><pre lang="json">
101
</pre>
</td>
			<td>UID the container processes run as (overrides container image default)</td>
		</tr>
		<tr>
			<td>cron.dbMigrationInitContainer.containerSecurityContext.runAsNonRoot</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Require the container to run as a non-root UID (prevents starting if UID 0)</td>
		</tr>
		<tr>
			<td>cron.dbMigrationInitContainer.containerSecurityContext.readOnlyRootFilesystem</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Mount the container root filesystem read-only to prevent in-place writes or tampering</td>
		</tr>
		<tr>
			<td>cron.dbMigrationInitContainer.containerSecurityContext.capabilities</td>
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
			<td>cron.dbMigrationInitContainer.resources</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Container requests and limits for different resources like CPU or memory <code>.requests</code> are the minimum CPU/memory resources the scheduler uses to place a pod; the kubelet then guarantees at least these resources to the pod. <code>.limits</code> are the maximum resources a container is allowed to use Ref: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ Seqera recommends configuring resources to match the expected workload. The following are sensible defaults to start with  <pre><code> resources:<br>   requests:<br>     cpu: "1"<br>     memory: "4000Mi"<br>   limits:<br>     memory: "4000Mi" </code></pre></td>
		</tr>
		<tr>
			<td>initContainerDependencies.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable init containers that coordinate startup dependencies between Platform components (for example, wait for database readiness before cron starts, wait for cron before backend starts, etc)</td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForMySQL.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable wait for MySQL init container before starting backend and cron</td>
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
			<td>initContainerDependencies.waitForRedis.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable wait for Redis init container before starting backend and cron</td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForRedis.image.registry</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Override default wait for Redis init container image</td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForRedis.image.repository</td>
			<td>string</td>
			<td><pre lang="json">
"redis"
</pre>
</td>
			<td></td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForRedis.image.tag</td>
			<td>string</td>
			<td><pre lang="json">
"7"
</pre>
</td>
			<td></td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForRedis.image.digest</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td></td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForRedis.image.pullPolicy</td>
			<td>string</td>
			<td><pre lang="json">
"IfNotPresent"
</pre>
</td>
			<td></td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForRedis.securityContext.runAsUser</td>
			<td>int</td>
			<td><pre lang="json">
101
</pre>
</td>
			<td>UID the container processes run as (overrides container image default)</td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForRedis.securityContext.runAsNonRoot</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Require the container to run as a non-root UID (prevents starting if UID 0)</td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForRedis.securityContext.readOnlyRootFilesystem</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Mount the container root filesystem read-only to prevent in-place writes or tampering</td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForRedis.securityContext.capabilities</td>
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
			<td>initContainerDependencies.waitForRedis.resources</td>
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
			<td>initContainerDependencies.waitForCron.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Enable wait for Platform cron init container before starting backend</td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForCron.image.registry</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Override default wait for cron init container image</td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForCron.image.repository</td>
			<td>string</td>
			<td><pre lang="json">
"curlimages/curl"
</pre>
</td>
			<td></td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForCron.image.tag</td>
			<td>string</td>
			<td><pre lang="json">
"latest"
</pre>
</td>
			<td></td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForCron.image.digest</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td></td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForCron.image.pullPolicy</td>
			<td>string</td>
			<td><pre lang="json">
"IfNotPresent"
</pre>
</td>
			<td></td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForCron.securityContext.runAsUser</td>
			<td>int</td>
			<td><pre lang="json">
101
</pre>
</td>
			<td>UID the container processes run as (overrides container image default)</td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForCron.securityContext.runAsNonRoot</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Require the container to run as a non-root UID (prevents starting if UID 0)</td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForCron.securityContext.readOnlyRootFilesystem</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td>Mount the container root filesystem read-only to prevent in-place writes or tampering</td>
		</tr>
		<tr>
			<td>initContainerDependencies.waitForCron.securityContext.capabilities</td>
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
			<td>initContainerDependencies.waitForCron.resources</td>
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
		<tr>
			<td>ingress.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
false
</pre>
</td>
			<td>Enable ingress for Platform</td>
		</tr>
		<tr>
			<td>ingress.path</td>
			<td>string</td>
			<td><pre lang="json">
"/"
</pre>
</td>
			<td>Path for the main ingress rule Note: this needs to be set to '/*' to be used with AWS ALB ingress controller</td>
		</tr>
		<tr>
			<td>ingress.contentPath</td>
			<td>string</td>
			<td><pre lang="json">
"/"
</pre>
</td>
			<td>Path for the content domain ingress rule Note: this needs to be set to '/*' to be used with AWS ALB ingress controller</td>
		</tr>
		<tr>
			<td>ingress.defaultPathType</td>
			<td>string</td>
			<td><pre lang="json">
"ImplementationSpecific"
</pre>
</td>
			<td>Default path type for the Ingress</td>
		</tr>
		<tr>
			<td>ingress.defaultBackend</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Configure the default service for the ingress (evaluated as template) Important: make sure only one defaultBackend is defined across the k8s cluster: if the ingress doesn't reconcile successfully, 'describe ingress <name>' will report problems  <pre><code> defaultBackend:<br>   service:<br>     name: '{{ printf "%s-frontend" (include "common.names.fullname" .) }}'<br>     port:<br>       number: '{{ .Values.frontend.service.http.port }}' </code></pre></td>
		</tr>
		<tr>
			<td>ingress.extraHosts</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>Additional hosts you want to include. Evaluated as a template  <pre><code> extraHosts:<br>   - host: '{{ printf "api.%s" .Values.global.platformExternalDomain }}'<br>     paths:<br>       - path: /*<br>         pathType: Prefix  # Optional, defaults to defaultPathType<br>         serviceName: '{{ printf "%s-backend" (include "common.names.fullname" .) }}'<br>         portNumber: '{{ .Values.global.platformServicePort }}'<br>   - host: '{{ printf "www.%s" .Values.global.platformExternalDomain }}'<br>     paths:<br>       - path: /*<br>         pathType: Prefix  # Optional, defaults to defaultPathType<br>         serviceName: '{{ printf "%s-frontend" (include "common.names.fullname" .) }}'<br>         portNumber: '{{ .Values.frontend.service.http.port }}' </code></pre></td>
		</tr>
		<tr>
			<td>ingress.annotations</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Ingress annotations specific to your load balancer. Evaluated as a template</td>
		</tr>
		<tr>
			<td>ingress.extraLabels</td>
			<td>object</td>
			<td><pre lang="json">
{}
</pre>
</td>
			<td>Additional labels for the ingress object. Evaluated as a template</td>
		</tr>
		<tr>
			<td>ingress.ingressClassName</td>
			<td>string</td>
			<td><pre lang="json">
""
</pre>
</td>
			<td>Name of the ingress class (replaces deprecated annotation 'kubernetes.io/ingress.class')</td>
		</tr>
		<tr>
			<td>ingress.tls</td>
			<td>list</td>
			<td><pre lang="json">
[]
</pre>
</td>
			<td>TLS configuration. Evaluated as a template  <pre><code> tls:<br>   - hosts:<br>       - '{{ .Values.global.platformExternalDomain }}'<br>       - '{{ printf "user-data.%s" .Values.global.platformExternalDomain }}'<br>     secretName: my-tls </code></pre></td>
		</tr>
		<tr>
			<td>pipeline-optimization.enabled</td>
			<td>bool</td>
			<td><pre lang="json">
true
</pre>
</td>
			<td></td>
		</tr>
	</tbody>
</table>

## Licensing

Seqera® and Nextflow® are registered trademarks of Seqera Labs.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
