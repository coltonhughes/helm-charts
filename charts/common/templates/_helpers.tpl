{{/*
Common chart helpers.
*/}}
{{- define "common.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "common.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "common.labels" -}}
helm.sh/chart: {{ include "common.chart" . }}
{{ include "common.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "common.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "common.serviceAccountName" -}}
{{- $serviceAccount := .Values.serviceAccount | default dict -}}
{{- if $serviceAccount.create | default false }}
{{- default (include "common.fullname" .) $serviceAccount.name }}
{{- else }}
{{- default "default" $serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "common.pvcClaimName" -}}
{{- $existingClaim := coalesce .Values.persistence.existingClaim .Values.persistence.exisitingClaim "" -}}
{{- if $existingClaim -}}
{{- $existingClaim -}}
{{- else -}}
{{- include "common.fullname" . -}}
{{- end -}}
{{- end }}

{{- define "common.env" -}}
{{- $env := .Values.container.env -}}
{{- if kindIs "map" $env }}
{{- range $key, $val := $env }}
- name: {{ $key | upper | replace "." "_" }}
  value: {{ $val | quote }}
{{- end }}
{{- else if kindIs "slice" $env }}
{{- toYaml $env }}
{{- end }}
{{- with .Values.container.extraEnv }}
{{- if kindIs "string" . }}
{{- tpl . $ }}
{{- else }}
{{- toYaml . }}
{{- end }}
{{- end }}
{{- end }}
