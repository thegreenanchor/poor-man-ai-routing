#!/usr/bin/env bash
# INSTALL.sh — Claude Routing System installer for bash/zsh
# Run from the repository root.

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE="$SCRIPT_DIR/.claude"
TARGET="$HOME/.claude"

echo "==> Claude Routing System installer"
echo "Source: $SOURCE"
echo "Target: $TARGET"
echo

# 1. Backup existing
if [ -d "$TARGET" ]; then
  STAMP=$(date +%Y%m%d-%H%M%S)
  BACKUP="$TARGET.bak.$STAMP"
  echo "==> Backing up existing $TARGET -> $BACKUP"
  mv "$TARGET" "$BACKUP"
fi

# 2. Copy
echo "==> Copying config to $TARGET"
cp -r "$SOURCE" "$TARGET"

# 3. Make wrappers executable
echo "==> Making bin/* executable"
chmod +x "$TARGET"/bin/*.sh 2>/dev/null || true
chmod +x "$TARGET"/hooks/*.sh 2>/dev/null || true

# 4. Symlink .sh wrappers to bare names so PATH lookup just works
ln -sf "$TARGET/bin/cdx.sh" "$TARGET/bin/cdx"
ln -sf "$TARGET/bin/cx.sh" "$TARGET/bin/cx"
ln -sf "$TARGET/bin/gca.sh" "$TARGET/bin/gca"
ln -sf "$TARGET/bin/ai-mode.sh" "$TARGET/bin/ai-mode"

# 5. Add to PATH (idempotent)
SHELL_RC=""
case "$(basename "$SHELL")" in
  bash) SHELL_RC="$HOME/.bashrc" ;;
  zsh)  SHELL_RC="$HOME/.zshrc" ;;
  *)    SHELL_RC="$HOME/.profile" ;;
esac

PATH_LINE='export PATH="$HOME/.claude/bin:$PATH"'

if ! grep -Fq "$PATH_LINE" "$SHELL_RC" 2>/dev/null; then
  echo "==> Adding ~/.claude/bin to PATH in $SHELL_RC"
  echo "" >> "$SHELL_RC"
  echo "# Claude Routing System" >> "$SHELL_RC"
  echo "$PATH_LINE" >> "$SHELL_RC"
  echo "    (Open a new shell or run: source $SHELL_RC)"
else
  echo "==> ~/.claude/bin already in PATH ($SHELL_RC)"
fi

# 6. Verify external tools
echo
echo "==> Checking external tools"

check_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "  OK  $1 -> $(command -v "$1")"
    return 0
  else
    echo "  XX  $1 not found"
    return 1
  fi
}

CODEX_OK=0
GEMINI_OK=0
check_cmd codex && CODEX_OK=1 || true
check_cmd gemini && GEMINI_OK=1 || true

if [ "$CODEX_OK" -eq 0 ]; then
  echo
  echo "Install Codex CLI:"
  echo "  npm install -g @openai/codex"
  echo "  codex auth"
fi

if [ "$GEMINI_OK" -eq 0 ]; then
  echo
  echo "Install Gemini CLI:"
  echo "  npm install -g @google/gemini-cli"
  echo "  gemini auth"
fi

# 7. Done
echo
echo "==> Install complete."
echo
echo "Next steps:"
echo "  1. Open a new terminal (or 'source $SHELL_RC')."
echo "  2. Verify: 'ai-mode status', 'cx --help', 'cdx --help', and 'gca --help'"
echo "  3. Start in 'cx' for a Codex-led session, or Claude Code for a Claude-led session."
echo
echo "Docs: $SCRIPT_DIR/docs/PHASES.md"
