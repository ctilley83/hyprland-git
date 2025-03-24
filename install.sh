#!/bin/bash
# Outputs to logfile and the screen ./install.sh --rebuild 2>&1 | tee -a install.log
rebuild=false
rebuild_only=("Dependencies")
# Exit script on any error
set -e

check_and_clone_repo() {
    local dir_name=$1
    local git_url=$2

    if [ ! -d "$dir_name" ]; then
        echo "Directory $dir_name not found. Cloning repository..."
        git clone "$git_url"
    else
        echo "Directory $dir_name already exists. Skipping clone."
    fi
}

# Function to install dependencies on Arch
Dependencies() {
    distro_id=$(lsb_release -si)
    echo
    echo "#######################################"
    echo "# Installing required dependencies... #"
    echo "#######################################"
    echo

    if [ "$distro_id" = "EndeavourOS" ] || [ "$distro_id" = "Arch" ]; then
        echo "######################################"
        echo "# Building for EndeavorOS or Arch... #"
        echo "######################################"
        echo

        
        paru -S --needed --noconfirm --sudoloop gdb ninja gcc glaze cmake meson qt6 libzip polkit-qt6 libxcb xcb-proto xcb-util xcb-util-keysyms libxfixes libx11 libxcomposite pugixml xorg-xinput libxrender pixman wayland-protocols cairo pango seatd libxkbcommon xcb-util-wm xorg-xwayland libinput libliftoff libdisplay-info cpio tomlplusplus xcb-util-errors
    fi

    if [ "$distro_id" = "openSUSE" ]; then
        echo "#######################################"
        echo "# Building for openSUSE Tumbleweed... #"
        echo "#######################################"
        echo

        sudo zypper dup --non-interactive --no-recommends
        sudo zypper install --non-interactive --no-recommends gcc-c++ ninja file-devel git meson cmake pugixml-devel librsvg-devel libzip-devel xcb-util-devel "pkgconfig(cairo)" "pkgconfig(egl)" "pkgconfig(gbm)" "pkgconfig(gl)" "pkgconfig(glesv2)" "pkgconfig(libdrm)" "pkgconfig(libinput)" "pkgconfig(libseat)" "pkgconfig(libudev)" "pkgconfig(pango)" "pkgconfig(pangocairo)" "pkgconfig(pixman-1)" "pkgconfig(vulkan)" "pkgconfig(wayland-client)" "pkgconfig(wayland-protocols)" "pkgconfig(wayland-scanner)" "pkgconfig(wayland-server)" "pkgconfig(xcb)" "pkgconfig(xcb-icccm)" "pkgconfig(xcb-renderutil)" "pkgconfig(xkbcommon)" "pkgconfig(xwayland)" "pkgconfig(xcb-errors)" glslang-devel Mesa-libGLESv3-devel tomlplusplus-devel
    fi
    if [ "$distro_id" = "Ubuntu" ]; then
        echo "###########################"
        echo "# Building for Ubuntu...  #"
        echo "###########################"
        echo

        sudo apt-get install -y meson wget build-essential ninja-build cmake-extras cmake gettext gettext-base fontconfig libfontconfig-dev libffi-dev libxml2-dev libdrm-dev libxkbcommon-x11-dev libxkbregistry-dev libxkbcommon-dev libpixman-1-dev libudev-dev libseat-dev seatd libxcb-dri3-dev libegl-dev libgles2 libegl1-mesa-dev glslang-tools libinput-bin libinput-dev libxcb-composite0-dev libavutil-dev libavcodec-dev libavformat-dev libxcb-ewmh2 libxcb-ewmh-dev libxcb-present-dev libxcb-icccm4-dev libxcb-render-util0-dev libxcb-res0-dev libxcb-xinput-dev libtomlplusplus3
    fi
}

hyprutils() {
    check_and_clone_repo "hyprutils" "https://github.com/hyprwm/hyprutils.git"
    echo
    echo "#######################################"
    echo "# Processing repository: hyprutils... #"
    echo "#######################################"
    echo
    cd "hyprutils"

    # Pull the latest changes
    output=$(git pull)

    if [ "$rebuild" = false ]; then
        if [[ "$output" == *"Already up to date."* && -d "build" ]]; then
            echo "Repository is already up to date. Skipping build and install."
            cd ..
            return # Exit the function early
        fi
    fi
    # Reconfigure if a build directory exists
    if [ -d "build" ]; then
        echo "Found existing build directory, reconfiguring..."
        rm -rf build
    fi

    # Configure, build, and install
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
    cmake --build ./build --config Release --target all -j"$(nproc 2>/dev/null || getconf _NPROCESSORS_CONF)"
    sudo cmake --install build

    cd ..
}
hyprland-protocols() {
    check_and_clone_repo "hyprland-protocols" "https://github.com/hyprwm/hyprland-protocols.git"
    echo
    echo "################################################"
    echo "# Processing repository: hyprland-protocols... #"
    echo "################################################"
    echo
    cd "hyprland-protocols"

    # Pull the latest changes
    output=$(git pull)

    if [ "$rebuild" = false ]; then
        if [[ "$output" == *"Already up to date."* && -d "build" ]]; then
            echo "Repository is already up to date. Skipping build and install."
            cd ..
            return # Exit the function early
        fi
    fi
    # Reconfigure if a build directory exists
    if [ -d "build" ]; then
        echo "Found existing build directory, reconfiguring..."
        rm -rf build
    fi

    # Configure, build, and install
    meson subprojects update --reset
    meson setup build
    ninja -C build
    sudo ninja -C build install

    cd ..
}
hyprland-qtutils() {
    check_and_clone_repo "hyprland-qtutils" "https://github.com/hyprwm/hyprland-qtutils.git"
    echo
    echo "##############################################"
    echo "# Processing repository: hyprland-qtutils... #"
    echo "##############################################"
    echo
    cd "hyprland-qtutils"

    # Pull the latest changes
    output=$(git pull)

    if [ "$rebuild" = false ]; then
        if [[ "$output" == *"Already up to date."* && -d "build" ]]; then
            echo "Repository is already up to date. Skipping build and install."
            cd ..
            return # Exit the function early
        fi
    fi
    # Reconfigure if a build directory exists
    if [ -d "build" ]; then
        echo "Found existing build directory, reconfiguring..."
        rm -rf build
    fi

    # Configure, build, and install
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
    cmake --build ./build --config Release --target all -j"$(nproc 2>/dev/null || getconf _NPROCESSORS_CONF)"
    sudo cmake --install build

    cd ..
}
hyprland-qt-support() {
    check_and_clone_repo "hyprland-qt-support" "https://github.com/hyprwm/hyprland-qt-support.git"
    echo
    echo "#################################################"
    echo "# Processing repository: hyprland-qt-support... #"
    echo "#################################################"
    echo
    cd "hyprland-qt-support"

    # Pull the latest changes
    output=$(git pull)

    if [ "$rebuild" = false ]; then
        if [[ "$output" == *"Already up to date."* && -d "build" ]]; then
            echo "Repository is already up to date. Skipping build and install."
            cd ..
            return # Exit the function early
        fi
    fi
    # Reconfigure if a build directory exists
    if [ -d "build" ]; then
        echo "Found existing build directory, reconfiguring..."
        rm -rf build
    fi

    # Configure, build, and install
  	cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -DINSTALL_QML_PREFIX=/lib/qt6/qml -S . -B ./build
	cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF`
    	sudo cmake --install build

    cd ..
}
hyprwayland-scanner() {
    echo
    echo "#################################################"
    echo "# Processing repository: hyprwayland-scanner... #"
    echo "#################################################"
    echo

    check_and_clone_repo "hyprwayland-scanner" "https://github.com/hyprwm/hyprwayland-scanner.git"

    cd "hyprwayland-scanner"

    output=$(git pull)

    if [ "$rebuild" = false ]; then
        if [[ "$output" == *"Already up to date."* && -d "build" ]]; then
            echo "Repository is already up to date. Skipping build and install."
            cd ..
            return # Exit the function early
        fi
    fi

    if [ -d "build" ]; then
        echo "Guess, what? there's an existing build directory, reconfiguring"
        rm -rf build
    fi

    cmake -DCMAKE_INSTALL_PREFIX=/usr -B build
    cmake --build build -j "$(nproc)"
    sudo cmake --install build

    cd ..

}

# Function to pull, build, and install aquamarine
aquamarine() {
    echo
    echo "########################################"
    echo "# Processing repository: aquamarine... #"
    echo "########################################"
    echo

    check_and_clone_repo "aquamarine" "https://github.com/hyprwm/aquamarine.git"

    cd "aquamarine"

    # Pull the latest changes
    output=$(git pull)

    if [ "$rebuild" = false ]; then
        if [[ "$output" == *"Already up to date."* && -d "build" ]]; then
            echo "Repository is already up to date. Skipping build and install."
            cd ..
            return # Exit the function early
        fi
    fi
    # Reconfigure if a build directory exists
    if [ -d "build" ]; then
        echo "Found existing build directory, reconfiguring..."
        rm -rf build
    fi

    # Configure, build, and install
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
    cmake --build ./build --config Release --target all -j"$(nproc 2>/dev/null || getconf _NPROCESSORS_CONF)"
    sudo cmake --install ./build

    cd ..
}

# Function to pull, build, and install hyprlang
hyprlang() {
    echo
    echo "######################################"
    echo "# Processing repository: hyprlang... #"
    echo "######################################"
    echo

    check_and_clone_repo "hyprlang" "https://github.com/hyprwm/hyprlang.git"

    cd "hyprlang"

    # Pull the latest changes
    output=$(git pull)

    if [ "$rebuild" = false ]; then
        if [[ "$output" == *"Already up to date."* && -d "build" ]]; then
            echo "Repository is already up to date. Skipping build and install."
            cd ..
            return # Exit the function early
        fi
    fi
    # Reconfigure if a build directory exists
    if [ -d "build" ]; then
        echo "Found existing build directory, reconfiguring..."
        rm -rf build
    fi

    # Configure, build, and install
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
    cmake --build ./build --config Release --target all -j"$(nproc 2>/dev/null || getconf _NPROCESSORS_CONF)"
    sudo cmake --install ./build

    cd ..
}

# Function to pull, build, and install hyprcursor
hyprcursor() {
    echo
    echo "########################################"
    echo "# Processing repository: hyprcursor... #"
    echo "########################################"
    echo

    check_and_clone_repo "hyprcursor" "https://github.com/hyprwm/hyprcursor.git"

    cd "hyprcursor"

    # Pull the latest changes
    output=$(git pull)

    if [ "$rebuild" = false ]; then
        if [[ "$output" == *"Already up to date."* && -d "build" ]]; then
            echo "Repository is already up to date. Skipping build and install."
            cd ..
            return # Exit the function early
        fi
    fi
    # Reconfigure if a build directory exists
    if [ -d "build" ]; then
        echo "Found existing build directory, reconfiguring..."
        rm -rf build
    fi

    # Configure, build, and install
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
    cmake --build ./build --config Release --target all -j"$(nproc 2>/dev/null || getconf _NPROCESSORS_CONF)"
    sudo cmake --install ./build

    cd ..
}

Hyprshot() {
    echo
    echo "######################################"
    echo "# Processing repository: hyprshot... #"
    echo "######################################"
    echo

    check_and_clone_repo "Hyprshot" "https://github.com/Gustash/Hyprshot.git"

    cd "Hyprshot"
    output=$(git pull)

    if [ "$rebuild" = false ]; then
        if [[ "$output" == *"Already up to date."* ]]; then
            echo "Repository is already up to date. Skipping build and install."
            cd ..
            return # Exit the function early
        fi
    fi

    cd ..

    # Check if the symbolic link already exists
    echo "Copying Hyprshot to ~/.local/bin"
    cp -i "$(pwd)/Hyprshot/hyprshot" "$HOME/.local/bin/hyprshot"

    echo "Changing permissions to executable"
    chmod +x "$HOME/.local/bin/hyprshot"
    echo "Succesfully installed Hyprshot"
    echo
}

hyprgraphics() {
    echo
    echo "##########################################"
    echo "# Processing repository: hyprgraphics... #"
    echo "##########################################"
    echo

    check_and_clone_repo "hyprgraphics" "https://github.com/hyprwm/hyprgraphics.git"

    cd "hyprgraphics"

    # Pull changes from the repository
    output=$(git pull)

    # Check if rebuild is necessary
    if [ "$rebuild" = false ]; then
        if [[ "$output" == *"Already up to date."* && -d "build" ]]; then
            echo "Repository is already up to date. Skipping build and install."
            cd ..
            return # Exit the function early
        fi
    fi

    # Check if build directory exists, then clean it up
    if [ -d "build" ]; then
        echo "Found existing build directory, cleaning up..."
        rm -rf build
        echo "Build directory removed. Reconfiguring..."
    fi

    # Configure and build the project using CMake
   cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
   echo "You're at the make command"
   cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF`
    # Install the built project
    sudo cmake --install ./build

    # Return to the previous directory
    cd ..
}

Hyprland() {
    echo
    echo "######################################"
    echo "# Processing repository: hyprland... #"
    echo "######################################"
    echo

    check_and_clone_repo "Hyprland" "https://github.com/hyprwm/Hyprland.git"

    cd "Hyprland"
    output=$(git pull)
    echo $output
    if [ "$rebuild" = false ]; then
        if [[ "$output" == *"Already up to date."* && -d "build" ]]; then
            echo "Repository is already up to date. Skipping build and install."
            cd ..
            return # Exit the function early
        fi
    fi

    git submodule update --init

    if [ -d "build" ]; then
        echo "Found existing build directory, reconfiguring...."
        rm -rf build
    fi
    #configure, build, and install

    make all && sudo make install

    cd ..
}

hypridle() {
    echo
    echo "######################################"
    echo "# Processing repository: hypridle... #"
    echo "######################################"
    echo

    check_and_clone_repo "hypridle" "https://github.com/hyprwm/hypridle.git"

    cd "hypridle"
    output=$(git pull)

    if [ "$rebuild" = false ]; then
        if [[ "$output" == *"Already up to date."* && -d "build" ]]; then
            echo "Repository is already up to date. Skipping build and install."
            cd ..
            return # Exit the function early
        fi
    fi

    if [ -d "build" ]; then
        echo "Found existing build directory, reconfiguring...."
        rm -rf build
    fi

    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build
    cmake --build ./build --config Release --target all -j"$(nproc 2>/dev/null || getconf _NPROCESSORS_CONF)"

    sudo cmake --install build

    cd ..
}

hyprlock() {
    echo
    echo "#####################################"
    echo "# Processing repository: hyprlock... "
    echo "#####################################"
    echo

    check_and_clone_repo "hyprlock" "https://github.com/hyprwm/hyprlock.git"

    cd "hyprlock"
    output=$(git pull)

    if [ "$rebuild" = false ]; then
        if [[ "$output" == *"Already up to date."* && -d "build" ]]; then
            echo "Repository is already up to date. Skipping build and install."
            cd ..
            return # Exit the function early
        fi
    fi

    if [ -d "build" ]; then
        echo "Found existing build directory, reconfiguring...."
        rm -rf build
    fi

    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build
    cmake --build ./build --config Release --target all -j"$(nproc 2>/dev/null || getconf _NPROCESSORS_CONF)"

    sudo cmake --install build

    cd ..
}

hyprpicker() {
    echo
    echo "########################################"
    echo "# Processing repository: hyprpicker... #"
    echo "########################################"
    echo

    check_and_clone_repo "hyprpicker" "https://github.com/hyprwm/hyprpicker.git"

    cd "hyprpicker"
    output=$(git pull)

    if [ "$rebuild" = false ]; then
        if [[ "$output" == *"Already up to date."* && -d "build" ]]; then
            echo "Repository is already up to date. Skipping build and install."
            cd ..
            return # Exit the function early
        fi
    fi

    if [ -d "build" ]; then
        echo "Found existing build directory, reconfiguring...."
        rm -rf build
    fi

    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
    cmake --build ./build --config Release --target all -j"$(nproc 2>/dev/null || getconf _NPROCESSORS_CONF)"

    sudo cmake --install ./build

    cd ..
}
hyprpolkitagent() {
    echo
    echo "#############################################"
    echo "# Processing repository: hyprpolkitagent... #"
    echo "#############################################"
    echo

    check_and_clone_repo "hyprpolkitagent" "https://github.com/hyprwm/hyprpolkitagent.git"

    cd "hyprpolkitagent"
    output=$(git pull)

    if [ "$rebuild" = false ]; then
        if [[ "$output" == *"Already up to date."* && -d "build" ]]; then
            echo "Repository is already up to date. Skipping build and install."
            cd ..
            return # Exit the function early
        fi
    fi

    if [ -d "build" ]; then
        echo "Found existing build directory, reconfiguring...."
        rm -rf build
    fi

    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
    cmake --build ./build --config Release --target all -j"$(nproc 2>/dev/null || getconf _NPROCESSORS_CONF)"

    sudo cmake --install ./build

    cd ..
}
hyprpaper() {
    echo
    echo "#######################################"
    echo "# Processing repository: hyprpaper... #"
    echo "#######################################"
    echo

    check_and_clone_repo "hyprpaper" "https://github.com/hyprwm/hyprpaper.git"

    cd "hyprpaper"

    # Pull changes from the repository
    output=$(git pull)

    # Check if rebuild is necessary
    if [ "$rebuild" = false ]; then
        if [[ "$output" == *"Already up to date."* && -d "build" ]]; then
            echo "Repository is already up to date. Skipping build and install."
            cd ..
            return # Exit the function early
        fi
    fi

    # Check if build directory exists, then clean it up
    if [ -d "build" ]; then
        echo "Found existing build directory, cleaning up..."
        rm -rf build
        echo "Build directory removed. Reconfiguring..."
    fi

    # Configure and build the project using CMake
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
    cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF`

    # Install the built project
    sudo cmake --install ./build

    # Return to the previous directory
    cd ..
}
hyprsunset() {
    echo
    echo "#######################################"
    echo "# Processing repository: hyprsunset... #"
    echo "#######################################"
    echo

    check_and_clone_repo "hyprsunset" "https://github.com/hyprwm/hyprsunset.git"

    cd "hyprsunset"

    # Pull changes from the repository
    output=$(git pull)

    # Check if rebuild is necessary
    if [ "$rebuild" = false ]; then
        if [[ "$output" == *"Already up to date."* && -d "build" ]]; then
            echo "Repository is already up to date. Skipping build and install."
            cd ..
            return # Exit the function early
        fi
    fi

    # Check if build directory exists, then clean it up
    if [ -d "build" ]; then
        echo "Found existing build directory, cleaning up..."
        rm -rf build
        echo "Build directory removed. Reconfiguring..."
    fi

    # Configure and build the project using CMake
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
    cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF`

    # Install the built project
    sudo cmake --install ./build

    # Return to the previous directory
    cd ..
}
xdg-desktop-portal-hyprland() {
    echo
    echo "######################################"
    echo "# Processing repository: XDG BLAH... #"
    echo "######################################"
    echo

    check_and_clone_repo "xdg-desktop-portal-hyprland" "https://github.com/hyprwm/xdg-desktop-portal-hyprland.git"

    cd "xdg-desktop-portal-hyprland"
    output=$(git pull)

    if [ "$rebuild" = false ]; then
        if [[ "$output" == *"Already up to date."* && -d "build" ]]; then
            echo "Repository is already up to date. Skipping build and install."
            cd ..
            return # Exit the function early
        fi
    fi

    if [ -d "build" ]; then
        echo "Found existing build directory, reconfiguring...."
        rm -rf build
        echo "Build directory removed. Reconfiguring..."

    fi

    cmake -DCMAKE_INSTALL_LIBEXECDIR=/usr/lib -DCMAKE_INSTALL_PREFIX=/usr -B build
    cmake --build build

    sudo cmake --install build

    cd ..
}

hyprsysteminfo() {

    echo
    echo "############################################"
    echo "# Processing repository: HyprSystemInfo... #"
    echo "############################################"
    echo

    check_and_clone_repo "hyprsysteminfo" "https://github.com/hyprwm/hyprsysteminfo.git"

    cd "hyprsysteminfo"
    output=$(git pull)

    # Check if rebuild is necessary
    if [ "$rebuild" = false ]; then
        if [[ "$output" == *"Already up to date."* && -d "build" ]]; then
            echo "Repository is already up to date. Skipping build and install."
            cd ..
            return # Exit the function early
        fi
    fi

    # Check if build directory exists, then clean it up
    if [ -d "build" ]; then
        echo "Found existing build directory, cleaning up..."
        rm -rf build
        echo "Build directory removed. Reconfiguring..."
    fi

    # Configure and build the project using CMake
    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
    cmake --build ./build --config Release --target hyprsysteminfo -j"$(nproc 2>/dev/null || getconf _NPROCESSORS_CONF)"

    # Install the built project
    sudo cmake --install ./build

    # Return to the previous directory
    cd ..
}

sdbus-cpp() {
    echo
    echo "###########################################"
    echo "# Processing repository: sdbus-cpp 2.0... #"
    echo "###########################################"
    echo

    check_and_clone_repo "sdbus-cpp" "https://github.com/Kistler-Group/sdbus-cpp.git"

    cd "sdbus-cpp"
    output=$(git pull)

    if [ "$rebuild" = false ]; then
        if [[ "$output" == *"Already up to date."* && -d "build" ]]; then
            echo "Repository is already up to date. Skipping build and install."
            cd ..
            return # Exit the function early
        fi
    fi

    if [ -d "build" ]; then
        echo "Found existing build directory, reconfiguring...."
        rm -rf build
    fi

    mkdir build
    cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release ${OTHER_CONFIG_FLAGS}
    cmake --build .
    sudo cmake --build . --target install
    cd ../../

    # Check the user's current shell and append to the appropriate RC file if not already present
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

    # Export variables in the current session
    export CMAKE_PREFIX_PATH="/usr/local:$CMAKE_PREFIX_PATH"
    export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
}

# Array of function names corresponding to each repository
repos=("Dependencies" "sdbus-cpp" "hyprwayland-scanner" "hyprland-protocols" "hyprutils" "hyprland-qtutils" "hyprland-qt-support" "aquamarine" "hyprgraphics" "hyprlang" "hyprcursor" "Hyprland" "hyprlock" "hyprpicker" "hyprpaper" "hypridle" "xdg-desktop-portal-hyprland" "hyprsysteminfo" "hyprpolkitagent" "Hyprshot", "hyprsunset")
# Command-line argument parsing
while [[ "$#" -gt 0 ]]; do
    case "$1" in
    --rebuild)
        rebuild=true
        shift
        ;;
    --rebuild-only)
        rebuild=true
        shift
        while [[ "$#" -gt 0 && ! "$1" =~ ^-- ]]; do
            rebuild_only+=("$1") # Add repository names to the array
            shift
        done
        ;;
    *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

# Execute repositories based on user input

if [[ ${#rebuild_only[@]} -gt 1 ]]; then
    # Rebuild packages with --rebuild-only separated by spaces
    for repo_function in "${rebuild_only[@]}"; do
        if declare -F "$repo_function" >/dev/null; then
            "$repo_function"
        else
            echo "Repository function '$repo_function' not found!"
            exit 1
        fi
    done
else # Build all packages
    for repo_function in "${repos[@]}"; do
        "$repo_function"
    done
fi
echo "########################################################################"
echo "# All repositories have been pulled, built, and installed successfully #"
echo "########################################################################"
