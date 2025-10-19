#!/bin/bash
# Usage examples:
#   ./install.sh
#   ./install.sh --rebuild
#   ./install.sh --rebuild-only Hyprland hyprutils

set -e

# -----------------------------------------------------------------------------
# Global toggles
# -----------------------------------------------------------------------------
rebuild=false
rebuild_only=("Dependencies")

# -----------------------------------------------------------------------------
# Helpers: logging + concurrency
# -----------------------------------------------------------------------------
nprocs() { nproc 2>/dev/null || getconf _NPROCESSORS_CONF || echo 1; }

section() {
  echo
  echo "###############################################"
  printf "# %s #\n" "$1"
  echo "###############################################"
  echo
}

# -----------------------------------------------------------------------------
# Compiler / toolchain setup (prefer GCC → fallback to Clang quietly)
# -----------------------------------------------------------------------------
setup_toolchain() {
  # If the user had CC/CXX pointing at clang, ignore it.
  if command -v "${CC:-}" >/dev/null 2>&1; then
    if "${CC}" --version 2>/dev/null | head -n1 | grep -qi clang; then
      echo "INFO: CC was set to clang; Hyprland repos require GCC. Unsetting CC/CXX."
      unset CC CXX
    fi
  fi

  if ! command -v gcc >/dev/null 2>&1; then
    echo "ERROR: gcc not found on PATH."
    echo "Fix: enable [core] in /etc/pacman.conf and install gcc, e.g.:"
    echo "  sudo pacman -Syu gcc"
    echo "Or (if you insist on yay):"
    echo "  yay -S gcc"
    exit 1
  fi

  export CC=gcc
  export CXX=g++
  echo "Using $(gcc --version | head -n1)"
}

# -----------------------------------------------------------------------------
# Repo utilities
# -----------------------------------------------------------------------------
check_and_clone_repo() {
  local dir_name=$1 git_url=$2
  if [ ! -d "$dir_name" ]; then
    echo "Directory $dir_name not found. Cloning repository..."
    git clone "$git_url" "$dir_name"
  else
    echo "Directory $dir_name already exists. Skipping clone."
  fi
}

# Returns 0 (true) if we should build, 1 (false) if we can skip
# Usage: should_build <dir>
should_build() {
  local dir="$1"
  cd "$dir"
  local output
  output=$(git pull)
  if [ "$rebuild" = false ] && [[ "$output" == *"Already up to date."* && -d "build" ]]; then
    echo "Repository is already up to date and has a build dir. Skipping."
    cd - >/dev/null
    return 1
  fi
  cd - >/dev/null
  return 0
}

git_clean_and_reset_build() {
  local dir="$1"
  cd "$dir"
  if [ -d build ]; then
    echo "Found existing build directory, reconfiguring..."
    rm -rf build
  fi
  git clean -fdX
  cd - >/dev/null
}

# -----------------------------------------------------------------------------
# Build systems
# -----------------------------------------------------------------------------
cmake_build_install() {
  # Args: <dir> [cmake_args] [target]
  local dir="$1"
  local cmake_args="$2"
  local target="${3:-all}"
  cd "$dir"
  cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_C_COMPILER="${CC:-gcc}" \
    -DCMAKE_CXX_COMPILER="${CXX:-g++}" \
    ${cmake_args}
  cmake --build build --config Release --target "${target}" -j"$(nprocs)"
  sudo cmake --install build
  cd - >/dev/null
}

meson_build_install() {
  # Args: <dir> [meson_args]
  local dir="$1"
  local meson_args="$2"
  cd "$dir"
  meson setup build ${meson_args}
  ninja -C build
  sudo ninja -C build install
  cd - >/dev/null
}

make_build_install() {
  # Args: <dir> [make_targets] [install_targets]
  local dir="$1"
  local make_targets="${2:-all}"
  local install_targets="${3:-install}"
  cd "$dir"
  make ${make_targets} -j"$(nprocs)"
  sudo make ${install_targets}
  cd - >/dev/null
}

# -----------------------------------------------------------------------------
# Dependencies
# -----------------------------------------------------------------------------
Dependencies() {
  local distro_id
  distro_id=$(lsb_release -si || echo Unknown)

  section "Installing required dependencies..."

  if [ "$distro_id" = "EndeavourOS" ] || [ "$distro_id" = "Arch" ]; then
    section "Building for EndeavourOS or Arch..."
    yay -S --needed --noconfirm --sudoloop \
      gdb ninja gcc glaze cmake meson qt6 libzip polkit-qt6 \
      libxcb xcb-proto xcb-util xcb-util-keysyms libxfixes libx11 \
      libxcomposite pugixml xorg-xinput libxrender pixman wayland-protocols \
      cairo pango seatd libxkbcommon xcb-util-wm xorg-xwayland libinput \
      libliftoff libdisplay-info cpio tomlplusplus xcb-util-errors
  fi

  if [ "$distro_id" = "openSUSE" ]; then
    section "Building for openSUSE Tumbleweed..."
    sudo zypper dup --non-interactive --no-recommends
    sudo zypper install --non-interactive --no-recommends \
      gcc-c++ ninja file-devel git meson cmake pugixml-devel librsvg-devel \
      libzip-devel xcb-util-devel \
      "pkgconfig(cairo)" "pkgconfig(egl)" "pkgconfig(gbm)" \
      "pkgconfig(gl)" "pkgconfig(glesv2)" "pkgconfig(libdrm)" \
      "pkgconfig(libinput)" "pkgconfig(libseat)" "pkgconfig(libudev)" \
      "pkgconfig(pango)" "pkgconfig(pangocairo)" "pkgconfig(pixman-1)" \
      "pkgconfig(vulkan)" "pkgconfig(wayland-client)" "pkgconfig(wayland-protocols)" \
      "pkgconfig(wayland-scanner)" "pkgconfig(wayland-server)" "pkgconfig(xcb)" \
      "pkgconfig(xcb-icccm)" "pkgconfig(xcb-renderutil)" "pkgconfig(xkbcommon)" \
      "pkgconfig(xwayland)" "pkgconfig(xcb-errors)" \
      glslang-devel Mesa-libGLESv3-devel tomlplusplus-devel
  fi

  if [ "$distro_id" = "Ubuntu" ]; then
    section "Building for Ubuntu..."
    sudo apt-get install -y \
      meson wget build-essential ninja-build cmake-extras cmake gettext gettext-base \
      fontconfig libfontconfig-dev libffi-dev libxml2-dev libdrm-dev \
      libxkbcommon-x11-dev libxkbregistry-dev libxkbcommon-dev libpixman-1-dev \
      libudev-dev libseat-dev seatd libxcb-dri3-dev libegl-dev libgles2 \
      libegl1-mesa-dev glslang-tools libinput-bin libinput-dev libxcb-composite0-dev \
      libavutil-dev libavcodec-dev libavformat-dev libxcb-ewmh2 libxcb-ewmh-dev \
      libxcb-present-dev libxcb-icccm4-dev libxcb-render-util0-dev libxcb-res0-dev \
      libxcb-xinput-dev libtomlplusplus3
  fi
}

# -----------------------------------------------------------------------------
# Per-repo wrappers (now tiny) — adjust only where a repo needs special args
# -----------------------------------------------------------------------------
hyprutils() {
  local name="hyprutils" url="https://github.com/hyprwm/hyprutils.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name"
}

hyprland-protocols() {
  local name="hyprland-protocols" url="https://github.com/hyprwm/hyprland-protocols.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  ( cd "$name" && git clean -fdX && meson subprojects update --reset )
  git_clean_and_reset_build "$name"
  meson_build_install "$name"
}

hyprland-qtutils() {
  local name="hyprland-qtutils" url="https://github.com/hyprwm/hyprland-qtutils.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name"
}

hyprland-qt-support() {
  local name="hyprland-qt-support" url="https://github.com/hyprwm/hyprland-qt-support.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name" "-DINSTALL_QML_PREFIX=/lib/qt6/qml"
}

hyprqt6engine(){
  local name="hyprqt6engine" url="https://github.com/hyprwm/hyprqt6engine.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name"
}

hyprwayland-scanner() {
  local name="hyprwayland-scanner" url="https://github.com/hyprwm/hyprwayland-scanner.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name"
}

aquamarine() {
  local name="aquamarine" url="https://github.com/hyprwm/aquamarine.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name"
}

hyprlang() {
  local name="hyprlang" url="https://github.com/hyprwm/hyprlang.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name"
}

hyprcursor() {
  local name="hyprcursor" url="https://github.com/hyprwm/hyprcursor.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name"
}

Hyprshot() {
  local name="Hyprshot" url="https://github.com/Gustash/Hyprshot.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  # Hyprshot is just a script; still pull for updates
  ( cd "$name" && git pull >/dev/null )
  mkdir -p "$HOME/.local/bin"
  echo "Copying Hyprshot to ~/.local/bin"
  cp -i "$(pwd)/$name/hyprshot" "$HOME/.local/bin/hyprshot"
  echo "Changing permissions to executable"
  chmod +x "$HOME/.local/bin/hyprshot"
  echo "Successfully installed Hyprshot"
}

hyprgraphics() {
  local name="hyprgraphics" url="https://github.com/hyprwm/hyprgraphics.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name"
}

Hyprland() {
  local name="Hyprland" url="https://github.com/hyprwm/Hyprland.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  ( cd "$name" && git submodule update --init && git clean -fdX )
  # Hyprland uses a Makefile
  make_build_install "$name" "all" "install"
}

hypridle() {
  local name="hypridle" url="https://github.com/hyprwm/hypridle.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name"
}


hyprlock() {
  local name="hyprlock" url="https://github.com/hyprwm/hyprlock.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name"
}

hyprpicker() {
  local name="hyprpicker" url="https://github.com/hyprwm/hyprpicker.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name"
}

hyprpolkitagent() {
  local name="hyprpolkitagent" url="https://github.com/hyprwm/hyprpolkitagent.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name"
}

hyprpaper() {
  local name="hyprpaper" url="https://github.com/hyprwm/hyprpaper.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name"
}

hyprtoolkit() {
  local name="hyprtoolkit" url="https://github.com/hyprwm/hyprtoolkit.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name"
}
hyprwire() {
  local name="hyprwire" url="https://github.com/hyprwm/hyprwire.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name"
}
hyprpwcenter() {
  local name="hyprpwcenter" url="https://github.com/hyprwm/hyprpwcenter.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name"
}
hyprlauncher() {
  local name="hyprlauncher" url="https://github.com/hyprwm/hyprlauncher.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name"
}
hyprsunset() {
  local name="hyprsunset" url="https://github.com/hyprwm/hyprsunset.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name"
}

xdg-desktop-portal-hyprland() {
  local name="xdg-desktop-portal-hyprland" url="https://github.com/hyprwm/xdg-desktop-portal-hyprland.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name" "-DCMAKE_INSTALL_LIBEXECDIR=/usr/lib"
}

hyprsysteminfo() {
  local name="hyprsysteminfo" url="https://github.com/hyprwm/hyprsysteminfo.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  # Building 'all' is fine; if you want the exact target, pass "hyprsysteminfo" as target 3rd arg
  cmake_build_install "$name"
}

hyprqt6engine() {
  local name="hyprqt6engine" url="https://github.com/hyprwm/hyprqt6engine.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  cmake_build_install "$name" "--no-warn-unused-cli"
}

sdbus-cpp() {
  local name="sdbus-cpp" url="https://github.com/Kistler-Group/sdbus-cpp.git"
  check_and_clone_repo "$name" "$url"
  section "Processing repository: $name"
  if ! should_build "$name"; then return; fi
  git_clean_and_reset_build "$name"
  # This project prefers out-of-source 'build' with "cmake .."
  cd "$name"
  cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
  cmake --build build -j"$(nprocs)"
  sudo cmake --build build --target install
  cd - >/dev/null

  # Shell config hints (kept from your original)
  if [[ "$SHELL" == */bash ]]; then
    grep -qxF 'export CMAKE_PREFIX_PATH="/usr/local:$CMAKE_PREFIX_PATH"' ~/.bashrc || echo 'export CMAKE_PREFIX_PATH="/usr/local:$CMAKE_PREFIX_PATH"' >>~/.bashrc
    grep -qxF 'export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"' ~/.bashrc || echo 'export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"' >>~/.bashrc
  elif [[ "$SHELL" == */zsh ]]; then
    grep -qxF 'export CMAKE_PREFIX_PATH="/usr/local:$CMAKE_PREFIX_PATH"' ~/.zshrc || echo 'export CMAKE_PREFIX_PATH="/usr/local:$CMAKE_PREFIX_PATH"' >>~/.zshrc
    grep -qxF 'export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"' ~/.zshrc || echo 'export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"' >>~/.zshrc
  elif [[ "$SHELL" == */fish ]]; then
    grep -qxF 'set -x CMAKE_PREFIX_PATH "/usr/local:$CMAKE_PREFIX_PATH"' ~/.config/fish/config.fish || echo 'set -x CMAKE_PREFIX_PATH "/usr/local:$CMAKE_PREFIX_PATH"' >>~/.config/fish/config.fish
    grep -qxF 'set -x LD_LIBRARY_PATH "/usr/local/lib:$LD_LIBRARY_PATH"' ~/.config/fish/config.fish || echo 'set -x LD_LIBRARY_PATH "/usr/local/lib:$LD_LIBRARY_PATH"' >>~/.config/fish/config.fish
  else
    echo "Unsupported shell: $SHELL"
  fi

  export CMAKE_PREFIX_PATH="/usr/local:$CMAKE_PREFIX_PATH"
  export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
}

# -----------------------------------------------------------------------------
# Repo execution list
# -----------------------------------------------------------------------------
repos=(
  "Dependencies"
  "sdbus-cpp"
  "hyprwayland-scanner"
  "hyprland-protocols"
  "hyprlang"
  "hyprutils"
  "hyprland-qtutils"
  "hyprland-qt-support"
  "hyprqt6engine"
  "aquamarine"
  "hyprgraphics"
  "hyprcursor"
  "Hyprland"
  "hyprlock"
  "hyprpicker"
  "hyprpaper"
  "hypridle"
  "xdg-desktop-portal-hyprland"
  "hyprsysteminfo"
  "hyprpolkitagent"
  "Hyprshot"
  "hyprsunset"
  "hyprqt6engine"
  "hyprtoolkit"
  "hyprwire"
  "hyprpwcenter"
  "hyprlauncher"
)

# -----------------------------------------------------------------------------
# CLI parsing
# -----------------------------------------------------------------------------
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --rebuild)
      rebuild=true; shift ;;
    --rebuild-only)
      rebuild=true; shift
      while [[ "$#" -gt 0 && ! "$1" =~ ^-- ]]; do
        rebuild_only+=("$1")
        shift
      done ;;
    *)
      echo "Unknown option: $1"; exit 1 ;;
  esac
done

# -----------------------------------------------------------------------------
# Run
# -----------------------------------------------------------------------------
setup_toolchain

if [[ ${#rebuild_only[@]} -gt 1 ]]; then
  for repo_function in "${rebuild_only[@]}"; do
    if declare -F "$repo_function" >/dev/null; then
      "$repo_function"
    else
      echo "Repository function '$repo_function' not found!"; exit 1
    fi
  done
else
  for repo_function in "${repos[@]}"; do
    "$repo_function"
  done
fi

echo "########################################################################"
echo "# All repositories have been pulled, built, and installed successfully #"
echo "########################################################################"

