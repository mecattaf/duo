# Firefox Custom Configuration Justfile
# Manages Firefox Flatpak setup with custom themes and profiles
# Expects config files to be in ~/.config/firefox-setup/ (managed by chezmoi)

# Set bash as default shell for all recipes
set shell := ["bash", "-euo", "pipefail", "-c"]

# Configuration variables
FIREFOX_BASE := env_var('HOME') + "/.var/app/org.mozilla.firefox/.mozilla/firefox"
CONFIG_DIR := env_var('HOME') + "/.config/firefox-setup"
FIREFOX_FLATPAK := "org.mozilla.firefox"

# Colors for output
RED := '\033[0;31m'
GREEN := '\033[0;32m'
YELLOW := '\033[1;33m'
NC := '\033[0m'

# Default recipe - runs full setup
firefox-setup: firefox-check firefox-create-profiles firefox-deploy-configs firefox-write-profiles
    @echo -e "{{GREEN}}═══════════════════════════════════════{{NC}}"
    @echo -e "{{GREEN}}Firefox setup complete!{{NC}}"
    @echo -e "{{GREEN}}═══════════════════════════════════════{{NC}}"
    @echo -e "\nProfiles created:"
    @echo -e "  • {{YELLOW}}default{{NC}} - Standard browsing with one-line UI & clock startpage"
    @echo -e "  • {{YELLOW}}webapp{{NC}} - Native app mode (no UI)"
    @echo -e "\nUsage examples:"
    @echo -e "  {{YELLOW}}flatpak run {{FIREFOX_FLATPAK}}{{NC}} (uses default profile)"
    @echo -e "  {{YELLOW}}flatpak run {{FIREFOX_FLATPAK}} -P webapp --new-window URL{{NC}}"

# Check if Firefox Flatpak is installed (user installation)
firefox-check:
    @if ! flatpak list --user | grep -q "{{FIREFOX_FLATPAK}}"; then \
        echo -e "{{RED}}Error: Firefox Flatpak is not installed{{NC}}"; \
        echo "Install with: flatpak install --user flathub {{FIREFOX_FLATPAK}}"; \
        exit 1; \
    fi
    @echo -e "{{GREEN}}Firefox Flatpak detected (user installation){{NC}}"
    @if [[ ! -d "{{CONFIG_DIR}}" ]]; then \
        echo -e "{{RED}}Error: Config directory not found at {{CONFIG_DIR}}{{NC}}"; \
        echo "Please ensure chezmoi has deployed Firefox config files to {{CONFIG_DIR}}"; \
        exit 1; \
    fi

# Install Firefox Flatpak if not present (user installation)
firefox-install:
    @echo -e "{{YELLOW}}Installing Firefox Flatpak as user...{{NC}}"
    flatpak install --user -y flathub {{FIREFOX_FLATPAK}}
    @echo -e "{{GREEN}}Firefox Flatpak installed for user{{NC}}"

# Create Firefox profiles (default and webapp)
firefox-create-profiles:
    @echo -e "{{YELLOW}}Creating Firefox profiles...{{NC}}"
    @for profile in default webapp; do \
        if [[ ! -d "{{FIREFOX_BASE}}/$profile" ]]; then \
            echo "Creating profile: $profile"; \
            flatpak run --command=firefox {{FIREFOX_FLATPAK}} -headless \
                -CreateProfile "$profile {{FIREFOX_BASE}}/$profile"; \
        else \
            echo "Profile already exists: $profile"; \
        fi; \
        mkdir -p "{{FIREFOX_BASE}}/$profile/chrome"; \
    done

# Deploy all configuration files to Firefox profiles
firefox-deploy-configs:
    @echo "Deploying Firefox configurations..."
    @if [[ ! -d "{{CONFIG_DIR}}" ]]; then \
        echo -e "{{RED}}Error: Config directory {{CONFIG_DIR}} not found{{NC}}"; \
        echo "Please run chezmoi to deploy Firefox config files first"; \
        exit 1; \
    fi
    @if [[ -f "{{CONFIG_DIR}}/clock.html" ]]; then \
        echo -e "{{GREEN}}Clock startpage found{{NC}}"; \
        if [[ -f "{{CONFIG_DIR}}/user.js" ]]; then \
            sed -i "s|file:///home/.config/firefox-setup/clock.html|file://{{CONFIG_DIR}}/clock.html|g" "{{CONFIG_DIR}}/user.js"; \
        fi; \
    else \
        echo -e "{{YELLOW}}Warning: clock.html not found in {{CONFIG_DIR}}{{NC}}"; \
        echo "The minimal clock startpage will not be available"; \
    fi
    @for profile in default webapp; do \
        if [[ -f "{{CONFIG_DIR}}/user.js" ]]; then \
            cp "{{CONFIG_DIR}}/user.js" "{{FIREFOX_BASE}}/$profile/"; \
            echo "  ✓ Deployed user.js to $profile"; \
        else \
            echo -e "{{YELLOW}}Warning: user.js not found{{NC}}"; \
        fi; \
    done
    @if [[ -f "{{CONFIG_DIR}}/userChrome.css" ]]; then \
        cp "{{CONFIG_DIR}}/userChrome.css" "{{FIREFOX_BASE}}/default/chrome/"; \
        echo "  ✓ Deployed userChrome.css to default profile"; \
    fi
    @if [[ -f "{{CONFIG_DIR}}/userContent.css" ]]; then \
        cp "{{CONFIG_DIR}}/userContent.css" "{{FIREFOX_BASE}}/default/chrome/"; \
        echo "  ✓ Deployed userContent.css to default profile"; \
    fi
    @if [[ -f "{{CONFIG_DIR}}/userChrome-webapp.css" ]]; then \
        cp "{{CONFIG_DIR}}/userChrome-webapp.css" "{{FIREFOX_BASE}}/webapp/chrome/userChrome.css"; \
        echo "  ✓ Deployed webapp userChrome.css"; \
    fi
    @if [[ -f "{{CONFIG_DIR}}/userContent.css" ]]; then \
        cp "{{CONFIG_DIR}}/userContent.css" "{{FIREFOX_BASE}}/webapp/chrome/"; \
        echo "  ✓ Deployed userContent.css to webapp profile"; \
    fi

# Write profiles.ini configuration
firefox-write-profiles:
    @echo -e "{{YELLOW}}Configuring profiles.ini...{{NC}}"
    @cat > "{{FIREFOX_BASE}}/profiles.ini" << 'EOF'
    [Profile0]
    Name=default
    IsRelative=1
    Path=default
    Default=1
    
    [Profile1]
    Name=webapp
    IsRelative=1
    Path=webapp
    
    [General]
    StartWithLastProfile=1
    Version=2
    EOF
    @echo "  ✓ profiles.ini configured"

# Launch Firefox with webapp profile for a given URL
firefox-webapp url:
    flatpak run {{FIREFOX_FLATPAK}} -P webapp --new-window {{url}}

# Verify installation and show status
firefox-verify:
    @echo -e "{{YELLOW}}Firefox Installation Status:{{NC}}"
    @echo ""
    @if flatpak list --user | grep -q "{{FIREFOX_FLATPAK}}"; then \
        echo -e "{{GREEN}}✓{{NC}} Firefox Flatpak installed (user)"; \
    else \
        echo -e "{{RED}}✗{{NC}} Firefox Flatpak not installed"; \
    fi
    @for profile in default webapp; do \
        if [[ -d "{{FIREFOX_BASE}}/$profile" ]]; then \
            echo -e "{{GREEN}}✓{{NC}} Profile '$profile' exists"; \
            if [[ -f "{{FIREFOX_BASE}}/$profile/chrome/userChrome.css" ]]; then \
                echo -e "  {{GREEN}}✓{{NC}} userChrome.css present"; \
            else \
                echo -e "  {{YELLOW}}○{{NC}} userChrome.css missing"; \
            fi; \
            if [[ -f "{{FIREFOX_BASE}}/$profile/user.js" ]]; then \
                echo -e "  {{GREEN}}✓{{NC}} user.js present"; \
            else \
                echo -e "  {{YELLOW}}○{{NC}} user.js missing"; \
            fi; \
        else \
            echo -e "{{RED}}✗{{NC}} Profile '$profile' missing"; \
        fi; \
    done
    @if [[ -f "{{CONFIG_DIR}}/clock.html" ]]; then \
        echo -e "{{GREEN}}✓{{NC}} Clock startpage available"; \
    else \
        echo -e "{{YELLOW}}○{{NC}} Clock startpage not found"; \
    fi

# Clean/remove Firefox profiles and configs
firefox-clean:
    @echo -e "{{YELLOW}}Cleaning Firefox configurations...{{NC}}"
    @read -p "Are you sure you want to remove all Firefox profiles and configs? (y/N): " -n 1 -r && \
    echo && \
    if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
        rm -rf "{{FIREFOX_BASE}}/default"; \
        rm -rf "{{FIREFOX_BASE}}/webapp"; \
        rm -f "{{FIREFOX_BASE}}/profiles.ini"; \
        echo -e "{{GREEN}}Firefox configurations cleaned{{NC}}"; \
    else \
        echo "Cancelled"; \
    fi

# Backup current Firefox profiles
firefox-backup:
    @BACKUP_DIR="${HOME}/firefox-backup-$(date +%Y%m%d-%H%M%S)" && \
    echo -e "{{YELLOW}}Backing up Firefox profiles to $$BACKUP_DIR...{{NC}}" && \
    mkdir -p "$$BACKUP_DIR" && \
    if [[ -d "{{FIREFOX_BASE}}" ]]; then \
        cp -r "{{FIREFOX_BASE}}" "$$BACKUP_DIR/"; \
        echo -e "{{GREEN}}Backup complete: $$BACKUP_DIR{{NC}}"; \
    else \
        echo -e "{{RED}}No Firefox profiles found to backup{{NC}}"; \
    fi

# Restore Firefox profiles from backup
firefox-restore backup_dir:
    @if [[ ! -d "{{backup_dir}}" ]]; then \
        echo -e "{{RED}}Backup directory not found: {{backup_dir}}{{NC}}"; \
        exit 1; \
    fi
    @echo -e "{{YELLOW}}Restoring Firefox profiles from {{backup_dir}}...{{NC}}"
    @read -p "This will overwrite current profiles. Continue? (y/N): " -n 1 -r && \
    echo && \
    if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
        rm -rf "{{FIREFOX_BASE}}"; \
        cp -r "{{backup_dir}}/firefox" "{{FIREFOX_BASE}}"; \
        echo -e "{{GREEN}}Restore complete{{NC}}"; \
    else \
        echo "Cancelled"; \
    fi

# Update configuration files from source
firefox-update:
    @echo -e "{{YELLOW}}Updating Firefox configurations...{{NC}}"
    @just firefox-deploy-configs
    @echo -e "{{GREEN}}Update complete. Restart Firefox to apply changes.{{NC}}"
