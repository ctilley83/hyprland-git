#!/bin/bash
# CachyOS Optimized Hyprland Rebuild Script
# Usage: ./install.sh --rebuild | --rebuild-only <components>
# Fully integrated with CachyOS toolchain (gcc-cachyos, v3 optimizations)

set -e
rebuild=false
rebuild_only=("Dependencies")

check_and_clone_repo() {
    local dir="$1"
    local repo="$2"
    [ -d "$dir" ] || git clone "$repo" "$dir"
}

Dependencies() {
    echo "[INFO] Installing dependencies for CachyOS..."
    sudo pacman -Syu --noconfirm
    sudo pacman -S --needed --noconfirm gcc-cachyos cmake meson ninja git \
        qt6-base qt6-declarative qt6-svg qt6-tools \
        wayland-protocols libx11 libxcomposite libxrender xcb-util \
        xcb-util-keysyms xcb-util-wm xcb-util-errors cairo pango \
        libxkbcommon seatd libinput libliftoff libdisplay-info \
        polkit-qt6 libzip tomlplusplus cpio
}

build_cmake() {
    local build_dir="build"
    [ -d "$build_dir" ] && rm -rf "$build_dir"
    git clean -fdX
    cmake -B "$build_dir" -S . -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
    cmake --build "$build_dir" --parallel
    sudo cmake --install "$build_dir"
}

build_meson() {
    local build_dir="build"
    [ -d "$build_dir" ] && rm -rf "$build_dir"
    git clean -fdX
    meson setup "$build_dir"
    ninja -C "$build_dir"
    sudo ninja -C "$build_dir" install
}

process_repo() {
    local name="$1"
    local repo="$2"
    local build_sys="$3"

    check_and_clone_repo "$name" "$repo"
    cd "$name"
    git pull

    [ "$rebuild" = false ] && [ -d build ] && echo "[SKIP] $name is current." && cd .. && return

    case "$build_sys" in
        cmake) build_cmake;;
        meson) build_meson;;
        make)
            git clean -fdX
            make -j"$(nproc)" && sudo make install
        ;;
    esac

    cd ..
}

sdbus_cpp() {
    process_repo sdbus-cpp https://github.com/Kistler-Group/sdbus-cpp.git cmake
}
hyprutils() {
    process_repo hyprutils https://github.com/hyprwm/hyprutils.git cmake
}
hyprgraphics() {
    process_repo hyprgraphics https://github.com/hyprwm/hyprgraphics.git cmake
}
aquamarine() {
    process_repo aquamarine https://github.com/hyprwm/aquamarine.git cmake
}
hyprcursor() {
    process_repo hyprcursor https://github.com/hyprwm/hyprcursor.git cmake
}
hyprlang() {
    process_repo hyprlang https://github.com/hyprwm/hyprlang.git cmake
}
hyprwayland_scanner() {
    process_repo hyprwayland-scanner https://github.com/hyprwm/hyprwayland-scanner.git cmake
}
hyprland_protocols() {
    process_repo hyprland-protocols https://github.com/hyprwm/hyprland-protocols.git meson
}
hyprqtutils() {
    process_repo hyprland-qtutils https://github.com/hyprwm/hyprland-qtutils.git cmake
}
hyprqt_support() {
    process_repo hyprland-qt-support https://github.com/hyprwm/hyprland-qt-support.git cmake
}
hypridle() {
    process_repo hypridle https://github.com/hyprwm/hypridle.git cmake
}
hyprlock() {
    process_repo hyprlock https://github.com/hyprwm/hyprlock.git cmake
}
hyprpicker() {
    process_repo hyprpicker https://github.com/hyprwm/hyprpicker.git cmake
}
hyprpaper() {
    process_repo hyprpaper https://github.com/hyprwm/hyprpaper.git cmake
}
hyprshot() {
    check_and_clone_repo Hyprshot https://github.com/Gustash/Hyprshot.git
    cd Hyprshot
    git pull
    install -Dm755 hyprshot "$HOME/.local/bin/hyprshot"
    cd ..
}
hyprsysteminfo() {
    process_repo hyprsysteminfo https://github.com/hyprwm/hyprsysteminfo.git cmake
}
hyprpolkitagent() {
    process_repo hyprpolkitagent https://github.com/hyprwm/hyprpolkitagent.git cmake
}
hyprsunset() {
    process_repo hyprsunset https://github.com/hyprwm/hyprsunset.git cmake
}
xdg_portal_hypr() {
    process_repo xdg-desktop-portal-hyprland https://github.com/hyprwm/xdg-desktop-portal-hyprland.git cmake
}
Hyprland() {
    process_repo Hyprland https://github.com/hyprwm/Hyprland.git make
}

# Repo list
repos=(Dependencies sdbus_cpp hyprwayland_scanner hyprland_protocols hyprutils hyprqtutils hyprqt_support aquamarine hyprgraphics hyprlang hyprcursor Hyprland hyprlock hyprpicker hyprpaper hypridle xdg_portal_hypr hyprsysteminfo hyprpolkitagent hyprshot hyprsunset)

# Argument parsing
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --rebuild) rebuild=true;;
        --rebuild-only)
            rebuild=true
            rebuild_only=("$2")
            shift
        ;;
        *) echo "Unknown option: $1"; exit 1;;
    esac
    shift

done

if [ "${#rebuild_only[@]}" -gt 0 ]; then
    for r in "${rebuild_only[@]}"; do "$r"; done
else
    for r in "${repos[@]}"; do "$r"; done
fi

echo "[COMPLETE] Hyprland ecosystem rebuilt with CachyOS toolchain."

