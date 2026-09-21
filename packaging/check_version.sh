#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

app_version="$(sed -n "s/^const String appVersion = '\(.*\)';/\1/p" "$PROJECT_ROOT/lib/core/constants.dart")"
pubspec_version="$(sed -n 's/^version:[[:space:]]*\([0-9][^+]*\).*/\1/p' "$PROJECT_ROOT/pubspec.yaml")"
tag="${GITHUB_REF_NAME:-${TAG_NAME:-}}"

if [[ -z "$app_version" ]]; then
  echo "error: could not read appVersion from lib/core/constants.dart" >&2
  exit 1
fi
if [[ -z "$pubspec_version" ]]; then
  echo "error: could not read version from pubspec.yaml" >&2
  exit 1
fi
if [[ "$app_version" != "$pubspec_version" ]]; then
  echo "error: appVersion ($app_version) does not match pubspec version ($pubspec_version)" >&2
  exit 1
fi
if [[ -n "$tag" && "$tag" == v* ]]; then
  tag_version="${tag#v}"
  if [[ "$tag_version" != "$app_version" ]]; then
    echo "error: tag $tag does not match appVersion $app_version" >&2
    exit 1
  fi
fi

echo "version check OK: $app_version${tag:+ (tag $tag)}"
