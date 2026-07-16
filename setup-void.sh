#!/bin/sh
set -eu

if [ "$(id -u)" -eq 0 ]; then
    cat >&2 <<'EOF'
Do not run setup-void.sh as root or with sudo.

Run it as the desktop user instead:
    ./setup-void.sh --all

The script requests doas/sudo only for XBPS and runit operations. Running the
whole script as root would deploy the dotfiles and backups under /root.
EOF
    exit 1
fi

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
do_install=false
do_services=false
do_deploy=false

usage() {
    cat <<'EOF'
Usage: ./setup-void.sh [options]

  --install-packages  Install dependencies available to XBPS.
  --enable-services   Enable dbus, NetworkManager, and bluetoothd.
  --deploy            Back up existing matching configs and install these dots.
  --all               Perform all three actions.
  -h, --help          Show this help.

Hyprland is not in Void's official repository. Configure the repository shown
in the README before using --install-packages if Hyprland is not installed.
EOF
}

run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v doas >/dev/null 2>&1; then
        doas "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        printf 'Install doas or sudo, or run this action as root.\n' >&2
        exit 1
    fi
}

install_package_set() {
    set_name=$1
    shift
    available=""

    for package do
        if xbps-query -Rs "^$package-[0-9]" 2>/dev/null | grep -q .; then
            available="$available $package"
        else
            printf 'Skipping unavailable %s: %s\n' "$set_name" "$package" >&2
        fi
    done

    if [ -n "$available" ]; then
        # Word splitting is intentional: XBPS accepts one package per word.
        # shellcheck disable=SC2086
        run_as_root xbps-install -y $available
    else
        printf 'No %ss were found in the configured repositories.\n' "$set_name" >&2
    fi
}
install_packages() {
    command -v xbps-install >/dev/null 2>&1 || {
        printf 'xbps-install not found; this script must run on Void Linux.\n' >&2
        exit 1
    }

    official_packages="
        awww matugen Waybar rofi SwayNotificationCenter wlogout
        foot kitty nautilus NetworkManager network-manager-applet
        bluez blueman dbus elogind polkit
        pipewire wireplumber alsa-pipewire libspa-bluetooth pavucontrol
        brightnessctl grim slurp wl-clipboard playerctl libnotify jq
        fastfetch cava btop nvtop yazi zsh util-linux xdg-utils
        nerd-fonts noto-fonts-emoji
        xdg-desktop-portal-gtk
    "

    hypr_packages="
        hyprland hyprland-guiutils hypridle hyprlock hyprpicker
        hyprpolkitagent xdg-desktop-portal-hyprland
    "

    run_as_root xbps-install -S
    # Word splitting is intentional when passing each list into the helper.
    # shellcheck disable=SC2086
    install_package_set "official dependency" $official_packages
    # shellcheck disable=SC2086
    install_package_set "Hyprland package" $hypr_packages
}

enable_services() {
    for service in dbus NetworkManager bluetoothd; do
        if [ ! -d "/etc/sv/$service" ]; then
            printf 'Service directory not installed, skipping: %s\n' "$service" >&2
            continue
        fi
        if [ -e "/var/service/$service" ] || [ -L "/var/service/$service" ]; then
            printf 'Already enabled: %s\n' "$service"
            continue
        fi
        run_as_root ln -s "/etc/sv/$service" "/var/service/$service"
        printf 'Enabled: %s\n' "$service"
    done
}

create_relative_symlink() {
    directory=$1
    target=$2
    link_name=$3
    link_path="$directory/$link_name"

    [ -d "$directory" ] || {
        printf 'Cannot create link; directory is missing: %s\n' "$directory" >&2
        return 1
    }

    [ -e "$directory/$target" ] || {
        printf 'Cannot create link; target is missing: %s/%s\n' "$directory" "$target" >&2
        return 1
    }

    if [ -d "$link_path" ] && [ ! -L "$link_path" ]; then
        printf 'Refusing to replace a real directory with a link: %s\n' "$link_path" >&2
        return 1
    fi

    rm -f "$link_path"
    (
        cd "$directory"
        ln -s "$target" "$link_name"
    )

    [ -L "$link_path" ] && [ -e "$link_path" ] && [ "$(readlink "$link_path")" = "$target" ] || {
        printf 'Failed to create symbolic link: %s -> %s\n' "$link_path" "$target" >&2
        return 1
    }
    printf 'Linked: %s -> %s\n' "$link_path" "$target"
}

deploy() {
    timestamp=$(date +'%Y%m%d-%H%M%S')
    state_home=${XDG_STATE_HOME:-"$HOME/.local/state"}
    backup="$state_home/void-hyprland/backups/$timestamp"
    mkdir -p "$HOME/.config" "$backup/.config"

    for source in "$repo_dir"/.config/*; do
        [ -e "$source" ] || continue
        name=${source##*/}
        target="$HOME/.config/$name"

        if [ -e "$target" ] || [ -L "$target" ]; then
            mv "$target" "$backup/.config/$name"
        fi
        cp -a "$source" "$target"
    done

    if [ -e "$HOME/.zshrc" ] || [ -L "$HOME/.zshrc" ]; then
        mv "$HOME/.zshrc" "$backup/.zshrc"
    fi
    cp -a "$repo_dir/.zshrc" "$HOME/.zshrc"

    mkdir -p "$HOME/Pictures" "$backup/Pictures"
    wallpaper_target="$HOME/Pictures/wallpapers"
    if [ -e "$wallpaper_target" ] || [ -L "$wallpaper_target" ]; then
        mv "$wallpaper_target" "$backup/Pictures/wallpapers"
    fi
    cp -a "$repo_dir/wallpapers" "$wallpaper_target"
    [ -d "$wallpaper_target" ] || {
        printf 'Failed to deploy wallpapers: %s\n' "$wallpaper_target" >&2
        exit 1
    }

    waybar_home="$HOME/.config/waybar"
    create_relative_symlink "$waybar_home" "configs/[TOP] 0-Ja-0 Been modified" "config"
    create_relative_symlink "$waybar_home" "style/islands.css" "style.css"

    chmod +x "$HOME"/.config/hypr/scripts/*.sh

    mkdir -p "$HOME/.config/pipewire/pipewire.conf.d"
    if [ -e /usr/share/examples/wireplumber/10-wireplumber.conf ]; then
        ln -sfn /usr/share/examples/wireplumber/10-wireplumber.conf             "$HOME/.config/pipewire/pipewire.conf.d/10-wireplumber.conf"
    fi
    if [ -e /usr/share/examples/pipewire/20-pipewire-pulse.conf ]; then
        ln -sfn /usr/share/examples/pipewire/20-pipewire-pulse.conf             "$HOME/.config/pipewire/pipewire.conf.d/20-pipewire-pulse.conf"
    fi

    printf 'Dotfiles installed. Backup: %s\n' "$backup"
    printf 'Edit ~/.config/hypr/configs/monitors.lua before starting Hyprland.\n'
}

[ "$#" -gt 0 ] || {
    usage
    exit 0
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --install-packages) do_install=true ;;
        --enable-services) do_services=true ;;
        --deploy) do_deploy=true ;;
        --all)
            do_install=true
            do_services=true
            do_deploy=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

if [ "$do_install" = true ]; then
    install_packages
fi
if [ "$do_services" = true ]; then
    enable_services
fi
if [ "$do_deploy" = true ]; then
    deploy
fi
