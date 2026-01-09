{{- define "common.deployment" -}}
{{- $mountEnabled := false -}}
{{- if hasKey .Values "persistence" -}}
  {{- $mountEnabled = true -}}
  {{- if hasKey .Values.persistence "mountEnabled" -}}
    {{- $mountEnabled = .Values.persistence.mountEnabled -}}
  {{- end -}}
{{- end -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount | default 1 }}
  {{- with .Values.deploymentStrategy }}
  strategy:
    {{- toYaml . | nindent 4 }}
  {{- else }}
  strategy:
    type: Recreate
  {{- end }}
  selector:
    matchLabels:
      {{- include "common.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "common.selectorLabels" . | nindent 8 }}
        {{- with .Values.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    spec:
      {{- $gpuEnabled := false -}}
      {{- if .Values.gpu }}
        {{- $gpuEnabled = .Values.gpu.enabled | default false -}}
      {{- end }}
      {{- if $gpuEnabled }}
      {{- $runtimeClassName := .Values.gpu.runtimeClassName | default "" -}}
      {{- if and (not $runtimeClassName) (eq .Values.gpu.type "nvidia") }}
      {{- $runtimeClassName = "nvidia" -}}
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
      {{- with .Values.podSecurityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if .Values.initContainers }}
      initContainers:
        {{- if kindIs "string" .Values.initContainers }}
        {{- tpl .Values.initContainers . | nindent 8 }}
        {{- else }}
        {{- toYaml .Values.initContainers | nindent 8 }}
        {{- end }}
      {{- end }}
      containers:
        - name: {{ .Values.container.name | default (include "common.fullname" .) }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy | default "IfNotPresent" }}
          {{- $containerSecurity := .Values.container.securityContext -}}
          {{- if and (not $containerSecurity) .Values.securityContext }}
          {{- $containerSecurity = .Values.securityContext -}}
          {{- end }}
          {{- with $containerSecurity }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- $env := include "common.env" . }}
          {{- if $env }}
          env:
            {{- $env | nindent 12 }}
          {{- end }}
          {{- with .Values.container.command }}
          command:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.container.args }}
          args:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- if or .Values.container.ports .Values.service.port }}
          ports:
            {{- if .Values.container.ports }}
            {{- toYaml .Values.container.ports | nindent 12 }}
            {{- else }}
            - containerPort: {{ .Values.service.port }}
              name: {{ .Values.service.portName | default (include "common.fullname" .) }}
              protocol: {{ .Values.service.protocol | default "TCP" }}
            {{- end }}
          {{- end }}
          {{- with .Values.livenessProbe }}
          livenessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.readinessProbe }}
          readinessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.startupProbe }}
          startupProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- if $gpuEnabled }}
          {{- if .Values.gpu.resources }}
          resources:
            {{- toYaml .Values.gpu.resources | nindent 12 }}
          {{- else if eq .Values.gpu.type "nvidia" }}
          resources:
            requests:
              nvidia.com/gpu: 1
            limits:
              nvidia.com/gpu: 1
          {{- else if eq .Values.gpu.type "intel" }}
          resources:
            requests:
              gpu.intel.com/i915: "1"
            limits:
              gpu.intel.com/i915: "1"
          {{- end }}
          {{- else if .Values.resources }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          {{- end }}
          {{- if or $mountEnabled .Values.volumeMounts .Values.container.additionalMounts .Values.persistence.additionalMounts }}
          volumeMounts:
            {{- if $mountEnabled }}
            - name: {{ .Values.persistence.volumeName | default "config" }}
              mountPath: {{ .Values.persistence.mountPath | default "/config" }}
            {{- end }}
            {{- with .Values.persistence.additionalMounts }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
            {{- with .Values.container.additionalMounts }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
            {{- with .Values.volumeMounts }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
          {{- end }}
        {{- with .Values.extraContainers }}
        {{- if kindIs "string" . }}
        {{- tpl . $ | nindent 8 }}
        {{- else }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- end }}
      {{- if or $mountEnabled .Values.extraVolumes .Values.volumes }}
      volumes:
        {{- if $mountEnabled }}
        - name: {{ .Values.persistence.volumeName | default "config" }}
          {{- if .Values.persistence.enabled }}
          persistentVolumeClaim:
            claimName: {{ include "common.pvcClaimName" . }}
          {{- else }}
          emptyDir: {}
          {{- end }}
        {{- with .Values.persistence.additionalVolumes }}
        {{- if kindIs "string" . }}
        {{- tpl . $ | nindent 8 }}
        {{- else }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- end }}
        {{- end }}
        {{- with .Values.extraVolumes }}
        {{- if kindIs "string" . }}
        {{- tpl . $ | nindent 8 }}
        {{- else }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- end }}
        {{- with .Values.volumes }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
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

{{- define "common.all" -}}
{{- include "common.serviceAccount" . }}
{{- include "common.deployment" . }}
{{- include "common.service" . }}
{{- include "common.ingress" . }}
{{- include "common.gateway" . }}
{{- include "common.pvc" . }}
{{- end }}

{{- define "common.serviceAccount" -}}
{{- $serviceAccountCreate := false -}}
{{- if .Values.serviceAccount }}
  {{- $serviceAccountCreate = .Values.serviceAccount.create | default false -}}
{{- end }}
{{- if $serviceAccountCreate }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "common.serviceAccountName" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with .Values.serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
automountServiceAccountToken: {{ .Values.serviceAccount.automount }}
{{- end }}
{{- end }}

{{- define "common.gateway" -}}
{{- if .Values.gateway.enabled }}
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: {{ .Values.gateway.name | default (include "common.fullname" .) }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  gatewayClassName: {{ .Values.gateway.gatewayClassName | quote }}
  {{- if .Values.gateway.listeners }}
  listeners:
    {{- toYaml .Values.gateway.listeners | nindent 4 }}
  {{- end }}
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ .Values.gateway.route.name | default (include "common.fullname" .) }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  {{- if .Values.gateway.route.hostnames }}
  hostnames:
    {{- toYaml .Values.gateway.route.hostnames | nindent 4 }}
  {{- end }}
  parentRefs:
    - name: {{ .Values.gateway.name | default (include "common.fullname" .) }}
      {{- if .Values.gateway.namespace }}
      namespace: {{ .Values.gateway.namespace }}
      {{- end }}
  rules:
    - matches:
        {{- toYaml .Values.gateway.route.matches | nindent 8 }}
      {{- if .Values.gateway.route.filters }}
      filters:
        {{- toYaml .Values.gateway.route.filters | nindent 8 }}
      {{- end }}
      backendRefs:
        - name: {{ include "common.fullname" . }}
          port: {{ .Values.service.port }}
{{- end }}
{{- end }}

{{- define "common.service" -}}
{{- $serviceEnabled := true -}}
{{- if hasKey .Values "service" -}}
  {{- if hasKey .Values.service "enabled" -}}
    {{- $serviceEnabled = .Values.service.enabled -}}
  {{- end -}}
{{- end -}}
{{- if $serviceEnabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- with .Values.service.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  type: {{ .Values.service.type | default "ClusterIP" }}
  {{- with .Values.service.loadBalancerIP }}
  loadBalancerIP: {{ . | quote }}
  {{- end }}
  selector:
    {{- include "common.selectorLabels" . | nindent 4 }}
  ports:
    {{- if .Values.service.ports }}
    {{- toYaml .Values.service.ports | nindent 4 }}
    {{- else }}
    - protocol: {{ .Values.service.protocol | default "TCP" }}
      port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort | default .Values.service.port }}
      {{- with .Values.service.name }}
      name: {{ . }}
      {{- end }}
    {{- end }}
{{- end }}
{{- end }}

{{- define "common.ingress" -}}
{{- if .Values.ingress.enabled }}
{{- $annotations := dict -}}
{{- if .Values.ingress.clusterIssuer }}
{{- $_ := set $annotations "cert-manager.io/cluster-issuer" .Values.ingress.clusterIssuer -}}
{{- end }}
{{- if .Values.ingress.acme }}
{{- $_ := set $annotations "kubernetes.io/tls-acme" "true" -}}
{{- end }}
{{- if .Values.ingress.annotations }}
{{- $annotations = merge $annotations .Values.ingress.annotations -}}
{{- end }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
  {{- if $annotations }}
  annotations:
    {{- toYaml $annotations | nindent 4 }}
  {{- end }}
spec:
  {{- if .Values.ingress.className }}
  ingressClassName: {{ .Values.ingress.className }}
  {{- else if .Values.ingress.class }}
  ingressClassName: {{ .Values.ingress.class }}
  {{- end }}
  {{- $tlsEntries := list }}
  {{- if .Values.ingress.hosts }}
    {{- range .Values.ingress.hosts }}
      {{- if .tls }}
        {{- $tls := deepCopy .tls }}
        {{- if and (not $tls.hosts) .host }}
          {{- $_ := set $tls "hosts" (list .host) -}}
        {{- end }}
        {{- $tlsEntries = append $tlsEntries $tls -}}
      {{- end }}
    {{- end }}
  {{- end }}
  rules:
    {{- if .Values.ingress.hosts }}
    {{- range .Values.ingress.hosts }}
    - host: {{ .host }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path | default "/" }}
            pathType: {{ .pathType | default "Prefix" }}
            backend:
              service:
                name: {{ include "common.fullname" $ }}
                port:
                  number: {{ .servicePort | default $.Values.service.port }}
          {{- end }}
    {{- end }}
    {{- else }}
    - host: {{ .Values.ingress.fqdn }}
      http:
        paths:
          - path: {{ .Values.ingress.path | default "/" }}
            pathType: {{ .Values.ingress.pathType | default "Prefix" }}
            backend:
              service:
                name: {{ include "common.fullname" . }}
                port:
                  number: {{ .Values.service.port }}
    {{- end }}
  {{- if .Values.ingress.tls }}
  tls:
    {{- toYaml .Values.ingress.tls | nindent 4 }}
  {{- else if $tlsEntries }}
  tls:
    {{- toYaml $tlsEntries | nindent 4 }}
  {{- else if and .Values.ingress.tlsSecretName .Values.ingress.fqdn }}
  tls:
    - hosts:
        - {{ .Values.ingress.fqdn }}
      secretName: {{ .Values.ingress.tlsSecretName }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "common.pvc" -}}
{{- $existingClaim := coalesce .Values.persistence.existingClaim .Values.persistence.exisitingClaim "" -}}
{{- if and .Values.persistence.enabled (not $existingClaim) }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  accessModes:
    - {{ .Values.persistence.accessMode | default "ReadWriteOnce" | quote }}
  resources:
    requests:
      storage: {{ .Values.persistence.size | default "1Gi" | quote }}
  {{- with .Values.persistence.storageClass }}
  storageClassName: {{ . | quote }}
  {{- end }}
{{- end }}
{{- end }}
