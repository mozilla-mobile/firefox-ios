#!/usr/bin/env zsh
# macOS helper to build local Application Services artifacts for Firefox iOS.
# Run this script from within the firefox-ios repo root. 
# The script should take care of installing all the necessary dependencies, with the exception of Xcode itself.
# Usage: `./use_local_as.sh`
#
# NOTE1: We explicitly use zsh here since that's the default shell on macOS nowadays. Also handling bash/zsh differences is a pain.
#
# NOTE2: Expected directory structure:
#   parent/
#     ├─ application-services/
#     └─ firefox-ios/    (this script runs here)

set -euo pipefail

###############################################################################
# Pretty logging
# This helps with understanding what the script is doing. Also useful when stuff breaks to trace back what happened.
###############################################################################
log()  { printf "\033[1;34m[info]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[err]\033[0m  %s\n" "$*" >&2; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }


###############################################################################
# Repo roots (we run FROM firefox-ios; AS is a sibling)
###############################################################################
IOS_DIR="$(pwd)"
AS_DIR="$(cd "$IOS_DIR/../application-services" 2>/dev/null && pwd || true)"


if [[ -z "$AS_DIR" || ! -d "$AS_DIR" ]]; then
  expected_path="$(cd "$PWD/.." && pwd)/application-services"
  err "Could not find sibling application-services/ next to firefox-ios/."
  err "Make sure application-services is at: $expected_path"
  exit 1
fi

log "Found firefox-ios dir: $IOS_DIR"
log "Found application-services dir: $AS_DIR"


###############################################################################
# Xcode Command Line Tools / Full Xcode check
###############################################################################
log "Checking Xcode installation..."

# Get the currently selected developer path
DEVELOPER_DIR="$(xcode-select -p 2>/dev/null || true)"

if [[ -z "$DEVELOPER_DIR" ]]; then
  warn "No Xcode developer directory found."
  warn "Please install Xcode from the App Store or from Apple's developer site."
  warn "After installing, run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

# Check if the path looks like Command Line Tools instead of full Xcode
if [[ "$DEVELOPER_DIR" == *"CommandLineTools"* ]]; then
  warn "xcode-select is currently pointing to CommandLineTools:"
  warn "  $DEVELOPER_DIR"
  warn "For building iOS apps, you need full Xcode."
  warn "If Xcode is already installed, set it like this:"
  warn "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  warn "Otherwise, install it from the App Store first."
  exit 1
fi

log "Xcode is correctly configured at: $DEVELOPER_DIR"


###############################################################################
# Homebrew + dependencies
# Install needed dependencies via Homebrew if not already installed.
###############################################################################
log "Ensuring Homebrew..."
if ! have_cmd brew; then
  warn "Homebrew not found; installing."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -d /opt/homebrew/bin ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
  elif [[ -d /usr/local/bin ]]; then
    export PATH="/usr/local/bin:$PATH"
  fi
fi

deps=(ninja python3 wget git rsync)
log "Updating Homebrew and installing dependencies if missing $(printf '%s, ' "${deps[@]}")..."

missing=()
for dep in "${deps[@]}"; do
  if have_cmd "$dep"; then
    log "$dep already installed"
  else
    missing+=("$dep")
  fi
done

# Only update/install if something’s missing
if ((${#missing[@]} > 0)); then
  log "Updating Homebrew..."
  brew update
  log "Installing missing dependencies: ${missing[*]}"
  brew install "${missing[@]}"
else
  log "All dependencies already satisfied."
fi

###############################################################################
# xcpretty (nice Xcode log formatter)
###############################################################################
if have_cmd xcpretty; then
  log "xcpretty available in PATH"
else
  RUBY_USER_BIN="$(ruby -e 'puts Gem.user_dir')/bin"
  XCPRETTY_BIN="$RUBY_USER_BIN/xcpretty"
  if [[ ! -x "$XCPRETTY_BIN" ]]; then
    log "Installing xcpretty via RubyGems (user install)..."
    gem install --user-install xcpretty || true
  fi
  export PATH="$RUBY_USER_BIN:$PATH"
  log "Added $RUBY_USER_BIN to PATH for this session"
fi

###############################################################################
# Python venv (isolated environment). Will be cleaned up later.
# This is better than polluting the system Python or using pipx. We risk breaking stuff otherwise.
###############################################################################
VENV_DIR="$IOS_DIR/.venv-as"
VENV_PY="$VENV_DIR/bin/python"
VENV_PIP="$VENV_DIR/bin/pip"

if [[ ! -d "$VENV_DIR" ]]; then
  log "Creating Python venv at $VENV_DIR..."
  python3 -m venv "$VENV_DIR"
fi

log "Activating Python venv..."
source "$VENV_DIR/bin/activate"

log "Upgrading pip and installing essentials..."
"$VENV_PIP" install --upgrade pip setuptools wheel six

###############################################################################
# gyp (needed for building some native dependencies)
# We clone it locally instead of using pipx or system-wide install to avoid breaking other stuff
###############################################################################
GYP_DIR="$HOME/tools/gyp"
if [[ -d "$GYP_DIR" ]]; then
  log "gyp already present at $GYP_DIR"
else
  log "Cloning gyp into $GYP_DIR..."
  mkdir -p "${GYP_DIR%/*}"
  git clone https://chromium.googlesource.com/external/gyp.git "$GYP_DIR"
fi

log "Installing gyp into venv..."
"$VENV_PIP" install --upgrade "$GYP_DIR"
"$VENV_PIP" install --upgrade six
export PATH="$GYP_DIR:$VENV_DIR/bin:$HOME/.local/bin:$PATH"

###############################################################################
# Rust (rustup + stable toolchain)
###############################################################################
log "Ensuring rustup and stable toolchain..."
if ! have_cmd rustup; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

if [[ -f "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi

if ! rustup toolchain list | grep -q '^stable'; then
  log "Installing Rust stable toolchain..."
  rustup toolchain install stable --profile default
else
  log "Rust stable toolchain already installed"
fi


###############################################################################
# NSS platform setup
# This is needed to point AS to the right NSS build for the current platform.
###############################################################################
if [[ "$(uname -s)" == "Darwin" ]]; then
  if [[ "$(uname -m)" == "arm64" ]]; then
    export NSS_DIR="$AS_DIR/libs/desktop/darwin-aarch64"
  else
    export NSS_DIR="$AS_DIR/libs/desktop/darwin-x86-64"
  fi
else
  export NSS_DIR="$AS_DIR/libs/desktop/linux-x86-64"
fi
export NSS_STATIC=1
log "Using NSS_DIR=$NSS_DIR"
log "Using NSS_STATIC=$NSS_STATIC"

###############################################################################
# Verify and build Application Services for iOS
###############################################################################

# Switch to AS dir because some scripts expect to be run from there
log "Switching to application-services dir: $AS_DIR"
cd "$AS_DIR"

VERIFY_SCRIPT="$AS_DIR/libs/verify-ios-environment.sh"
BUILD_SCRIPT="$AS_DIR/megazords/ios-rust/build-xcframework.sh"

if [[ ! -x "$VERIFY_SCRIPT" ]]; then
  err "Missing verify script at $VERIFY_SCRIPT"
  exit 1
fi
if [[ ! -x "$BUILD_SCRIPT" ]]; then
  err "Missing build script at $BUILD_SCRIPT"
  exit 1
fi

log "Verifying Application Services iOS build environment..."
"$VERIFY_SCRIPT"

log "Building Application Services iOS artifacts..."
"$BUILD_SCRIPT" --generate-swift-sources

# Delete and deactivate python venv
log "Deactivating Python venv..."
deactivate || true
log "Deleting Python venv at $VENV_DIR..."
rm -rf "$VENV_DIR"

# Switch to back to firefox-ios dir
log "Switching back to firefox-ios dir: $IOS_DIR"
cd "$IOS_DIR"


###############################################################################
# Copy built artifacts into firefox-ios
###############################################################################
MEGAZORDS_DIR="$AS_DIR/megazords/ios-rust"
XCFRAMEWORK_ZIP="$MEGAZORDS_DIR/MozillaRustComponents.xcframework.zip"
GENERATED_SRC="$MEGAZORDS_DIR/Sources/MozillaRustComponentsWrapper/Generated/"
GENERATED_DST="$IOS_DIR/MozillaRustComponents/Sources/MozillaRustComponentsWrapper/Generated/"
PKG_FILE="$IOS_DIR/MozillaRustComponents/Package.swift"

if [[ ! -f "$XCFRAMEWORK_ZIP" ]]; then
  err "Expected xcframework zip not found: $XCFRAMEWORK_ZIP"
  exit 1
fi

log "Unzipping xcframework into firefox-ios/MozillaRustComponents/..."
unzip -oq "$XCFRAMEWORK_ZIP" -d "$IOS_DIR/MozillaRustComponents/"

log "Copying generated Swift wrappers into project..."
rsync -avm --include='*/' --include='*.swift' --exclude='*' "$GENERATED_SRC/" "$GENERATED_DST/"

###############################################################################
# Switch SPM binaryTarget to use the local xcframework instead of remote URL
###############################################################################
if [[ ! -f "$PKG_FILE" ]]; then
  err "Package.swift not found at $PKG_FILE"
  exit 1
fi

log "Rewriting Package.swift to point MozillaRustComponents to local path..."
perl -pi -e '
  if (/\.binaryTarget\(/ .. /\),/) {
    $inblock .= $_;
    if (/name:\s*"MozillaRustComponents"/) { $flag=1 }
    if (/\),/) {
      if ($flag) {
        $inblock =~ s|^(\s*)url:|\1//url:|mg;
        $inblock =~ s|^(\s*)checksum:|\1//checksum:|mg;
        $inblock =~ s|^(\s*)//path:|\1path:|mg;
      }
      $_=$inblock; $inblock=""; $flag=0;
    } else { $_=""; }
  }
' "$PKG_FILE"

log "All done! Open Xcode and build Firefox iOS 🎉"