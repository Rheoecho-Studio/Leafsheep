#!/bin/bash

# 设置脚本为立即退出如果任何命令执行失败
set -e

# 检查LSVERSION文件是否存在
if [ ! -f LSVERSION ]; then
    echo "Error: LSVERSION file does not exist!"
    exit 1
fi

# 读取LSVERSION文件内容
CHANNEL=$(head -n 1 LSVERSION)
VERSION=$(sed -n '2p' LSVERSION)
SERVICE_PACK=$(sed -n '3p' LSVERSION)

# 输出当前代码的频道和版本号
echo "Current LeafSheep browser information:"
echo "Channel: $CHANNEL (Rolling)"
echo "Version: $VERSION"
echo "Service Pack: $SERVICE_PACK"
echo

# 设置默认UXP选项为Master
DEFAULT_UXP_OPTION="1"
DEFAULT_UXP_NAME="Master"

echo "Please select UXP version source:"
echo "1) Master"
echo "2) Tags"
echo "3) Release"
read -p "Enter option (1/2/3) [default: $DEFAULT_UXP_OPTION]: " UXP_OPTION

# 如果用户留空，使用默认值
if [ -z "$UXP_OPTION" ]; then
    UXP_OPTION=$DEFAULT_UXP_OPTION
    echo "Using default option: $DEFAULT_UXP_OPTION ($DEFAULT_UXP_NAME)"
fi

# 确保platform文件夹存在（直接下载到platform文件夹）
mkdir -p platform
cd platform

case $UXP_OPTION in
    1|Master|master) 
        echo "Downloading UXP using git clone..."
        git clone https://repo.palemoon.org/MoonchildProductions/UXP.git .
        # 获取commit ID
        COMMIT_ID=$(git rev-parse --short HEAD)
        ;;
    2|Tags|tags) 
        echo "Downloading UXP latest tags..."
        # 获取最新的tag tar.gz文件链接
        LATEST_TAG=$(curl -s https://repo.palemoon.org/api/v1/repos/MoonchildProductions/UXP/tags | grep -o 'name":.*' | head -n 1 | cut -d '"' -f 3)
        DOWNLOAD_URL="https://repo.palemoon.org/MoonchildProductions/UXP/archive/$LATEST_TAG.tar.gz"
        wget -O uxp-latest-tag.tar.gz "$DOWNLOAD_URL"
        tar -xzf uxp-latest-tag.tar.gz --strip-components=1
        rm uxp-latest-tag.tar.gz
        # 尝试从git获取commit ID
        COMMIT_ID=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        ;;
    3|Release|release) 
        echo "Downloading UXP latest release..."
        # 获取最新的release tar.gz文件链接
        LATEST_RELEASE=$(curl -s https://repo.palemoon.org/api/v1/repos/MoonchildProductions/UXP/releases/latest)
        DOWNLOAD_URL=$(echo $LATEST_RELEASE | grep -o '"tarball_url":"[^"]*' | cut -d '"' -f 4)
        wget -O uxp-latest.tar.gz "$DOWNLOAD_URL"
        tar -xzf uxp-latest.tar.gz --strip-components=1
        rm uxp-latest.tar.gz
        # 尝试从git获取commit ID
        COMMIT_ID=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
        ;;
    *) 
        echo "Invalid option, please try again."
        exit 1
        ;;
esac

# 如果COMMIT_ID为空，尝试从git获取
if [ -z "$COMMIT_ID" ] && [ -d ".git" ]; then
    COMMIT_ID=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
fi

# 如果仍然为空，设置为unknown
if [ -z "$COMMIT_ID" ]; then
    COMMIT_ID="unknown"
fi

cd ..
echo "UXP sync completed!"
echo "UXP Commit ID: $COMMIT_ID"

# 将commit ID写入LSVERSION文件的第四行
# 使用sed命令直接在第四行插入commit ID
# 如果文件少于4行，先补齐到3行
LINES_COUNT=$(wc -l < LSVERSION)
if [ $LINES_COUNT -lt 3 ]; then
    # 补齐到3行
    while [ $LINES_COUNT -lt 3 ]; do
        echo "" >> LSVERSION
        LINES_COUNT=$((LINES_COUNT + 1))
    done
fi

# 现在使用sed在第四行插入commit ID
# 先备份原文件
cp LSVERSION LSVERSION.backup
# 使用sed在第四行插入commit ID，如果第四行已存在则替换
sed -i "4s/.*/$COMMIT_ID/" LSVERSION
# 如果第四行不存在（文件只有3行），则追加到第四行
if [ $(wc -l < LSVERSION) -eq 3 ]; then
    echo "$COMMIT_ID" >> LSVERSION
fi

echo "Commit ID written to LSVERSION file (line 4)"

# 更新uaoverrides.inc文件中的LSVAPI宏定义
# 读取LSVERSION文件的最新内容
LS_VERSION=$(sed -n '2p' LSVERSION)
LS_SP=$(sed -n '3p' LSVERSION)
LS_UXP=$(sed -n '4p' LSVERSION)

# 更新uaoverrides.inc文件中的LSVAPI宏定义
UAFILE="leafsheep/branding/shared/uaoverrides.inc"
if [ -f "$UAFILE" ]; then
    # 备份原文件
    cp "$UAFILE" "$UAFILE.backup"
    
    # 更新LSVAPI_LS宏定义
    sed -i "s/^#define LSVAPI_LS.*/#define LSVAPI_LS $LS_VERSION/" "$UAFILE"
    
    # 更新LSVAPI_SP宏定义
    sed -i "s/^#define LSVAPI_SP.*/#define LSVAPI_SP $LS_SP/" "$UAFILE"
    
    # 更新LSVAPI_UXP宏定义
    sed -i "s/^#define LSVAPI_UXP.*/#define LSVAPI_UXP $LS_UXP/" "$UAFILE"
    
    echo "LSVAPI macros updated in uaoverrides.inc:"
    echo "  LSVAPI_LS: $LS_VERSION"
    echo "  LSVAPI_SP: $LS_SP"
    echo "  LSVAPI_UXP: $LS_UXP"
else
    echo "Warning: uaoverrides.inc file not found!"
fi

# 将commit ID写入version_display.txt文件
VERSION_DISPLAY_FILE="leafsheep/config/version_display.txt"
if [ -f "$VERSION_DISPLAY_FILE" ]; then
    # 备份原文件
    cp "$VERSION_DISPLAY_FILE" "$VERSION_DISPLAY_FILE.backup"
    
    # 读取原文件内容，保留前面的版本信息，只更新commit ID部分
    OLD_CONTENT=$(cat "$VERSION_DISPLAY_FILE")
    
    # 如果原内容包含括号，替换括号内的内容；否则在末尾添加commit ID
    if [[ "$OLD_CONTENT" =~ \(.*\) ]]; then
        # 替换括号内的内容为新的commit ID
        NEW_CONTENT=$(echo "$OLD_CONTENT" | sed "s/([^)]*)/($LS_UXP)/")
    else
        # 在末尾添加commit ID（确保有空格）
        NEW_CONTENT="$OLD_CONTENT ($LS_UXP)"
    fi
    
    # 写入更新后的内容
    echo "$NEW_CONTENT" > "$VERSION_DISPLAY_FILE"
    echo "Version display updated: $NEW_CONTENT"
else
    echo "Warning: version_display.txt file not found!"
fi

echo

# 确保回到脚本所在的根目录
cd "$(dirname "$0")"

# 选择当前系统
echo "Please select your current system:"
echo "1) Windows"
echo "2) Linux/FreeBSD/illumos"
echo "3) macOS"
read -p "Enter option (1/2/3): " SYSTEM_TYPE

# 删除现有的.mozconfig文件（如果存在）
if [ -f .mozconfig ]; then
    rm .mozconfig
fi

case $SYSTEM_TYPE in
    1|Windows|windows) 
        SYSTEM_DIR="windows"
        ;;
    2|Linux|linux|FreeBSD|freebsd|illumos|Illumos) 
        SYSTEM_DIR="linux"
        ;;
    3|macos|MacOS|mac) 
        SYSTEM_DIR="macos"
        ;;
    *) 
        echo "Invalid option, creating blank .mozconfig file..."
        touch .mozconfig
        echo "Please manually edit .mozconfig file to configure build options"
        echo
        ;;
esac

# 如果选择了有效的系统，继续选择架构和配置
if [ -n "$SYSTEM_DIR" ]; then
    # 检查系统目录是否存在
    if [ ! -d "mozconfigs/$SYSTEM_DIR" ]; then
        echo "Error: mozconfigs/$SYSTEM_DIR directory does not exist!"
        echo "Creating blank .mozconfig file..."
        touch .mozconfig
        echo "Please manually edit .mozconfig file to configure build options"
    else
        # 显示可用的架构
        echo "Available architectures for $SYSTEM_DIR:"
        ARCH_DIRS=($(ls -d mozconfigs/$SYSTEM_DIR/*/ 2>/dev/null | sed 's|/$||' | xargs -n1 basename))
        
        if [ ${#ARCH_DIRS[@]} -eq 0 ]; then
            echo "No architecture directories found!"
            echo "Creating blank .mozconfig file..."
            touch .mozconfig
            echo "Please manually edit .mozconfig file to configure build options"
        else
            # 显示架构选项
            for i in "${!ARCH_DIRS[@]}"; do
                echo "$((i+1))) ${ARCH_DIRS[i]}"
            done
            
            read -p "Select architecture [1-${#ARCH_DIRS[@]}]: " ARCH_OPTION
            
            # 验证架构选择
            if [[ "$ARCH_OPTION" =~ ^[0-9]+$ ]] && [ "$ARCH_OPTION" -ge 1 ] && [ "$ARCH_OPTION" -le ${#ARCH_DIRS[@]} ]; then
                ARCH_DIR="${ARCH_DIRS[$((ARCH_OPTION-1))]}"
                
                # 显示可用的.mozconfig文件
                echo "Available .mozconfig files for $SYSTEM_DIR/$ARCH_DIR:"
                MOZCONFIG_FILES=($(ls mozconfigs/$SYSTEM_DIR/$ARCH_DIR/*.mozconfig 2>/dev/null))
                
                if [ ${#MOZCONFIG_FILES[@]} -eq 0 ]; then
                    echo "No .mozconfig files found!"
                    echo "Creating blank .mozconfig file..."
                    touch .mozconfig
                    echo "Please manually edit .mozconfig file to configure build options"
                else
                    # 显示.mozconfig文件选项
                    for i in "${!MOZCONFIG_FILES[@]}"; do
                        filename=$(basename "${MOZCONFIG_FILES[i]}")
                        echo "$((i+1))) $filename"
                    done
                    
                    read -p "Select .mozconfig file [1-${#MOZCONFIG_FILES[@]}]: " MOZCONFIG_OPTION
                    
                    # 验证.mozconfig文件选择
                    if [[ "$MOZCONFIG_OPTION" =~ ^[0-9]+$ ]] && [ "$MOZCONFIG_OPTION" -ge 1 ] && [ "$MOZCONFIG_OPTION" -le ${#MOZCONFIG_FILES[@]} ]; then
                        SELECTED_FILE="${MOZCONFIG_FILES[$((MOZCONFIG_OPTION-1))]}"
                        
                        # 复制选中的文件到根目录并重命名为.mozconfig
                        cp "$SELECTED_FILE" .mozconfig
                        echo "Selected configuration: $(basename "$SELECTED_FILE")"
                        echo "Configuration file copied to .mozconfig"
                    else
                        echo "Invalid selection, creating blank .mozconfig file..."
                        touch .mozconfig
                        echo "Please manually edit .mozconfig file to configure build options"
                    fi
                fi
            else
                echo "Invalid architecture selection, creating blank .mozconfig file..."
                touch .mozconfig
                echo "Please manually edit .mozconfig file to configure build options"
            fi
        fi
    fi
fi

echo

# 确保回到脚本所在的根目录
cd "$(dirname "$0")"

# 询问用户要执行的操作
echo "Please select the action to perform:"
echo "1) configure"
echo "2) build"
echo "3) run"
echo "4) clobber"
read -p "Enter option (1/2/3/4): " ACTION

# 确保mach脚本有执行权限
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
        echo "Packageing..."
        ./mach package
        ;;
    *) 
        echo "Invalid option, no action performed."
        ;;
esac

echo
echo "Welcome to LeafSheep!"