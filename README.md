# hyprland-git
This is a script that automates the installation and updating of git versions of the entire hyprland ecosystem. Currently the script works with EndeavourOS/Arch, openSUSE Tumbleweed, and Ubuntu. Fedora coming soon.

# To Install
clone the repository:

```git clone https://github.com/ctilley83/hyprland-git.git```

```cd hyprland-git```

```chmod +x install.sh```

For initial installation and updating simply run:

```./install.sh```

To install or rebuild all packages pass the --rebuild flag

```./install.sh --rebuild```

To install or rebuild select packages pass the --rebuild_only flag. For ex:

``` ./install.sh --rebuild_only "Hyprland" "aquamarine" "hyprutils"```

