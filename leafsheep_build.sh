#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STEP_DONE_FILE="$SCRIPT_DIR/.build_steps_done"

mark_step_done() {
    local step=$1
    touch "$STEP_DONE_FILE.$step"
}

is_step_done() {
    [ -f "$STEP_DONE_FILE.$1" ]
}

clear_step_done() {
    rm -f "$STEP_DONE_FILE."*
}

check_lsversion() {
    if [ ! -f LSVERSION ]; then
        echo "Error: LSVERSION file does not exist!"
        return 1
    fi

    CHANNEL=$(head -n 1 LSVERSION)
    VERSION=$(sed -n '2p' LSVERSION)
    SERVICE_PACK=$(sed -n '3p' LSVERSION)

    echo "Current LeafSheep browser information:"
    echo "Channel: $CHANNEL "
    echo "Version: $VERSION"
    echo "Service Pack: $SERVICE_PACK"
    echo

    mark_step_done 1
}

sync_uxp() {
    DEFAULT_UXP_OPTION="1"
    DEFAULT_UXP_NAME="Master"

    echo "Please select UXP version source:"
    echo "1) Master"
    echo "2) Tags"
    echo "3) Release"
    read -p "Enter option (1/2/3) [default: $DEFAULT_UXP_OPTION]: " UXP_OPTION

    if [ -z "$UXP_OPTION" ]; then
        UXP_OPTION=$DEFAULT_UXP_OPTION
        echo "Using default option: $DEFAULT_UXP_OPTION ($DEFAULT_UXP_NAME)"
    fi

    mkdir -p platform
    cd platform

    case $UXP_OPTION in
        1|Master|master)
            echo "Downloading UXP using git clone..."
            git clone https://repo.palemoon.org/MoonchildProductions/UXP.git .
            COMMIT_ID=$(git rev-parse --short HEAD)
            ;;
        2|Tags|tags)
            echo "Downloading UXP latest tags..."
            LATEST_TAG=$(curl -s https://repo.palemoon.org/api/v1/repos/MoonchildProductions/UXP/tags | grep -o 'name":.*' | head -n 1 | cut -d '"' -f 3)
            DOWNLOAD_URL="https://repo.palemoon.org/MoonchildProductions/UXP/archive/$LATEST_TAG.tar.gz"
            wget -O uxp-latest-tag.tar.gz "$DOWNLOAD_URL"
            tar -xzf uxp-latest-tag.tar.gz --strip-components=1
            rm uxp-latest-tag.tar.gz
            COMMIT_ID=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
            ;;
        3|Release|release)
            echo "Downloading UXP latest release..."
            LATEST_RELEASE=$(curl -s https://repo.palemoon.org/api/v1/repos/MoonchildProductions/UXP/releases/latest)
            DOWNLOAD_URL=$(echo $LATEST_RELEASE | grep -o '"tarball_url":"[^"]*' | cut -d '"' -f 4)
            wget -O uxp-latest.tar.gz "$DOWNLOAD_URL"
            tar -xzf uxp-latest.tar.gz --strip-components=1
            rm uxp-latest.tar.gz
            COMMIT_ID=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
            ;;
        *)
            echo "Invalid option, please try again."
            cd "$SCRIPT_DIR"
            return 1
            ;;
    esac

    if [ -z "$COMMIT_ID" ] && [ -d ".git" ]; then
        COMMIT_ID=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    fi

    if [ -z "$COMMIT_ID" ]; then
        COMMIT_ID="unknown"
    fi

    cd "$SCRIPT_DIR"
    echo "UXP sync completed!"
    echo "UXP Commit ID: $COMMIT_ID"
    echo "$COMMIT_ID" > "$SCRIPT_DIR/.uxp_commit_id"
    echo "$COMMIT_ID" > platform/.uxp_commit_id

    mark_step_done 2
}

update_version_info() {
    LS_VERSION=$(sed -n '2p' LSVERSION)
    LS_SP=$(sed -n '3p' LSVERSION)
    LS_UXP=$(sed -n '4p' LSVERSION)

    if [ -f "$SCRIPT_DIR/.uxp_commit_id" ]; then
        COMMIT_ID=$(cat "$SCRIPT_DIR/.uxp_commit_id")
    elif [ -f "platform/.uxp_commit_id" ]; then
        COMMIT_ID=$(cat "platform/.uxp_commit_id")
    else
        COMMIT_ID="$LS_UXP"
    fi

    LINES_COUNT=$(wc -l < LSVERSION)
    if [ $LINES_COUNT -lt 3 ]; then
        while [ $LINES_COUNT -lt 3 ]; do
            echo "" >> LSVERSION
            LINES_COUNT=$((LINES_COUNT + 1))
        done
    fi

    cp LSVERSION LSVERSION.backup
    sed -i "4s/.*/$COMMIT_ID/" LSVERSION
    if [ $(wc -l < LSVERSION) -eq 3 ]; then
        echo "$COMMIT_ID" >> LSVERSION
    fi
    echo "Commit ID written to LSVERSION file (line 4)"

    UAFILE="leafsheep/branding/shared/uaoverrides.inc"
    if [ -f "$UAFILE" ]; then
        cp "$UAFILE" "$UAFILE.backup"
        sed -i "s/^#define LSVAPI_LS.*/#define LSVAPI_LS $LS_VERSION/" "$UAFILE"
        sed -i "s/^#define LSVAPI_SP.*/#define LSVAPI_SP $LS_SP/" "$UAFILE"
        sed -i "s/^#define LSVAPI_UXP.*/#define LSVAPI_UXP $COMMIT_ID/" "$UAFILE"
        echo "LSVAPI macros updated in uaoverrides.inc:"
        echo "  LSVAPI_LS: $LS_VERSION"
        echo "  LSVAPI_SP: $LS_SP"
        echo "  LSVAPI_UXP: $COMMIT_ID"
    else
        echo "Warning: uaoverrides.inc file not found!"
    fi

    VERSION_DISPLAY_FILE="leafsheep/config/version_display.txt"
    if [ -f "$VERSION_DISPLAY_FILE" ]; then
        cp "$VERSION_DISPLAY_FILE" "$VERSION_DISPLAY_FILE.backup"
        OLD_CONTENT=$(cat "$VERSION_DISPLAY_FILE")
        if [[ "$OLD_CONTENT" =~ \(.*\) ]]; then
            NEW_CONTENT=$(echo "$OLD_CONTENT" | sed "s/([^)]*)/($COMMIT_ID)/")
        else
            NEW_CONTENT="$OLD_CONTENT ($COMMIT_ID)"
        fi
        echo "$NEW_CONTENT" > "$VERSION_DISPLAY_FILE"
        echo "Version display updated: $NEW_CONTENT"
    else
        echo "Warning: version_display.txt file not found!"
    fi

    # 直接修改aboutDialog-updater.js文件写入版本数据
    UPDATER_JS_FILE="leafsheep/base/content/aboutDialog-updater.js"
    if [ -f "$UPDATER_JS_FILE" ]; then
        cp "$UPDATER_JS_FILE" "$UPDATER_JS_FILE.backup"
        
        # 读取LSVERSION文件第一行获取Channel
        if [ -f "LSVERSION" ]; then
            LS_CHANNEL=$(head -n 1 LSVERSION)
        else
            LS_CHANNEL="unknown"
        fi
        
        # 使用sed命令替换版本信息
        sed -i "s/channel: \"\"/channel: \"$LS_CHANNEL\"/" "$UPDATER_JS_FILE"
        sed -i "s/browser_version: \"\"/browser_version: \"$LS_VERSION\"/" "$UPDATER_JS_FILE"
        sed -i "s/service_pack: \"\"/service_pack: \"$LS_SP\"/" "$UPDATER_JS_FILE"
        sed -i "s/uxp_commit: \"\"/uxp_commit: \"$COMMIT_ID\"/" "$UPDATER_JS_FILE"
        
        echo "Version info written to aboutDialog-updater.js:"
        echo "  channel: $LS_CHANNEL"
        echo "  browser_version: $LS_VERSION"
        echo "  service_pack: $LS_SP"
        echo "  uxp_commit: $COMMIT_ID"
    else
        echo "Warning: aboutDialog-updater.js file not found!"
    fi

    mark_step_done 3
}

select_configuration() {
    echo "Please select your current system:"
    echo "1) Windows"
    echo "2) Linux"
    echo "3) MacOS"
    echo "4) Illumos"
    echo "5) BSD Series"
    read -p "Enter option (1/2/3): " SYSTEM_TYPE

    case $SYSTEM_TYPE in
        1|Windows|windows)
            SYSTEM_DIR="windows"
            ;;
        2|Linux|linux)
            SYSTEM_DIR="linux"
            ;;
        3|macos|MacOS|mac)
            SYSTEM_DIR="macos"
            ;;
        4|illumos|Illumos)
            SYSTEM_DIR="illumos"
            ;;
        5|BSD|bsd)
            SYSTEM_DIR="bsd"
            ;;
        *)
            echo "Invalid option, creating blank .mozconfig file..."
            touch .mozconfig
            echo "Please manually edit .mozconfig file to configure build options"
            echo

            mark_step_done 3
            mark_step_done 4
            mark_step_done 5
            return 0
            ;;
    esac

    echo "Selected system: $SYSTEM_DIR"

    if [ ! -d "mozconfigs/$SYSTEM_DIR" ]; then
        echo "Error: mozconfigs/$SYSTEM_DIR directory does not exist!"
        echo "Creating blank .mozconfig file..."
        touch .mozconfig
        echo "Please manually edit .mozconfig file to configure build options"
        mark_step_done 3
        mark_step_done 4
        mark_step_done 5
        return 0
    fi

    echo "Available architectures for $SYSTEM_DIR:"
    ARCH_DIRS=($(ls -d mozconfigs/$SYSTEM_DIR/*/ 2>/dev/null | sed 's|/$||' | xargs -n1 basename))

    if [ ${#ARCH_DIRS[@]} -eq 0 ]; then
        echo "No architecture directories found!"
        echo "Creating blank .mozconfig file..."
        touch .mozconfig
        echo "Please manually edit .mozconfig file to configure build options"
        mark_step_done 3
        mark_step_done 4
        mark_step_done 5
        return 0
    fi

    for i in "${!ARCH_DIRS[@]}"; do
        echo "$((i+1))) ${ARCH_DIRS[i]}"
    done

    read -p "Select architecture [1-${#ARCH_DIRS[@]}]: " ARCH_OPTION

    if [[ "$ARCH_OPTION" =~ ^[0-9]+$ ]] && [ "$ARCH_OPTION" -ge 1 ] && [ "$ARCH_OPTION" -le ${#ARCH_DIRS[@]} ]; then
        ARCH_DIR="${ARCH_DIRS[$((ARCH_OPTION-1))]}"
        echo "Selected architecture: $ARCH_DIR"
    else
        echo "Invalid architecture selection, creating blank .mozconfig file..."
        touch .mozconfig
        echo "Please manually edit .mozconfig file to configure build options"
        mark_step_done 3
        mark_step_done 4
        mark_step_done 5
        return 0
    fi

    echo "Available .mozconfig files for $SYSTEM_DIR/$ARCH_DIR:"
    MOZCONFIG_FILES=($(ls mozconfigs/$SYSTEM_DIR/$ARCH_DIR/*.mozconfig 2>/dev/null))

    if [ ${#MOZCONFIG_FILES[@]} -eq 0 ]; then
        echo "No .mozconfig files found!"
        echo "Creating blank .mozconfig file..."
        touch .mozconfig
        echo "Please manually edit .mozconfig file to configure build options"
        mark_step_done 3
        mark_step_done 4
        mark_step_done 5
        return 0
    fi

    for i in "${!MOZCONFIG_FILES[@]}"; do
        filename=$(basename "${MOZCONFIG_FILES[i]}")
        echo "$((i+1))) $filename"
    done

    read -p "Select .mozconfig file [1-${#MOZCONFIG_FILES[@]}]: " MOZCONFIG_OPTION

    if [[ "$MOZCONFIG_OPTION" =~ ^[0-9]+$ ]] && [ "$MOZCONFIG_OPTION" -ge 1 ] && [ "$MOZCONFIG_OPTION" -le ${#MOZCONFIG_FILES[@]} ]; then
        SELECTED_FILE="${MOZCONFIG_FILES[$((MOZCONFIG_OPTION-1))]}"

        if [ -f .mozconfig ]; then
            rm .mozconfig
        fi
        cp "$SELECTED_FILE" .mozconfig
        echo "Selected configuration: $(basename "$SELECTED_FILE")"
        echo "Configuration file copied to .mozconfig"
    else
        echo "Invalid selection, creating blank .mozconfig file..."
        touch .mozconfig
        echo "Please manually edit .mozconfig file to configure build options"
    fi

    mark_step_done 3
    mark_step_done 4
    mark_step_done 5
}

execute_mach_action() {
    echo "Please select the action to perform:"
    echo "1) configure"
    echo "2) build"
    echo "3) run"
    echo "4) clobber"
    echo "5) package"
    read -p "Enter option (1/2/3/4/5): " ACTION

    chmod +x mach

    case $ACTION in
        1|configure)
            echo "Running configure..."
            ./mach configure
            ;;
        2|build)
            echo "Running build..."
            ./mach build
            ;;
        3|run)
            echo "Running browser..."
            ./mach run
            ;;
        4|clobber)
            echo "Cleaning build environment..."
            ./mach clobber
            ;;
        5|package)
            echo "Packaging..."
            ./mach package
            ;;
        *)
            echo "Invalid option, no action performed."
            ;;
    esac
}

show_menu() {
    echo ""
    echo "========================================"
    echo "     LeafSheep Build Script"
    echo "========================================"
    echo ""

    if [ -f LSVERSION ]; then
        CHANNEL=$(head -n 1 LSVERSION)
        VERSION=$(sed -n '2p' LSVERSION)
        SERVICE_PACK=$(sed -n '3p' LSVERSION)
        UXP_COMMIT=$(sed -n '4p' LSVERSION)
        echo "  Channel: $CHANNEL"
        echo "  Version: $VERSION"
        echo "  Service Pack: $SERVICE_PACK"
        echo "  UXP Commit: ${UXP_COMMIT:-unknown}"
        echo ""
        echo "========================================"
        echo ""
    fi

    local steps=(
        "Sync UXP version"
        "Update version info"
        "Select configuration"
        "Execute mach action"
    )

    for i in "${!steps[@]}"; do
        local num=$((i+1))
        local status="[ ]"
        if is_step_done $num; then
            status="[✓]"
        fi
        echo "  $status $num) ${steps[$i]}"
    done

    echo ""
    echo "  S) Run all remaining steps"
    echo "  R) Reset all steps"
    echo "  Q) Quit"
    echo ""
}

run_all_remaining() {
    for i in {1..4}; do
        if ! is_step_done $i; then
            run_step $i
            if [ $? -ne 0 ]; then
                return 1
            fi
        fi
    done
}

run_step() {
    local step=$1
    echo ""
    echo "========================================"
    echo "Step $step: ${steps[$((step-1))]}"
    echo "========================================"
    echo ""

    case $step in
        1)
            sync_uxp
            ;;
        2)
            update_version_info
            ;;
        3)
            select_configuration
            ;;
        4)
            execute_mach_action
            ;;
        *)
            echo "Invalid step"
            return 1
            ;;
    esac
}

declare -a steps=(
    "Sync UXP version"
    "Update version info"
    "Select configuration"
    "Execute mach action"
)

main() {
    cd "$SCRIPT_DIR"

    if [ ! -f LSVERSION ]; then
        echo "Error: LSVERSION file does not exist!"
        exit 1
    fi

    if [ -f platform/.git ]; then
        cd platform
        COMMIT_ID=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        cd "$SCRIPT_DIR"
        if [ -n "$COMMIT_ID" ] && [ "$COMMIT_ID" != "unknown" ]; then
            mark_step_done 1
            mark_step_done 2
        fi
    fi

    while true; do
        show_menu
        read -p "Select option: " choice

        case $choice in
            S|s)
                run_all_remaining
                ;;
            1|2|3|4)
                run_step $choice
                ;;
            R|r)
                clear_step_done
                echo "All steps reset."
                ;;
            Q|q)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid option"
                ;;
        esac
    done
}

main