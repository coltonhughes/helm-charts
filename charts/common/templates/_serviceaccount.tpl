{{- define "common.serviceAccount" -}}
{{- $serviceAccount := default dict .Values.serviceAccount -}}
{{- if ($serviceAccount.create | default false) -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "common.serviceAccountName" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with $serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
automountServiceAccountToken: {{ $serviceAccount.automount | default true }}
{{- end }}
{{- end }}
