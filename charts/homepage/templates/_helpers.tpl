{{/*
Resolve a single secretRef object to a decoded scalar value.
Input:
  root: the root chart context
  ref: map with name, key, optional namespace
  path: logical path string used in error messages
*/}}
{{- define "homepage.resolveSecretRefValue" -}}
{{- $root := .root -}}
{{- $ref := .ref -}}
{{- $path := .path -}}
{{- if not (kindIs "map" $ref) -}}
{{- fail (printf "%s secretRef must be a map with name/key" $path) -}}
{{- end -}}
{{- $name := required (printf "%s secretRef.name is required" $path) (index $ref "name") -}}
{{- $key := required (printf "%s secretRef.key is required" $path) (index $ref "key") -}}
{{- $namespace := default $root.Release.Namespace (index $ref "namespace") -}}
{{- $secret := lookup "v1" "Secret" $namespace $name -}}
{{- if not $secret -}}
{{- fail (printf "%s references Secret %s/%s, but it was not found. secretRef resolution requires cluster access and a readable Secret at render time." $path $namespace $name) -}}
{{- end -}}
{{- $secretData := default (dict) (index $secret "data") -}}
{{- if not (hasKey $secretData $key) -}}
{{- fail (printf "%s references key %q in Secret %s/%s, but the key does not exist" $path $key $namespace $name) -}}
{{- end -}}
{{- $decoded := b64dec (index $secretData $key) -}}
{{- if eq $decoded "" -}}
{{- fail (printf "%s references key %q in Secret %s/%s, but the decoded value is empty" $path $key $namespace $name) -}}
{{- end -}}
{{- $decoded -}}
{{- end -}}

{{/*
Recursively walk any YAML node and resolve secretRef objects.
Input:
  root: the root chart context
  node: current node (map/list/scalar)
  path: logical path string for error context
*/}}
{{- define "homepage.resolveNode" -}}
{{- $root := .root -}}
{{- $node := .node -}}
{{- $path := .path -}}
{{- if kindIs "map" $node -}}
  {{- if and (eq (len $node) 1) (hasKey $node "secretRef") -}}
    {{- include "homepage.resolveSecretRefValue" (dict "root" $root "ref" (index $node "secretRef") "path" $path) -}}
  {{- else -}}
    {{- $out := dict -}}
    {{- range $k, $v := $node -}}
      {{- $childPath := printf "%s.%s" $path $k -}}
      {{- if kindIs "map" $v -}}
        {{- if and (eq (len $v) 1) (hasKey $v "secretRef") -}}
          {{- $_ := set $out $k (include "homepage.resolveSecretRefValue" (dict "root" $root "ref" (index $v "secretRef") "path" $childPath)) -}}
        {{- else -}}
          {{- $_ := set $out $k (include "homepage.resolveNode" (dict "root" $root "node" $v "path" $childPath) | fromYaml) -}}
        {{- end -}}
      {{- else if kindIs "slice" $v -}}
        {{- $_ := set $out $k (include "homepage.resolveNode" (dict "root" $root "node" $v "path" $childPath) | fromYamlArray) -}}
      {{- else -}}
        {{- $_ := set $out $k $v -}}
      {{- end -}}
    {{- end -}}
    {{- toYaml $out -}}
  {{- end -}}
{{- else if kindIs "slice" $node -}}
  {{- $out := list -}}
  {{- range $i, $v := $node -}}
    {{- $childPath := printf "%s[%d]" $path $i -}}
    {{- if kindIs "map" $v -}}
      {{- if and (eq (len $v) 1) (hasKey $v "secretRef") -}}
        {{- $out = append $out (include "homepage.resolveSecretRefValue" (dict "root" $root "ref" (index $v "secretRef") "path" $childPath)) -}}
      {{- else -}}
        {{- $out = append $out (include "homepage.resolveNode" (dict "root" $root "node" $v "path" $childPath) | fromYaml) -}}
      {{- end -}}
    {{- else if kindIs "slice" $v -}}
      {{- $out = append $out (include "homepage.resolveNode" (dict "root" $root "node" $v "path" $childPath) | fromYamlArray) -}}
    {{- else -}}
      {{- $out = append $out $v -}}
    {{- end -}}
  {{- end -}}
  {{- toYaml $out -}}
{{- else -}}
  {{- toYaml $node -}}
{{- end -}}
{{- end -}}

{{- define "homepage.renderWidgets" -}}
{{- include "homepage.resolveNode" (dict "root" . "node" .Values.config.widgets "path" "config.widgets") -}}
{{- end -}}

{{- define "homepage.renderServices" -}}
{{- include "homepage.resolveNode" (dict "root" . "node" .Values.config.services "path" "config.services") -}}
{{- end -}}
