#!/usr/bin/env bash
set -euo pipefail

chart_dir="${1:-}"
if [[ -z "$chart_dir" ]]; then
  echo "usage: $0 <chart_dir>" >&2
  exit 1
fi

chart_yaml="${chart_dir%/}/Chart.yaml"
if [[ ! -f "$chart_yaml" ]]; then
  echo "missing Chart.yaml in $chart_dir" >&2
  exit 1
fi

current="$(awk '/^version:/{print $2; exit}' "$chart_yaml")"
if [[ -z "$current" ]]; then
  echo "missing version in $chart_yaml" >&2
  exit 1
fi

IFS='.' read -r major minor patch <<< "$current"
if [[ -z "${major:-}" || -z "${minor:-}" || -z "${patch:-}" ]]; then
  echo "invalid version: $current" >&2
  exit 1
fi

patch=$((patch + 1))
new_version="${major}.${minor}.${patch}"

perl -pi -e "s/^version:\\s*.*/version: ${new_version}/" "$chart_yaml"
