#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHARTS_DIR="$ROOT_DIR/charts"
COMMON_CHART_DIR="$CHARTS_DIR/common"

if ! command -v helm >/dev/null 2>&1; then
  echo "helm is required" >&2
  exit 1
fi

common_version="$(awk '/^version:/ { print $2; exit }' "$COMMON_CHART_DIR/Chart.yaml")"
local_common_repo="file://$COMMON_CHART_DIR"

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

failures=0
tested=0

requested_charts=("$@")

patch_chart_dependency_to_local_common() {
  local file="$1"
  local tmpfile
  tmpfile="$(mktemp)"

  awk -v common_version="$common_version" -v local_repo="$local_common_repo" '
    {
      if ($0 ~ /^[[:space:]]*-[[:space:]]+name:[[:space:]]+common[[:space:]]*$/) {
        in_common_dep = 1
        print
        next
      }

      if (in_common_dep && $0 ~ /^[[:space:]]+version:/) {
        sub(/version:.*/, "version: " common_version)
        print
        next
      }

      if (in_common_dep && $0 ~ /^[[:space:]]+repository:/) {
        sub(/repository:.*/, "repository: \"" local_repo "\"")
        in_common_dep = 0
        print
        next
      }

      print
    }
  ' "$file" >"$tmpfile"

  mv "$tmpfile" "$file"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "ASSERTION FAILED: $msg" >&2
    return 1
  fi
}

while IFS= read -r chart_yaml; do
  chart_dir="$(dirname "$chart_yaml")"
  chart_name="$(basename "$chart_dir")"

  if [[ "$chart_name" == "common" ]]; then
    continue
  fi

  if ! grep -q 'name: common' "$chart_yaml"; then
    continue
  fi

  if [[ "${#requested_charts[@]}" -gt 0 ]]; then
    match=0
    for requested in "${requested_charts[@]}"; do
      if [[ "$requested" == "$chart_name" ]]; then
        match=1
        break
      fi
    done
    if [[ "$match" -eq 0 ]]; then
      continue
    fi
  fi

  tested=$((tested + 1))
  workdir="$tmpdir/$chart_name"
  cp -R "$chart_dir" "$workdir"

  # Force consumer charts to use the local common chart and current local version.
  patch_chart_dependency_to_local_common "$workdir/Chart.yaml"

  echo "==> Testing $chart_name"
  if ! helm dependency build "$workdir" >/dev/null 2>&1; then
    echo "FAILED: helm dependency build for $chart_name" >&2
    failures=$((failures + 1))
    continue
  fi

  if ! rendered="$(helm template "test-$chart_name" "$workdir" 2>&1)"; then
    echo "FAILED: helm template for $chart_name" >&2
    echo "$rendered" >&2
    failures=$((failures + 1))
    continue
  fi

  # Targeted regression checks around the common chart changes.
  if [[ "$chart_name" == "overseerr" ]]; then
    if ! assert_contains "$rendered" $'kind: Deployment' "overseerr should remain a Deployment by default"; then
      failures=$((failures + 1))
      continue
    fi
  fi

  if [[ "$chart_name" == "seerr" ]]; then
    if ! assert_contains "$rendered" $'kind: StatefulSet' "seerr should render as a StatefulSet"; then
      failures=$((failures + 1))
      continue
    fi
    if ! assert_contains "$rendered" $'ipFamilyPolicy: PreferDualStack' "seerr service should include ipFamilyPolicy"; then
      failures=$((failures + 1))
      continue
    fi
  fi
done < <(find "$CHARTS_DIR" -mindepth 2 -maxdepth 2 -name Chart.yaml | sort)

echo
echo "Tested consumer charts: $tested"

if [[ "${#requested_charts[@]}" -gt 0 && "$tested" -eq 0 ]]; then
  echo "No matching consumer charts found for: ${requested_charts[*]}" >&2
  exit 1
fi

if [[ "$failures" -ne 0 ]]; then
  echo "Failures: $failures" >&2
  exit 1
fi

echo "All consumer chart render tests passed."
