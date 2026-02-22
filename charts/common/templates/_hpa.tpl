{{- define "common.hpa" -}}
{{- $autoscaling := default dict .Values.autoscaling }}
{{- $workloadKind := include "common.workloadKind" . }}
{{- if $autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: {{ $workloadKind }}
    name: {{ include "common.fullname" . }}
  minReplicas: {{ $autoscaling.minReplicas }}
  maxReplicas: {{ $autoscaling.maxReplicas }}
  metrics:
    {{- if $autoscaling.targetCPUUtilizationPercentage }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ $autoscaling.targetCPUUtilizationPercentage }}
    {{- end }}
    {{- if $autoscaling.targetMemoryUtilizationPercentage }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ $autoscaling.targetMemoryUtilizationPercentage }}
    {{- end }}
{{- end }}
{{- end }}
