# Duo Linux &nbsp; [![build-ublue](https://github.com/blue-build/template/actions/workflows/build.yml/badge.svg)](https://github.com/blue-build/template/actions/workflows/build.yml)

See the [BlueBuild docs](https://blue-build.org/how-to/setup/). 

## Installation (ISO) [Recommended]

> [!CAUTION]
> This ISO installation guide assumes that you want to install Duo Linux on single-boot single-disk setup.

### [DOWNLOAD LINK](https://github.com/mecattaf/duo/actions/workflows/build-iso.yml)
Click on the most recent successful build, then download the ISO artifact.  
ISOs are named in DD-MM-YYYY date format for easy identification.

- Download and extract the ISO artifact from GitHub Actions
- ISO doesn't require an active internet connection during its usage (but it is recommended to have it for NTP functionality)
- Boot from the ISO and proceed with installation
- When ISO is booted, complete the following mandatory configuration:
  - **Network & Host Name**: Configure your WiFi connection if needed
  - **Installation Destination**: Select target disk, choose "Storage Configuration" → Automatic, then "Free up space by removing or shrinking existing partitions"
    - When "Reclaim disk space" screen appears, click "Delete all" and "Reclaim space"
  - **User Creation**: Input your full name, username, and password. Click Done.
  - **Root Password**: Set a root password for system administration (recommended for Sway environments)
- Optionally configure "Keyboard", "Language Support", "Time & Date", etc.
- Click "Begin Installation"
- After installation completes, reboot and enjoy your new Duo Linux system

### Manual Steps

- Sign in to github wih `gh auth login`
- Copy over git credentials
```
git config --global user.name "Thomas Mecattaf"
git config --global user.email "thomas@mecattaf.dev"
```
- Authenticate to firefox and [follow instructions](docs/firefox.md)
- Authenticate to gh from the CLI
- Set icon and gtk theme with GTK Settings
- If flatpaks are not loaded automatically: ``
```
mako #to have a notification daemon running
bluebuild-flatpak-manager apply all
```
- Authenticate into tailscale (using github account)

### Enabling systemd services

We use a single command to detect and enable all systemd services in one go. The snippets below show us testing for a subset of available podman quadlets to be used. Do the same for testing other systemd units (wayland graphical session)
```

# Reload systemd
echo "Reloading systemd daemon..."
systemctl --user daemon-reload

# Start services in order
echo "Starting core services..."
systemctl --user start llm.network
systemctl --user start llm-postgres
systemctl --user start llm-redis

echo "Waiting for databases to initialize..."
sleep 10

echo "Starting auxiliary services..."
systemctl --user start docling
systemctl --user start tika
systemctl --user start searxng
systemctl --user start mcp
systemctl --user start edgetts

echo "Starting main services..."
systemctl --user start litellm
systemctl --user start openwebui

# Enable services
echo "Enabling services for session startup..."
systemctl --user enable \
    llm-postgres \
    llm-redis \
    docling \
    tika \
    searxng \
    mcp \
    edgetts \
    litellm \
    openwebui

# Status check
echo ""
echo "Service Status:"
echo "==============="
systemctl --user status --no-pager llm.slice

```

## Alternative Installation (Rebase)

To rebase an existing atomic Fedora installation to the latest build:

- First rebase to the unsigned image, to get the proper signing keys and policies installed:
  ```
  sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/mecattaf/duo:latest
  ```
- Reboot to complete the rebase:
  ```
  systemctl reboot
  ```
- Then rebase to the signed image, like so:
  ```
  sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/mecattaf/duo:latest
  ```
- Reboot again to complete the installation
  ```
  systemctl reboot
  ```


### Troubleshooting flatpaks

If a flatpak is broken, revert versions using:
```
flatpak list
flatpak remote-info --log flathub com.google.Chrome
flatpak update --commit=<commit-of-working-version> com.google.Chrome
```

### Rolling back to previous versions

View the list of available builds by entering:
```
skopeo list-tags docker://ghcr.io/mecattaf/duo | sort -rV
```

Rebasing to a specific build requires users to open a host terminal and enter:
```
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/IMAGE-NAME:VERSION-YEARMONTHDAY
```

Example:
```
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/bazzite-deck:39-20240113
```
For the Jan. 13th 2024 bazzite-deck (Fedora 39) build.

### To revert back to Silverblue

```shell
sudo rpm-ostree rebase fedora:fedora/40/x86_64/silverblue
```
