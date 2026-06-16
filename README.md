# Better Blur Tuner

A small interactive script that sets up a clean, consistent blur(Static) look across GNOME using the [Blur My Shell](https://github.com/aunetx/blur-my-shell) extension - and fixes a known bug where the blur radius randomly resets after your screen locks or your computer sleeps.

## What it does

- Checks that you're on GNOME (works on Ubuntu, Fedora, Bazzite, and other distros with GNOME).
- Checks if Blur My Shell is installed, or not.
- Support for Yaru (Ubuntu) , ADWAITA (Other distros with GNOME).
- Applies a tuned blur preset across the top bar, dock, overview, and folder background.
- Optionally backs up your current blur settings before changing anything
- Optionally fixes the radius-reset bug that happens after lock/sleep
- Lets you restore your previous settings or reset everything back to the extension's defauls.

## Requirements

- GNOME desktop environment
- [Blur My Shell](https://extensions.gnome.org/extension/3193/blur-my-shell/) extension installed (the script will tell if it's missing)
- `dconf` ( comes pre-installed on all distros with GNOME )

## How to install

OPEN TERMINAL/CONSOLE

Clone the project to your Downloads folder:

```bash
cd ~/Downloads
git clone https://github.com/ChoeHa-U/Better-BLUR-for-MySHELL
```

move into the project directory:

```bash
cd ~/Downloads/Better-BLUR-for-MySHELL
```

Run the script:

```bash
bash blurtweaker.sh
```

## If that does not run the script try this:

### 1. Make it executable

Linux doesn't let scripts run by default as a safety measure, so the first time you use it you need to grant permission:

```bash
chmod +x blurtweaker.sh
```

You only need to do this once.

### 2. Run it

```bash
./blurtweaker.sh
```

## If Blur My Shell isn't installed

The script will detect and stop with instructions, since installing GNOME extensions varies with different distros (Debian, Fedora, Arch), How to:

1. Install **Extension Manager** from your distro's app store, or via Flathub (you need to add flathub repository beforehand or via [FLATHUB](https://flathub.org/en/setup):
   ```bash
   flatpak install flathub com.mattjakeman.ExtensionManager
   ```
2. Open Extension Manager, search for **Blur My Shell**, and install it
3. Run `bash blurtweaker.sh` again

## The menu

```
1) Apply BETTER BLUR
2) Restore your previous blur settings
3) Reset Blur to extension default
4) Exit
```

**1) Apply BETTER BLUR**
Applies the tuned preset. Before doing so, it asks if you'd like to back up your current settings (recommended if you've already customized things). After applying,your distro, and the dock configuration,then it asks if you want to install the radius-reset fix (recommended - without it, blur strength can silently drop after your screen locks or the laptop wakes from sleep). You'll need to log out and back in afterward for everything to take full effect.

**2) Restore your previous blur settings**
Brings back whatever was saved during your last backup. Only works if you said yes to the backup prompt before.

**3) Reset Blur to extension default**
Wipes everything back to Blur My Shell's out-of-the-box defaults, including removing the radius-reset fix if it was applied. Use this if you want a totally clean slate.

**4) Exit**
Does nothing and closes.

## Where things are stored

| What | Where |
|------|-------|
| Backup of your previous settings | `~/.local/share/blurtweaker/bms_backup.dconf` |
| Radius-fix pipeline snapshot | `~/.config/blur-my-shell-pipelines.dconf` |
| Radius-fix watcher script | `~/.local/bin/blur-fix-on-unlock.sh` |
| Radius-fix background service | `~/.config/systemd/user/blur-fix.service` |

None of this touches anything outside your home folder.

## About the radius-reset fix

Blur My Shell has a bug where the blur radius can silently snap back to a lower default value after your screen locks or your device sleeps, even though the slider in the extension's settings still visually shows the value you set. The fix works by running a small background watcher that detects when your screen unlocks and reapplies the correct blur values automatically, a second after you're back in. It's lightweight and only works when unlocked, it won't interfere with sleep/wake timing.

## Notes

- Tested on **Ubuntu**, **Fedora (Workstation, Silverblue)**, **Bazzite**.
- If you're on a non-GNOME desktop (KDE, XFCE, etc.), the script should not run.
- If your desktop environment isn't detected correctly even though you are on GNOME, the script will ask if you want to continue anyway.
- pop-up blur is not implemented yet (do it manually).
- Dynamic blur need to be configured manually for dock if you are discomfort with the static blur on pop-up autohide dock configuration.
