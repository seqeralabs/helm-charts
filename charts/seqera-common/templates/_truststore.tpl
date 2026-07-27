{{/*
 Copyright (c) 2026 Seqera Labs
 All rights reserved.

 SPDX-License-Identifier: Apache-2.0

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/}}

{{/*
Helpers for distributing a private/internal CA to Seqera workloads.

Deployments behind an enterprise PKI, or behind a firewall performing HTTPS
interception, present certificates signed by a CA that is in no public trust
store. Two mechanisms are needed and they are not interchangeable:

  * JVM services consult only their own trust store. A PEM on disk does
    nothing for them, so `seqera.trustStore.initContainer` builds a Java trust
    store from the JRE's own bundle plus the supplied CA, and
    `seqera.trustStore.envVars` points the JVM at it.
  * OpenSSL, Go, and Python services read a PEM. The init container builds a
    bundle from the image's system roots plus the supplied CA, and
    `seqera.trustStore.envVars` points those runtimes at the combined bundle.
  * Node.js reads the supplied CA through `NODE_EXTRA_CA_CERTS`, which adds it
    to Node's bundled roots without replacing public trust.

The trust store is always seeded from the JRE's existing bundle rather than
replacing it, so public trust is preserved. Replacing it breaks every
legitimately public endpoint, and does so in a way that presents as an
unrelated network fault.

Values live under `.Values.global.trustStore` so a single declaration reaches
the parent chart and every subchart.
*/}}

{{/*
Whether the trust store is enabled and has a usable source.

Usage:
include "seqera.trustStore.enabled" $
*/}}
{{- define "seqera.trustStore.enabled" -}}
  {{- $ts := (.Values.global).trustStore | default dict -}}
  {{- if and $ts.enabled (or $ts.certificate $ts.existingConfigMap $ts.existingSecret) -}}
true
  {{- end -}}
{{- end -}}

{{/*
Name of the ConfigMap holding the CA bundle when the chart creates it from an
inline certificate.

Usage:
include "seqera.trustStore.configMapName" $
*/}}
{{- define "seqera.trustStore.configMapName" -}}
  {{- $ts := (.Values.global).trustStore | default dict -}}
  {{- if $ts.existingConfigMap -}}
{{- tpl $ts.existingConfigMap . -}}
  {{- else -}}
    {{- printf "%s-trust-store-ca" (include "common.names.fullname" .) -}}
  {{- end -}}
{{- end -}}

{{/*
Key within the ConfigMap or Secret that holds the PEM bundle.

Usage:
include "seqera.trustStore.key" $
*/}}
{{- define "seqera.trustStore.key" -}}
  {{- $ts := (.Values.global).trustStore | default dict -}}
{{- $ts.key | default "ca.crt" -}}
{{- end -}}

{{/*
Absolute path of the mounted PEM bundle. Non-JVM runtimes and any tooling that
reads a PEM directly (for example the mysql client, or a database driver's
`sslCa` option) use this path.

Usage:
include "seqera.trustStore.caPath" $
*/}}
{{- define "seqera.trustStore.caPath" -}}
  {{- $ts := (.Values.global).trustStore | default dict -}}
  {{- printf "%s/%s" ($ts.mountPath | default "/opt/seqera/trust") (include "seqera.trustStore.key" .) -}}
{{- end -}}

{{/*
Absolute path of the generated Java trust store.

Usage:
include "seqera.trustStore.javaPath" $
*/}}
{{- define "seqera.trustStore.javaPath" -}}
  {{- $ts := (.Values.global).trustStore | default dict -}}
  {{- printf "%s/cacerts" ($ts.javaMountPath | default "/opt/seqera/truststore") -}}
{{- end -}}

{{/*
Absolute path of the combined system and private PEM bundle.

Usage:
include "seqera.trustStore.pemPath" $
*/}}
{{- define "seqera.trustStore.pemPath" -}}
  {{- $ts := (.Values.global).trustStore | default dict -}}
  {{- printf "%s/ca-bundle.crt" ($ts.javaMountPath | default "/opt/seqera/truststore") -}}
{{- end -}}

{{/*
Volumes carrying the CA bundle, plus the writable volume a generated Java
trust store or combined PEM bundle is written into.

The generated store needs an emptyDir because Seqera containers run with
`readOnlyRootFilesystem: true`, which rules out patching the image's own
cacerts in place.

Usage:
include "seqera.trustStore.volumes" (dict "context" $ "java" true)
*/}}
{{- define "seqera.trustStore.volumes" -}}
  {{- $ctx := .context -}}
  {{- if include "seqera.trustStore.enabled" $ctx -}}
    {{- $ts := ($ctx.Values.global).trustStore | default dict -}}
- name: seqera-trust-ca
    {{- if $ts.existingSecret }}
  secret:
    secretName: {{ tpl $ts.existingSecret $ctx }}
    {{- else }}
  configMap:
    name: {{ include "seqera.trustStore.configMapName" $ctx }}
    {{- end }}
    {{- if or .java .pem }}
- name: seqera-trust-store
  emptyDir: {}
    {{- end }}
  {{- end -}}
{{- end -}}

{{/*
Volume mounts for the CA bundle and, when needed, generated trust assets.

Usage:
include "seqera.trustStore.volumeMounts" (dict "context" $ "java" true)
*/}}
{{- define "seqera.trustStore.volumeMounts" -}}
  {{- $ctx := .context -}}
  {{- if include "seqera.trustStore.enabled" $ctx -}}
    {{- $ts := ($ctx.Values.global).trustStore | default dict -}}
- name: seqera-trust-ca
  mountPath: {{ $ts.mountPath | default "/opt/seqera/trust" }}
  readOnly: true
    {{- if or .java .pem }}
- name: seqera-trust-store
  mountPath: {{ $ts.javaMountPath | default "/opt/seqera/truststore" }}
  readOnly: true
    {{- end }}
  {{- end -}}
{{- end -}}

{{/*
Init container that builds either a Java trust store or a combined PEM bundle.

For JVM services it copies the JRE's own cacerts and imports every certificate
from the supplied PEM. For other PEM-consuming runtimes it finds the image's
system CA bundle and appends the supplied CA. Both preserve public trust.

By default it runs the *component's own image*, supplied by the call site as
`imageRoot`. This matters: a trust store seeded from a different JDK carries
that vendor's set of public roots, so using a stock JRE would silently swap the
component's public trust for another distribution's. Seqera components do not
all ship the same base image. Running the component's own image also keeps the
generated store's format matched to the JVM that reads it.

`.global.trustStore.java.image.repository` overrides this, which is needed when
a component image does not ship `keytool`. Match the overriding image's vendor
and major version to the component to avoid the substitution described above.

Usage:
include "seqera.trustStore.initContainer" (dict "context" $ "imageRoot" .Values.backend.image "java" true)
*/}}
{{- define "seqera.trustStore.initContainer" -}}
  {{- $ctx := .context -}}
  {{- $javaMode := true -}}
  {{- if hasKey . "java" -}}
{{- $javaMode = .java -}}
  {{- end -}}
  {{- if include "seqera.trustStore.enabled" $ctx -}}
    {{- $ts := ($ctx.Values.global).trustStore | default dict -}}
    {{- $java := $ts.java | default dict -}}
    {{- $storePath := include "seqera.trustStore.javaPath" $ctx -}}
    {{/*
    Defaults are applied here rather than relying on values alone, so a subchart
    installed standalone (with no parent `global` block) still renders.
    */}}
    {{- $override := $java.image | default dict -}}
    {{- $image := dict -}}
    {{- if and $javaMode $override.repository -}}
{{- $image = mergeOverwrite (dict "registry" "" "digest" "" "pullPolicy" "IfNotPresent") $override -}}
    {{- else -}}
{{- $image = mergeOverwrite (dict "pullPolicy" "IfNotPresent") (deepCopy (.imageRoot | default dict)) -}}
    {{- end -}}
    {{- $securityContext := $java.securityContext | default (dict "runAsUser" 101 "runAsNonRoot" true "readOnlyRootFilesystem" true "capabilities" (dict "drop" (list "ALL"))) -}}
    {{- $resources := $java.resources | default (dict "requests" (dict "cpu" "0.25" "memory" "128Mi") "limits" (dict "memory" "256Mi")) -}}
    {{- if $javaMode }}
- name: build-trust-store
  image: {{ include "common.images.image" (dict "imageRoot" $image "global" $ctx.Values.global "chart" $ctx.Chart) }}
  imagePullPolicy: {{ $image.pullPolicy }}
  command:
    - 'sh'
    - '-c'
    - |
      set -eu
      # Seed from the JRE's own bundle so public trust anchors survive.
      cp "${JAVA_HOME}/lib/security/cacerts" "$STORE_PATH"
      CERT_DIR="${STORE_PATH%/*}"
      # A PEM bundle may contain multiple roots/intermediates. Split it so
      # keytool imports each certificate under a distinct alias.
      awk -v cert_dir="$CERT_DIR" '
        /-----BEGIN CERTIFICATE-----/ { cert += 1 }
        cert > 0 { print > (cert_dir "/seqera-ca-" cert ".pem") }
      ' "$CA_PATH"
      test -f "$CERT_DIR/seqera-ca-1.pem"
      for cert in "$CERT_DIR"/seqera-ca-*.pem; do
        number="${cert##*-}"
        number="${number%.pem}"
        keytool -importcert -noprompt -trustcacerts \
          -alias "seqera-trust-store-ca-${number}" \
          -file "$cert" \
          -keystore "$STORE_PATH" \
          -storepass "$STORE_PASSWORD"
      done
      echo "imported $CA_PATH into $STORE_PATH"
  env:
    - name: CA_PATH
      value: {{ include "seqera.trustStore.caPath" $ctx | quote }}
    - name: STORE_PATH
      value: {{ $storePath | quote }}
    - name: STORE_PASSWORD
      value: {{ $java.password | default "changeit" | quote }}
  volumeMounts:
    - name: seqera-trust-ca
      mountPath: {{ $ts.mountPath | default "/opt/seqera/trust" }}
      readOnly: true
    - name: seqera-trust-store
      mountPath: {{ $ts.javaMountPath | default "/opt/seqera/truststore" }}
  securityContext: {{- include "seqera.tplvalues.render" (dict "value" $securityContext) | nindent 4 }}
  resources: {{- include "seqera.tplvalues.render" (dict "value" $resources) | nindent 4 }}
    {{- else if .pem }}
- name: build-ca-bundle
  image: {{ include "common.images.image" (dict "imageRoot" $image "global" $ctx.Values.global "chart" $ctx.Chart) }}
  imagePullPolicy: {{ $image.pullPolicy }}
  command:
    - 'sh'
    - '-c'
    - |
      set -eu
      SYSTEM_CA_FILE=""
      for candidate in \
        /etc/ssl/certs/ca-certificates.crt \
        /etc/pki/tls/certs/ca-bundle.crt \
        /etc/ssl/ca-bundle.pem \
        /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
      do
        if [ -f "$candidate" ]; then
          SYSTEM_CA_FILE="$candidate"
          break
        fi
      done
      if [ -z "$SYSTEM_CA_FILE" ]; then
        echo "could not find the image's system CA bundle" >&2
        exit 1
      fi
      cat "$SYSTEM_CA_FILE" "$CA_PATH" > "$BUNDLE_PATH"
      echo "appended $CA_PATH to $SYSTEM_CA_FILE"
  env:
    - name: CA_PATH
      value: {{ include "seqera.trustStore.caPath" $ctx | quote }}
    - name: BUNDLE_PATH
      value: {{ include "seqera.trustStore.pemPath" $ctx | quote }}
  volumeMounts:
    - name: seqera-trust-ca
      mountPath: {{ $ts.mountPath | default "/opt/seqera/trust" }}
      readOnly: true
    - name: seqera-trust-store
      mountPath: {{ $ts.javaMountPath | default "/opt/seqera/truststore" }}
  securityContext: {{- include "seqera.tplvalues.render" (dict "value" $securityContext) | nindent 4 }}
  resources: {{- include "seqera.tplvalues.render" (dict "value" $resources) | nindent 4 }}
    {{- end }}
  {{- end -}}
{{- end -}}

{{/*
Environment variables pointing a runtime at the CA.

`java: true` sets JAVA_TOOL_OPTIONS for the generated trust store. `node: true`
sets NODE_EXTRA_CA_CERTS, which augments Node's bundled roots. Otherwise the
conventional PEM variables point at the generated system-plus-private bundle:
SSL_CERT_FILE (OpenSSL and Go), REQUESTS_CA_BUNDLE (Python requests), and
CURL_CA_BUNDLE (curl).

Usage:
include "seqera.trustStore.envVars" (dict "context" $ "java" true)
*/}}
{{- define "seqera.trustStore.envVars" -}}
  {{- $ctx := .context -}}
  {{- if include "seqera.trustStore.enabled" $ctx -}}
    {{- $ts := ($ctx.Values.global).trustStore | default dict -}}
    {{- if .java -}}
      {{- $java := $ts.java | default dict }}
- name: JAVA_TOOL_OPTIONS
  value: {{ printf "-Djavax.net.ssl.trustStore=%s -Djavax.net.ssl.trustStorePassword=%s" (include "seqera.trustStore.javaPath" $ctx) ($java.password | default "changeit") | quote }}
    {{- else if .node }}
- name: NODE_EXTRA_CA_CERTS
  value: {{ include "seqera.trustStore.caPath" $ctx | quote }}
    {{- else }}
- name: SSL_CERT_FILE
  value: {{ include "seqera.trustStore.pemPath" $ctx | quote }}
- name: REQUESTS_CA_BUNDLE
  value: {{ include "seqera.trustStore.pemPath" $ctx | quote }}
- name: CURL_CA_BUNDLE
  value: {{ include "seqera.trustStore.pemPath" $ctx | quote }}
    {{- end }}
  {{- end -}}
{{- end -}}
