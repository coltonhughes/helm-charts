{{- define "common.pvc" -}}
{{- $persistence := default dict .Values.persistence -}}
{{- if and $persistence.enabled (not $persistence.existingClaim) }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "common.pvcResourceName" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  accessModes:
    - {{ $persistence.accessMode | quote }}
  {{- if $persistence.storageClass }}
  storageClassName: {{ $persistence.storageClass | quote }}
  {{- end }}
  resources:
    requests:
      storage: {{ $persistence.size | quote }}
{{- end }}
{{- end }}
