{{- define "common.gatewayapi" -}}
{{- $httpRoute := default dict .Values.httpRoute -}}
{{- if ($httpRoute.enabled | default false) -}}
{{- $fullName := include "common.fullname" . -}}
{{- $svcPort := (default dict .Values.service).port | default 80 -}}
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ $fullName }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
    {{- with $httpRoute.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $httpRoute.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  parentRefs:
    {{- required "A valid .Values.httpRoute.parentRefs entry is required when httpRoute.enabled is true" $httpRoute.parentRefs | toYaml | nindent 4 }}
  {{- with $httpRoute.hostnames }}
  hostnames:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  rules:
    {{- if $httpRoute.rules }}
    {{- toYaml $httpRoute.rules | nindent 4 }}
    {{- else }}
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: {{ $fullName }}
          port: {{ $svcPort }}
    {{- end }}
{{- end }}
{{- end }}
