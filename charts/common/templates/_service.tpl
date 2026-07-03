{{- define "common.service" -}}
{{- $service := default dict .Values.service -}}
{{- $ports := $service.ports -}}
{{- $portsTemplate := $service.portsTemplate | default "" -}}
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
  {{- with $service.ipFamilyPolicy }}
  ipFamilyPolicy: {{ . }}
  {{- end }}
  {{- with $service.ipFamilies }}
  ipFamilies:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  ports:
    {{- if or $ports $portsTemplate }}
    {{- with $ports }}
    {{ tpl (toYaml .) $ | nindent 4 }}
    {{- end }}
    {{- with $portsTemplate }}
    {{ tpl . $ | nindent 4 }}
    {{- end }}
    {{- else }}
    - port: {{ $service.port | default 80 }}
      targetPort: {{ $service.targetPort | default "http" }}
      protocol: {{ $service.protocol | default "TCP" }}
      name: http
    {{- end }}
  selector:
    {{- include "common.selectorLabels" . | nindent 4 }}
{{- end }}
