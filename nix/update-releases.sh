#!/usr/bin/env bash
set -euo pipefail

if ! command -v nix >/dev/null 2>&1; then
  echo "nix not installed; skipping release update" >&2
  exit 0
fi

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
lockfile="$repo_root/nix/releases.json"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

fetch_url() {
  local response
  if response=$(curl --fail-with-body -sSL "$1"); then
    printf '%s\n' "$response"
  else
    printf 'Failed to fetch %s\n%s\n' "$1" "$response" >&2
    return 1
  fi
}

github_api() {
  if command -v gh >/dev/null 2>&1 && gh auth token --hostname github.com >/dev/null 2>&1; then
    gh api --hostname github.com "$1"
  else
    fetch_url "https://api.github.com/$1" || {
      echo 'For a GitHub rate limit, wait for reset or authenticate with: gh auth login --hostname github.com' >&2
      return 1
    }
  fi
}

github_asset() {
  local repository=$1
  local asset=$2
  local release

  release=$(github_api "repos/$repository/releases/latest") || return
  jq -er --arg asset "$asset" '
      . as $release
      | .assets[]
      | select(.name == $asset)
      | [$release.tag_name, .browser_download_url, .digest]
      | @tsv
    ' <<<"$release"
}

sri_hash() {
  local digest=${1#sha256:}
  nix hash convert --hash-algo sha256 --to sri "$digest"
}

claude_base=https://downloads.claude.ai/claude-code-releases
claude_version=$(fetch_url "$claude_base/latest")
claude_manifest=$(fetch_url "$claude_base/$claude_version/manifest.zst.json")
claude_binary=$(jq -er '.platforms["linux-x64"].binary' <<<"$claude_manifest")
claude_digest=$(jq -er '.platforms["linux-x64"].checksum' <<<"$claude_manifest")
claude_url="$claude_base/$claude_version/linux-x64/$claude_binary"
asset_info=$(github_asset openai/codex codex-package-x86_64-unknown-linux-musl.tar.gz)
read -r codex_tag codex_url codex_digest <<<"$asset_info"
asset_info=$(github_asset github/copilot-cli copilot-linux-x64.tar.gz)
read -r copilot_tag copilot_url copilot_digest <<<"$asset_info"
hermes_release=$(github_api repos/NousResearch/hermes-agent/releases/latest)
hermes_tag=$(jq -er .tag_name <<<"$hermes_release")
hermes_version=$(jq -er '.name | capture("^Hermes Agent v(?<version>[0-9]+\\.[0-9]+\\.[0-9]+)").version' <<<"$hermes_release")
hermes_rev=$(
  github_api "repos/NousResearch/hermes-agent/commits/$hermes_tag" |
    jq -er .sha
)
asset_info=$(github_asset can1357/oh-my-pi omp-linux-x64)
read -r omp_tag omp_url omp_digest <<<"$asset_info"
asset_info=$(github_asset anomalyco/opencode opencode-linux-x64.tar.gz)
read -r opencode_tag opencode_url opencode_digest <<<"$asset_info"
asset_info=$(github_asset OpenRouterLabs/ori-releases ori-linux-x64)
read -r ori_tag ori_url ori_digest <<<"$asset_info"

codex_version=${codex_tag#rust-v}
copilot_version=${copilot_tag#v}
omp_version=${omp_tag#v}
opencode_version=${opencode_tag#v}
ori_version=${ori_tag#cli-}
ori_version=${ori_version/-/+}
if [[ ! $claude_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ||
  $codex_version == "$codex_tag" ||
  $copilot_version == "$copilot_tag" ||
  ! $hermes_tag =~ ^v[0-9]{4}\.[0-9]{1,2}\.[0-9]{1,2}$ ||
  ! $hermes_rev =~ ^[0-9a-f]{40}$ ||
  $omp_version == "$omp_tag" ||
  $opencode_version == "$opencode_tag" ||
  $ori_version == "$ori_tag" ]]; then
  echo "unexpected release tag" >&2
  exit 1
fi
claude_hash=$(sri_hash "$claude_digest")
codex_hash=$(sri_hash "$codex_digest")
copilot_hash=$(sri_hash "$copilot_digest")
omp_hash=$(sri_hash "$omp_digest")
opencode_hash=$(sri_hash "$opencode_digest")
ori_hash=$(sri_hash "$ori_digest")

jq -n \
  --arg claude_version "$claude_version" \
  --arg claude_url "$claude_url" \
  --arg claude_hash "$claude_hash" \
  --arg codex_version "$codex_version" \
  --arg codex_url "$codex_url" \
  --arg codex_hash "$codex_hash" \
  --arg copilot_version "$copilot_version" \
  --arg copilot_url "$copilot_url" \
  --arg copilot_hash "$copilot_hash" \
  --arg hermes_version "$hermes_version" \
  --arg hermes_tag "$hermes_tag" \
  --arg hermes_rev "$hermes_rev" \
  --arg omp_version "$omp_version" \
  --arg omp_url "$omp_url" \
  --arg omp_hash "$omp_hash" \
  --arg opencode_version "$opencode_version" \
  --arg opencode_url "$opencode_url" \
  --arg opencode_hash "$opencode_hash" \
  --arg ori_version "$ori_version" \
  --arg ori_url "$ori_url" \
  --arg ori_hash "$ori_hash" \
  '{
    claude: {version: $claude_version, url: $claude_url, hash: $claude_hash},
    codex: {version: $codex_version, url: $codex_url, hash: $codex_hash},
    copilot: {version: $copilot_version, url: $copilot_url, hash: $copilot_hash},
    hermes: {version: $hermes_version, tag: $hermes_tag, rev: $hermes_rev},
    omp: {version: $omp_version, url: $omp_url, hash: $omp_hash},
    opencode: {version: $opencode_version, url: $opencode_url, hash: $opencode_hash},
    ori: {version: $ori_version, url: $ori_url, hash: $ori_hash}
  }' >"$tmp"

if cmp -s "$tmp" "$lockfile"; then
  echo "release lock is current"
  exit 0
fi

chmod 0644 "$tmp"
mv "$tmp" "$lockfile"
echo "updated: nix/releases.json"
