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
VERSION=$(tail -n 1 LSVERSION)

# 输出当前代码的频道和版本号
echo "Current LeafSheep browser information:"
echo "Channel: $CHANNEL (Stable/Latest/Rolling)"
echo "Version: $VERSION"
echo

# 询问用户是否同步UXP平台
read -p "Do you need to sync UXP platform? (y/n): " SYNC_UXP

if [ "$SYNC_UXP" = "y" ] || [ "$SYNC_UXP" = "Y" ]; then
    # 根据LSVERSION频道设置默认UXP频道
    case $CHANNEL in
        STABLE|stable|Stable) 
            DEFAULT_UXP_CHANNEL="1"
            DEFAULT_UXP_NAME="RB"
            ;;
        LATEST|latest|Latest) 
            DEFAULT_UXP_CHANNEL="2"
            DEFAULT_UXP_NAME="RC"
            ;;
        ROLLING|rolling|Rolling) 
            DEFAULT_UXP_CHANNEL="3"
            DEFAULT_UXP_NAME="RO"
            ;;
        *) 
            DEFAULT_UXP_CHANNEL="3"
            DEFAULT_UXP_NAME="RO"
            ;;
    esac
    
    echo "Please select UXP version channel (default: $DEFAULT_UXP_NAME for $CHANNEL):"
    echo "1) RB"
    echo "2) RC"
    echo "3) RO"
    read -p "Enter option (1/2/3) [default: $DEFAULT_UXP_CHANNEL]: " UXP_CHANNEL
    
    # 如果用户留空，使用默认值
    if [ -z "$UXP_CHANNEL" ]; then
        UXP_CHANNEL=$DEFAULT_UXP_CHANNEL
        echo "Using default option: $DEFAULT_UXP_CHANNEL ($DEFAULT_UXP_NAME)"
    fi
    
    # 确保UXP文件夹存在
    mkdir -p UXP
    cd UXP
    
    case $UXP_CHANNEL in
        1|RB|rb) 
            echo "Downloading"
            # 获取最新的release tar.gz文件链接
            # 使用更精确的方式提取tarball_url
            LATEST_RELEASE=$(curl -s https://repo.palemoon.org/api/v1/repos/MoonchildProductions/UXP/releases/latest)
            DOWNLOAD_URL=$(echo $LATEST_RELEASE | grep -o '"tarball_url":"[^"]*' | cut -d '"' -f 4)
            wget -O uxp-latest.tar.gz "$DOWNLOAD_URL"
            tar -xzf uxp-latest.tar.gz --strip-components=1
            rm uxp-latest.tar.gz
            ;;
        2|RC|rc) 
            echo "Downloading"
            # 获取最新的tag tar.gz文件链接
            # 注意：这里需要根据实际情况修改获取最新tag的方式
            # 示例使用curl和jq来获取最新tag，需要安装这些工具
            LATEST_TAG=$(curl -s https://repo.palemoon.org/api/v1/repos/MoonchildProductions/UXP/tags | grep -o 'name":.*' | head -n 1 | cut -d '"' -f 3)
            DOWNLOAD_URL="https://repo.palemoon.org/MoonchildProductions/UXP/archive/$LATEST_TAG.tar.gz"
            wget -O uxp-latest-tag.tar.gz "$DOWNLOAD_URL"
            tar -xzf uxp-latest-tag.tar.gz --strip-components=1
            rm uxp-latest-tag.tar.gz
            ;;
        3|RO|ro) 
            echo "Downloading UXP using git clone..."
            git clone https://repo.palemoon.org/MoonchildProductions/UXP.git .
            ;;
        *) 
            echo "Invalid option, please try again."
            ;;
    esac
    
    cd ..
    
    
    # 移动UXP文件夹内容到platform
    echo "Moving UXP content to platform folder..."
    mv UXP/* platform/
    
    # 删除空的UXP文件夹
    rmdir UXP
    echo "UXP sync completed!"
echo
fi

# 确保回到脚本所在的根目录
cd "$(dirname "$0")"

# 让用户选择当前系统
echo "Please select your current system:"
echo "1) Windows"
echo "2) Linux/FreeBSD/illumos"
echo "3) Other systems"
read -p "Enter option (1/2/3): " SYSTEM_TYPE

# 删除现有的.mozconfig文件（如果存在）
if [ -f .mozconfig ]; then
    rm .mozconfig
fi

case $SYSTEM_TYPE in
    1|Windows|windows) 
        echo "Configuring Windows build environment..."
        cp .mozconfig.win .mozconfig
        ;;
    2|Linux|linux|FreeBSD|freebsd|illumos|Illumos) 
        echo "Configuring Linux/FreeBSD/illumos build environment..."
        cp .mozconfig.unix .mozconfig
        ;;
    3|Other|other) 
        echo "Creating blank .mozconfig file..."
        touch .mozconfig
        echo "Please manually edit .mozconfig file to configure build options"
        ;;
    *) 
        echo "Invalid option, creating blank .mozconfig file..."
        touch .mozconfig
        echo "Please manually edit .mozconfig file to configure build options"
        ;;
esac
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
    *) 
        echo "Invalid option, no action performed."
        ;;
esac

echo
echo "Thank you for building LeafSheep web browser!"