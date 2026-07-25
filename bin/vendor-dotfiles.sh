#!/usr/bin/env bash
# Vendor dotfiles from this Mac into the repo, pruning macOS-only content.
# Runs on macOS only (BSD sed). Output is committed to the repo.
set -euo pipefail

cd "$(dirname "$0")/.."

ZSHRC=roles/shell/files/zshrc
P10K=roles/shell/files/p10k.zsh
TMUX=roles/shell/files/tmux.conf
NVIM=roles/nvim/files/nvim

mkdir -p roles/shell/files roles/nvim/files

# --- .zshrc ---
cp "$HOME/.zshrc" "$ZSHRC"

# LM Studio block
sed -i '' '/^# Added by LM Studio CLI/,/^# End of LM Studio CLI section/d' "$ZSHRC"
# bun exports + completions
sed -i '' '/\.bun/d; /^# bun completions$/d; /^# bun$/d; /BUN_INSTALL/d' "$ZSHRC"
# OpenRouter key
sed -i '' '/OPENROUTER_API_KEY/d; /^# openrouter api key$/d' "$ZSHRC"
# claude-mem alias + homebrew nvim alias
sed -i '' '/claude-mem/d; /homebrew\/bin\/nvim/d' "$ZSHRC"
# Dedupe repeated lines ignoring trailing whitespace, preserving blanks and
# syntax-significant lines (a repeated '}' closes two different functions).
awk '{ k=$0; gsub(/[ \t]+$/,"",k) } NF==0 || k=="}" { print; next } !seen[k]++' "$ZSHRC" > /tmp/zshrc.$$
mv /tmp/zshrc.$$ "$ZSHRC"
# uv PATH shim must be sourced before the thefuck evals use it
sed -i '' '/^\. "\$HOME\/\.local\/bin\/env"$/d' "$ZSHRC"
sed -i '' '/^eval \$(thefuck --alias)$/i\
. "$HOME/.local/bin/env"' "$ZSHRC"
# Disable OMZ auto-update (insert after export ZSH= line)
sed -i '' "/^export ZSH=/a\\
zstyle ':omz:update' mode disabled" "$ZSHRC"
# Optional local overrides as final line
printf '[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local\n' >> "$ZSHRC"

# --- self-checks ---
fail=0
check() { # desc, cmd...
  local desc=$1; shift
  if "$@"; then echo "  ok: $desc"; else echo "FAIL: $desc"; fail=1; fi
}

check "no macOS-only content" bash -c "! grep -qE 'LM Studio|\.bun|OPENROUTER|claude-mem|homebrew' '$ZSHRC'"
check "thefuck aliases present (2)" test "$(grep -c 'thefuck --alias' "$ZSHRC")" = 2
check "gg alias deduped (1)" test "$(grep -c "gg='lazygit'" "$ZSHRC")" = 1
check "last line sources .zshrc.local" bash -c "tail -n1 '$ZSHRC' | grep -qF 'source ~/.zshrc.local'"
check "omz update disabled" grep -qF "zstyle ':omz:update' mode disabled" "$ZSHRC"
check "zsh syntax valid" zsh -n "$ZSHRC"
check "no bun remnant" bash -c "! grep -q 'BUN_INSTALL' '$ZSHRC'"
[ "$fail" -eq 0 ] || { echo "vendor-dotfiles: self-check failed" >&2; exit 1; }

# --- p10k, tmux, nvim ---
cp "$HOME/.p10k.zsh" "$P10K"
cp "$HOME/.tmux.conf" "$TMUX"
rsync -a --delete --exclude '.git' "$HOME/.config/nvim/" "$NVIM/"

# lazy-lock.json gets rewritten by `Lazy! sync` on the server; manage it as a
# seed-only file (copied when absent) instead of fighting Lazy on every run.
if [ -f "$NVIM/lazy-lock.json" ]; then
  mv "$NVIM/lazy-lock.json" roles/nvim/files/lazy-lock.json
fi

echo "vendored: zshrc ($(wc -l < "$ZSHRC" | tr -d ' ') lines), p10k.zsh, tmux.conf, nvim/"
