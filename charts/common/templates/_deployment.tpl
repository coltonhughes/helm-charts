{{- define "common.deployment" -}}
{{- $autoscaling := default dict .Values.autoscaling -}}
{{- $service := default dict .Values.service -}}
{{- $persistence := default dict .Values.persistence -}}
{{- $container := default dict .Values.container -}}
{{- $gpu := default dict .Values.gpu -}}
{{- $podSecurityContext := default dict .Values.podSecurityContext -}}
{{- $securityContext := default dict .Values.securityContext -}}
{{- $resources := default dict .Values.resources -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  {{- if not ($autoscaling.enabled | default false) }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  {{- with .Values.deploymentStrategy }}
  strategy:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "common.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- tpl (toYaml .) $ | nindent 8 }}
      {{- end }}
      labels:
        {{- include "common.labels" . | nindent 8 }}
        {{- with .Values.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
    spec:
      {{- if $gpu.enabled }}
      {{- $runtimeClassName := $gpu.runtimeClassName | default "" }}
      {{- if and (eq $runtimeClassName "") (eq $gpu.type "nvidia") }}
      {{- $runtimeClassName = "nvidia" }}
      {{- end }}
      {{- if $runtimeClassName }}
      runtimeClassName: {{ $runtimeClassName }}
      {{- end }}
      {{- end }}
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "common.serviceAccountName" . }}
      securityContext:
        {{- toYaml $podSecurityContext | nindent 8 }}
      {{- $initContainers := .Values.initContainers }}
      {{- $initContainersTemplate := .Values.initContainersTemplate }}
      {{- if or $initContainers $initContainersTemplate }}
      initContainers:
        {{- if $initContainers }}
        {{- tpl (toYaml $initContainers) $ | nindent 8 }}
        {{- end }}
        {{- if $initContainersTemplate }}
        {{- tpl $initContainersTemplate $ | nindent 8 }}
        {{- end }}
      {{- end }}
      containers:
        - name: {{ .Chart.Name }}
          securityContext:
            {{- toYaml $securityContext | nindent 12 }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          {{- with $container.command }}
          command:
            {{- tpl (toYaml .) $ | nindent 12 }}
          {{- end }}
          {{- with $container.args }}
          args:
            {{- tpl (toYaml .) $ | nindent 12 }}
          {{- end }}
          {{- with $container.env }}
          env:
            {{- range $key, $value := . }}
            - name: {{ $key }}
              value: {{ $value | quote }}
            {{- end }}
          {{- end }}
          ports:
            {{ if .Values.containerPorts }}
            {{ tpl (toYaml .Values.containerPorts) $ | nindent 12 }}
            {{ else }}
            - name: http
              containerPort: {{ $service.port | default 80 }}
              protocol: TCP
            {{ end }}
          {{- with .Values.livenessProbe }}
          livenessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.readinessProbe }}
          readinessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- if $gpu.enabled }}
          resources:
            {{ if $gpu.resources }}
            {{ toYaml $gpu.resources | nindent 12 }}
            {{ else if eq $gpu.type "nvidia" }}
            requests:
              nvidia.com/gpu: 1
            limits:
              nvidia.com/gpu: 1
            {{ else if eq $gpu.type "intel" }}
            requests:
              gpu.intel.com/i915: "1"
            limits:
              gpu.intel.com/i915: "1"
            {{ end }}
          {{- else }}
          resources:
            {{ toYaml $resources | nindent 12 }}
          {{- end }}
          {{- $hasPersistence := $persistence.enabled }}
          {{- $hasVolumeMounts := .Values.volumeMounts }}
          {{- if or $hasPersistence $hasVolumeMounts }}
          volumeMounts:
            {{ if $hasPersistence }}
            - name: {{ $persistence.name }}
              mountPath: {{ $persistence.mountPath }}
              {{- if $persistence.subPath }}
              subPath: {{ $persistence.subPath }}
              {{- end }}
            {{ end }}
            {{ with .Values.volumeMounts }}
            {{ tpl (toYaml .) $ | nindent 12 }}
            {{ end }}
          {{- end }}
        {{- $extraContainers := .Values.extraContainers }}
        {{- $extraContainersTemplate := .Values.extraContainersTemplate }}
        {{- if $extraContainers }}
        {{- tpl (toYaml $extraContainers) $ | nindent 8 }}
        {{- end }}
        {{- if $extraContainersTemplate }}
        {{- tpl $extraContainersTemplate $ | nindent 8 }}
        {{- end }}
      {{- $hasVolumes := .Values.volumes }}
      {{- if or $persistence.enabled $hasVolumes }}
      volumes:
        {{ if $persistence.enabled }}
        - name: {{ $persistence.name }}
          {{- if $persistence.existingClaim }}
          persistentVolumeClaim:
            claimName: {{ $persistence.existingClaim }}
          {{- else }}
          persistentVolumeClaim:
            claimName: {{ $persistence.claimName | default (include "common.fullname" .) }}
          {{- end }}
        {{ end }}
        {{ with .Values.volumes }}
        {{ tpl (toYaml .) $ | nindent 8 }}
        {{ end }}
      {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end }}
