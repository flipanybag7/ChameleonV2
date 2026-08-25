#!/usr/bin/env bash
set -euo pipefail

# Download the newest successful build artifact from the main branch.
# Requires GitHub CLI (gh) and an authenticated account with repo access.

REPO="${REPO:-flipanybag7/ChameleonV2}"
WORKFLOW="${WORKFLOW:-build.yml}"
DEST="${DEST:-/home/whoareyou/Desktop/Githubbbbb}"

command -v gh >/dev/null 2>&1 || {
  echo "Error: GitHub CLI (gh) is not installed." >&2
  exit 1
}

gh auth status >/dev/null 2>&1 || {
  echo "Error: authenticate first with: gh auth login" >&2
  exit 1
}

run_id="$(gh run list \
  --repo "$REPO" \
  --workflow "$WORKFLOW" \
  --branch main \
  --event push \
  --status success \
  --limit 1 \
  --json databaseId \
  --jq '.[0].databaseId')"

if [[ -z "$run_id" || "$run_id" == "null" ]]; then
  echo "Error: no successful main-branch build was found." >&2
  exit 1
fi

mkdir -p "$DEST"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

echo "Downloading artifacts from successful run $run_id..."
gh run download "$run_id" --repo "$REPO" --dir "$tmp_dir"

mapfile -t files < <(find "$tmp_dir" -type f \( -name '*.deb' -o -name '*.ipa' -o -name '*.zip' \) -print)
if (( ${#files[@]} == 0 )); then
  echo "Error: the build had no .deb, .ipa, or .zip artifact." >&2
  exit 1
fi

for file in "${files[@]}"; do
  cp -f "$file" "$DEST/"
  echo "Saved: $DEST/$(basename "$file")"
done

echo "Done. Latest build files are in $DEST"
