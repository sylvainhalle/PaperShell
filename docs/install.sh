
# ------------------------------------------------------------
# Simple installation script for PaperShell 3
# ------------------------------------------------------------
set -euo pipefail

# Defaults
PS_REMOTE_URL="https://github.com/sylvainhalle/PaperShell.git"
PS_BRANCH="v3"
PS_LOCAL_BIN="${HOME}/.local/bin"
PS_LOCAL_SHARE="${HOME}/.local/share"
PS_LOCAL_MAN="${PS_LOCAL_SHARE}/man"
PS_INSTALL_DIR="${PS_LOCAL_SHARE}/papershell"
PS_WRAPPER="${PS_LOCAL_BIN}/papershell"
PAPERSHELL_HOME="$(realpath $(pwd)/../)"

# Prints a message
say() {
  printf '[papershell] %s\n' "$*"
}

# Prints an error message
fail() {
  printf '[papershell] ERROR: %s\n' "$*" >&2
  exit 1
}

# Default action is install
PS_ACTION="install"

case "${1:-}" in
  install|"")
    PS_ACTION="install"
    ;;
  uninstall|--uninstall|-u)
    PS_ACTION="uninstall"
    ;;
  *)
    fail "Unknown option: $1"
    ;;
esac

uninstall() {
  say "Removing PaperShell"
  rm -rf "$PS_INSTALL_DIR"
  rm -f "$PS_WRAPPER"
  say "Uninstalled PaperShell"
}

if [ "$PS_ACTION" = "uninstall" ]; then
  uninstall
  exit 0
fi

# Sanity checks
command -v texlua >/dev/null 2>&1 || say "Warning: texlua was not found in PATH; PaperShell may not run until it is installed"

# Directories
say "Creating install directories"
mkdir -p "$PS_LOCAL_BIN" "$PS_LOCAL_SHARE" "$PS_LOCAL_MAN"

if [ -d "$PS_INSTALL_DIR" ]; then
  say "Removing previous installation at $PS_INSTALL_DIR"
  rm -rf "$PS_INSTALL_DIR"
fi

if command -v git >/dev/null 2>&1; then
  say "Cloning PaperShell with git"
  git clone --depth 1 -q "$PS_REMOTE_URL" "$PS_INSTALL_DIR" || fail "Could not clone repository"
  rm -rf "$PS_INSTALL_DIR/.git"
else
  say "git not found; falling back to ZIP download"

  command -v curl >/dev/null 2>&1 || fail "curl is required when git is not available"
  command -v unzip >/dev/null 2>&1 || fail "unzip is required when git is not available"

  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT

  zipfile="$tmpdir/papershell.zip"

  curl -fsSL \
    "https://github.com/sylvainhalle/PaperShell/archive/refs/heads/${PS_BRANCH}.zip" \
    -o "$zipfile" \
    || fail "Could not download PaperShell ZIP archive"

  unzip -q "$zipfile" -d "$tmpdir" \
    || fail "Could not unzip PaperShell archive"

  mv "$tmpdir/PaperShell-master" "$PS_INSTALL_DIR" \
    || fail "Could not install PaperShell files"
fi

# Executable wrapper
say "Creating wrapper: $PS_WRAPPER"
cat > "$PS_WRAPPER" <<EOF
#!/usr/bin/env bash
set -euo pipefail
export PAPERSHELL_HOME="$(realpath $(pwd)/../)"
exec texlua "\$PAPERSHELL_HOME/Tools/psmod.lua" "$@"
EOF
chmod u+x "$PS_WRAPPER"

# Man page
say "Linking to manpage"
mkdir -p "$PS_LOCAL_MAN/man1"
ln -s "$PAPERSHELL_HOME/Package/usr/local/share/man/man1/papershell.1" "$PS_LOCAL_MAN/man1/"

# Completions
say "Installing completions"
# -- bash
mkdir -p "$PS_LOCAL_SHARE/bash-completion/completions"
ln -s "$PAPERSHELL_HOME/Package/completions/bash" "$PS_LOCAL_SHARE/bash-completion/completions/papershell.bash"
# -- zsh
mkdir -p "$PS_LOCAL_SHARE/zsh/site-functions"
ln -s "$PAPERSHELL_HOME/Package/completions/zsh" "$PS_LOCAL_SHARE/zsh/site-functions/_papershell"
# -- fish
mkdir -p "~/.config/fish/completions"
ln -s "$PAPERSHELL_HOME/Package/completions/fish" "~/.config/fish/completions/papershell.fish"

say "Installed PaperShell successfully"

case ":$PATH:" in
  *":$PS_LOCAL_BIN:"*)
    ;;
  *)
    say "Note: $PS_LOCAL_BIN is not currently in your PATH"
    say "Add this to your shell startup file if needed:"
    say "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    ;;
esac

say "To create an empty project, type papershell init <folder>"

say "Done"
exit 0
