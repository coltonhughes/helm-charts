{{- define "common.service" -}}
{{- $service := default dict .Values.service -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with $service.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  type: {{ $service.type | default "ClusterIP" }}
  {{- if $service.loadBalancerIP }}
  loadBalancerIP: {{ $service.loadBalancerIP }}
  {{- end }}
  ports:
    {{ if $service.ports }}
    {{ tpl (toYaml $service.ports) $ | nindent 4 }}
    {{ else }}
    - port: {{ $service.port | default 80 }}
      targetPort: {{ $service.targetPort | default "http" }}
      protocol: {{ $service.protocol | default "TCP" }}
      name: http
    {{ end }}
  selector:
    {{- include "common.selectorLabels" . | nindent 4 }}
{{- end }}
