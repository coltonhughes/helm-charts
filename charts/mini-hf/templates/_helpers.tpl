{{- define "mini-hf.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (default .Chart.Name .Values.nameOverride) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "mini-hf.componentContext" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $name := printf "%s-%s" (include "mini-hf.fullname" $root) $component | trunc 63 | trimSuffix "-" -}}
{{- $values := deepCopy $root.Values -}}
{{- $_ := set $values "nameOverride" $name -}}
{{- $_ := set $values "fullnameOverride" $name -}}
{{- $_ := set $values "ingress" (dict "enabled" false) -}}
{{- $_ := set $values "httpRoute" (default dict .route) -}}
{{- $_ := set $values "serviceAccount" (dict "create" false "name" (include "common.serviceAccountName" $root)) -}}
{{- $_ := set $values "image" .image -}}
{{- $_ := set $values "container" .container -}}
{{- $_ := set $values "initContainers" (default list .initContainers) -}}
{{- $_ := set $values "service" .service -}}
{{- $_ := set $values "replicaCount" .replicas -}}
{{- $_ := set $values "resources" .resources -}}
{{- $_ := set $values "podAnnotations" (default dict .podAnnotations) -}}
{{- $_ := set $values "readinessProbe" .readinessProbe -}}
{{- $_ := set $values "livenessProbe" .livenessProbe -}}
{{- $_ := set $values "volumes" (default list .volumes) -}}
{{- $_ := set $values "volumeMounts" (default list .volumeMounts) -}}
{{- $ctx := dict "Values" $values "Chart" $root.Chart "Release" $root.Release "Files" $root.Files "Capabilities" $root.Capabilities "Template" $root.Template -}}
{{- toYaml $ctx -}}
{{- end -}}

{{- define "mini-hf.secretName" -}}
{{- printf "%s-secrets" (include "mini-hf.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mini-hf.databaseSecretName" -}}
{{- $clusterName := default (printf "%s-cnpg" (include "mini-hf.fullname" .)) .Values.database.cnpg.name -}}
{{- printf "%s-cnpg-credentials" $clusterName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mini-hf.databaseClusterName" -}}
{{- default (printf "%s-cnpg" (include "mini-hf.fullname" .)) .Values.database.cnpg.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mini-hf.valkeyName" -}}
{{- default (include "mini-hf.fullname" .) .Values.valkey.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mini-hf.databaseHost" -}}
{{- $namespace := default .Release.Namespace .Values.database.cnpg.namespace -}}
{{- printf "%s-rw.%s.svc.%s" (include "mini-hf.databaseClusterName" .) $namespace .Values.database.cnpg.clusterDomain -}}
{{- end -}}

{{- define "mini-hf.valkeyHost" -}}
{{- if .Values.redis.url -}}
{{- .Values.redis.url -}}
{{- else -}}
{{- $namespace := default .Release.Namespace .Values.valkey.namespace -}}
{{- $service := default (printf "valkey-%s" (include "mini-hf.valkeyName" .)) .Values.valkey.serviceHost -}}
{{- printf "%s.%s.svc.%s:6379" $service $namespace .Values.valkey.clusterDomain -}}
{{- end -}}
{{- end -}}
