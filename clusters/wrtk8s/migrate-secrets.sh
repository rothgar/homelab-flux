#!/usr/bin/env bash
set -e

VAULT="wrtk8s"
KUBECONFIG="kube-sa"
KUBECTL="/nix/store/6m48j0x1w9hq9l6byqcnj82q5h0c6nbg-kubectl-1.35.3/bin/kubectl"

SECRETS=(
  "cert-manager/cloudflare-api-token"
  "controld-exporter/controld-api-key"
  "external-dns/cloudflare-api-token"
  "frigate/frigate-config"
  "immich/immich-postgres"
  "minecraft/playit-secret"
  "miniflux/miniflux-app-credentials"
  "miniflux/miniflux-db-credentials"
  "resolve-db/resolve-db-credentials"
  "tts/tts-api-key"
  "vllm-system/hf-token"
)

for pair in "${SECRETS[@]}"; do
  ns="${pair%%/*}"
  name="${pair##*/}"
  title="${ns}/${name}"

  echo "=== Creating 1Password item: ${title} ==="

  # Get all keys and values from the secret
  keys=$($KUBECTL --kubeconfig "$KUBECONFIG" get secret "$name" -n "$ns" -o json | jq -r '.data // {} | keys[]')

  # Build assignment arguments
  assignments=()
  for key in $keys; do
    value=$($KUBECTL --kubeconfig "$KUBECONFIG" get secret "$name" -n "$ns" -o jsonpath="{.data.${key}}" | base64 -d)
    assignments+=("${key}[password]=${value}")
  done

  # Create the item with positional assignments
  op item create \
    --vault "$VAULT" \
    --category login \
    --title "$title" \
    "${assignments[@]}" 2>&1 || echo "  FAILED: ${title}"

  echo ""
done

echo "Done! All secrets migrated to 1Password vault: ${VAULT}"
