{{- define "common.gatewayapi" -}}
{{- $gatewayAPI := default dict .Values.gatewayAPI -}}
{{- if $gatewayAPI.enabled -}}
  {{- range $route := $gatewayAPI.httpRoutes }}
---
{{- tpl (toYaml $route) $ | nindent 0 }}
  {{- end }}
  {{- range $route := $gatewayAPI.tcpRoutes }}
---
{{- tpl (toYaml $route) $ | nindent 0 }}
  {{- end }}
  {{- range $route := $gatewayAPI.tlsRoutes }}
---
{{- tpl (toYaml $route) $ | nindent 0 }}
  {{- end }}
  {{- range $route := $gatewayAPI.udpRoutes }}
---
{{- tpl (toYaml $route) $ | nindent 0 }}
  {{- end }}
{{- end }}
{{- end }}
