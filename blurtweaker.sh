#!/usr/bin/env bash

EXT_UUID="blur-my-shell@aunetx"
DCONF_PATH="/org/gnome/shell/extensions/blur-my-shell/"
BACKUP_DIR="$HOME/.local/share/blurtweaker"
BACKUP_FILE="$BACKUP_DIR/bms_backup.dconf"
FIX_DCONF_FILE="$HOME/.config/blur-my-shell-pipelines.dconf"
FIX_SCRIPT="$HOME/.local/bin/blur-fix-on-unlock.sh"
FIX_SERVICE="$HOME/.config/systemd/user/blur-fix.service"

# ─── Colors ───────────────────────────────────────────────────────────────────
BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

echo ""
echo -e "${CYAN}${BOLD}  Better Blur Tuner${RESET}"
echo -e "  Makes blur on top bar, dock, overview, folders - more comfortable to read and consistent."
echo ""

# ─── Check GNOME ──────────────────────────────────────────────────────────────
if [[ "$XDG_CURRENT_DESKTOP" != *"GNOME"* ]] && [[ "$DESKTOP_SESSION" != *"gnome"* ]] && [[ "$XDG_SESSION_DESKTOP" != *"gnome"* ]]; then
    echo -e "${RED}  Tuner will only work on GNOME desktop environment.${RESET}"
    echo ""
    read -rp "  Continue anyway? [only do this if you are surely on GNOME] [y/N]: " force_continue
    if [[ ! "$force_continue" =~ ^[Yy]$ ]]; then
        echo ""
        exit 1
    fi
    echo ""
fi

# ─── Check Blur My Shell installed ────────────────────────────────────────────
is_bms_installed() {
    gnome-extensions list 2>/dev/null | grep -q "$EXT_UUID"
}

install_bms() {
    echo ""
    echo -e "${CYAN}  Cloning and installing Blur My Shell...${RESET}"
    TMP_DIR=$(mktemp -d)
    git clone --quiet https://github.com/aunetx/blur-my-shell "$TMP_DIR/blur-my-shell"
    if [ $? -ne 0 ]; then
        echo -e "${RED}  Failed to clone repository. Check your internet connection.${RESET}"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    ( cd "$TMP_DIR/blur-my-shell" && make install )
    if [ $? -ne 0 ]; then
        echo -e "${RED}  Installation failed.${RESET}"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    gnome-extensions enable "$EXT_UUID" 2>/dev/null

    rm -rf "$TMP_DIR"
    echo -e "${GREEN}  Blur My Shell installed and enabled.${RESET}"
    echo ""
}

if ! is_bms_installed; then
    read -rp "  Blur my shell is not installed, do you want to install it? [Y/n]: " install_choice
    if [[ "$install_choice" =~ ^[Yy]$ ]] || [ -z "$install_choice" ]; then
        install_bms
    else
        echo -e "  Exiting."
        echo ""
        exit 0
    fi
fi

# ─── Menu ─────────────────────────────────────────────────────────────────────
echo -e "  ${BOLD}Choose an option:${RESET}"
echo ""
echo -e "  ${CYAN}1)${RESET} Apply BETTER BLUR"
echo -e "  ${CYAN}2)${RESET} Restore your previous blur settings"
echo -e "  ${CYAN}3)${RESET} Reset Blur to extension default"
echo -e "  ${CYAN}4)${RESET} Exit"
echo ""
read -rp "  Enter choice [1-4]: " choice
echo ""

# ─── Backup ───────────────────────────────────────────────────────────────────
do_backup() {
    mkdir -p "$BACKUP_DIR"
    echo -e "  ${YELLOW}Backing up current values to ${BACKUP_DIR}${RESET}"
    dconf dump "$DCONF_PATH" > "$BACKUP_FILE"
    echo -e "  ${GREEN}Backup saved.${RESET}"
    echo ""
}

# ─── Radius reset fix ─────────────────────────────────────────────────────────
apply_unlock_fix() {
    mkdir -p "$(dirname "$FIX_DCONF_FILE")"
    mkdir -p "$(dirname "$FIX_SCRIPT")"
    mkdir -p "$(dirname "$FIX_SERVICE")"

    dconf dump "$DCONF_PATH" > "$FIX_DCONF_FILE"

    cat > "$FIX_SCRIPT" << 'SCRIPT_EOF'
#!/usr/bin/env bash
# Watches for GNOME screen unlock and re-applies blur-my-shell pipelines
# to fix the radius reset bug that occurs on sleep/lock resume.

DCONF_FILE="$HOME/.config/blur-my-shell-pipelines.dconf"

dbus-monitor --session "type='signal',interface='org.gnome.ScreenSaver'" |
while read -r line; do
    if echo "$line" | grep -q "boolean false"; then
        sleep 1
        dconf load /org/gnome/shell/extensions/blur-my-shell/ < "$DCONF_FILE"
    fi
done
SCRIPT_EOF
    chmod +x "$FIX_SCRIPT"

    cat > "$FIX_SERVICE" << SERVICE_EOF
[Unit]
Description=Fix blur-my-shell radius on screen unlock/resume
After=graphical-session.target

[Service]
Type=simple
ExecStart=$FIX_SCRIPT
Restart=on-failure
RestartSec=3

[Install]
WantedBy=graphical-session.target
SERVICE_EOF

    systemctl --user daemon-reload
    systemctl --user enable --now blur-fix.service

    echo -e "  ${GREEN}Radius reset fix applied and running.${RESET}"
    echo ""
}

# ─── Apply BETTER BLUR preset ─────────────────────────────────────────────────
apply_better_blur() {
    dconf load "$DCONF_PATH" << 'EOF'
[/]
pipelines={'pipeline_default': {'name': <'UNIVERSAL'>, 'effects': <[<{'type': <'luminosity'>, 'id': <'effect_10123004872538'>, 'params': <{'brightness_shift': <0>, 'brightness_multiplicator': <1>, 'contrast': <0.69999999999999996>, 'contrast_center': <0.45000000000000001>, 'saturation_multiplicator': <1.1000000000000001>}>}>, <{'type': <'native_static_gaussian_blur'>, 'id': <'effect_70781716204571'>, 'params': <{'radius': <100>, 'brightness': <0.69999999999999996>, 'unscaled_radius': <100>}>}>, <{'type': <'color'>, 'id': <'effect_91905123905706'>, 'params': <{'color': <(1.0, 1.0, 1.0, 0.035472974181175232)>}>}>]>}, 'pipeline_57656187583797': {'name': <'APPLICATION,UNFOCUSED - (Modify this yourself User)'>, 'effects': <[<{'type': <'native_static_gaussian_blur'>, 'id': <'effect_38795972003219'>, 'params': <{'radius': <100>, 'brightness': <0.59999999999999998>, 'unscaled_radius': <100>}>}>, <{'type': <'luminosity'>, 'id': <'effect_51653740722811'>, 'params': <{'brightness_shift': <0>, 'brightness_multiplicator': <1>, 'contrast': <0.69999999999999996>, 'contrast_center': <0.5>, 'saturation_multiplicator': <1.2>}>}>, <{'type': <'corner'>, 'id': <'effect_70682751325723'>, 'params': <{'radius': <24>}>}>]>}, 'pipeline_43430336888672': {'name': <'ROUNDED-DOCK'>, 'effects': <[<{'type': <'luminosity'>, 'id': <'effect_10123004872538'>, 'params': <{'brightness_shift': <0>, 'brightness_multiplicator': <1>, 'contrast': <0.69999999999999996>, 'contrast_center': <0.45000000000000001>, 'saturation_multiplicator': <1.1000000000000001>}>}>, <{'type': <'native_static_gaussian_blur'>, 'id': <'effect_70781716204571'>, 'params': <{'radius': <100>, 'brightness': <0.69999999999999996>, 'unscaled_radius': <100>}>}>, <{'type': <'color'>, 'id': <'effect_91905123905706'>, 'params': <{'color': <(1.0, 1.0, 1.0, 0.035472974181175232)>}>}>, <{'type': <'corner'>, 'id': <'effect_95502997996556'>, 'params': <{'radius': <16>}>}>]>}}
rounded-blur-found=false
settings-version=2

[appfolder]
brightness=0.90000000000000002
sigma=50
style-dialogs=3

[applications]
pipeline='pipeline_default'

[coverflow-alt-tab]
pipeline='pipeline_default'

[dash-to-dock]
blur=true
pipeline='pipeline_43430336888672'

[lockscreen]
blur=false
pipeline='pipeline_default'

[overview]
pipeline='pipeline_default'
style-components=2

[panel]
pipeline='pipeline_default'

[screenshot]
pipeline='pipeline_default'

[window-list]
sigma=60
EOF
}

# ─── Handle choice ────────────────────────────────────────────────────────────
case "$choice" in
    1)
        read -rp "  Do you want to backup your current blur customization? [this will backup to: ${BACKUP_DIR} to restore it later] [Y/n]: " backup_choice
        if [[ "$backup_choice" =~ ^[Yy]$ ]] || [ -z "$backup_choice" ]; then
            do_backup
        fi

        echo -e "  ${CYAN}Applying BETTER BLUR preset...${RESET}"
        apply_better_blur
        echo -e "  ${GREEN}Done!${RESET}"
        echo ""

        read -rp "  Do you want to apply the fix for blur my shell resetting blur radius? [Highly recommended for stability of BLUR] [Y/n]: " fix_choice
        if [[ "$fix_choice" =~ ^[Yy]$ ]] || [ -z "$fix_choice" ]; then
            apply_unlock_fix
        fi

        echo -e "  ${YELLOW}Please logout and login to apply changes.${RESET}"
        echo ""
        ;;
    2)
        if [ ! -f "$BACKUP_FILE" ]; then
            echo -e "  ${RED}No backup found at ${BACKUP_DIR}.${RESET}"
            echo -e "  Apply BETTER BLUR with backup enabled first to create one."
            echo ""
            exit 1
        fi
        echo -e "  ${CYAN}Restoring backup from ${BACKUP_DIR}...${RESET}"
        dconf load "$DCONF_PATH" < "$BACKUP_FILE"
        echo -e "  ${GREEN}Restored!${RESET}"
        echo ""
        ;;
    3)
        echo -e "  ${CYAN}Resetting Blur My Shell to extension default...${RESET}"
        dconf reset -f "$DCONF_PATH"
        sleep 0.5
        dconf reset -f "$DCONF_PATH"

        if systemctl --user is-enabled blur-fix.service &>/dev/null || systemctl --user is-active blur-fix.service &>/dev/null; then
            echo -e "  ${CYAN}Removing radius reset fix...${RESET}"
            systemctl --user disable --now blur-fix.service &>/dev/null
            rm -f "$FIX_SERVICE"
            rm -f "$FIX_SCRIPT"
            rm -f "$FIX_DCONF_FILE"
            systemctl --user daemon-reload
        fi

        echo -e "  ${GREEN}Reset complete!${RESET}"
        echo ""
        ;;
    4)
        echo -e "  Exiting with no changes being made."
        echo ""
        exit 0
        ;;
    *)
        echo -e "  ${RED}Invalid choice (Should be either 1, 2, 3, 4). Exiting...${RESET}"
        echo ""
        exit 1
        ;;
esac

echo -e " HEY! :)  Check me on Twitter/X: ${BOLD}@choehau_ara${RESET}"
echo ""
