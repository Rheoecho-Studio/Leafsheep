#!/bin/bash

# 设置变量
APP_ID="org.rheoecho.leafsheep"
MANIFEST="${APP_ID}.yml"
BUILD_DIR="build-dir"
EXPORT_DIR="export"
BUNDLE_NAME="leafsheep.flatpak"

# 清理旧的构建
rm -rf $BUILD_DIR $EXPORT_DIR $BUNDLE_NAME

# 安装Flatpak运行时（如果需要）
flatpak install -y flathub org.freedesktop.Platform//24.08 org.freedesktop.Sdk//24.08
flatpak install -y flathub org.freedesktop.Platform.GL.default//24.08
flatpak install -y flathub org.freedesktop.Platform.VAAPI.Intel//24.08
flatpak install -y flathub org.freedesktop.Platform.openh264//2.4.1

# 构建
flatpak-builder \
    --force-clean \
    --ccache \
    --keep-build-dirs \
    --repo=$EXPORT_DIR \
    $BUILD_DIR \
    $MANIFEST

# 检查构建是否成功
if [ $? -eq 0 ]; then
    echo "Build successful!"
    
    # 创建仓库
    flatpak build-export $EXPORT_DIR $BUILD_DIR
    
    # 创建Bundle
    flatpak build-bundle \
        $EXPORT_DIR \
        $BUNDLE_NAME \
        $APP_ID
    
    echo "Bundle created: $BUNDLE_NAME"
    
    # 可选：安装到本地系统测试
    flatpak install -y --user $BUNDLE_NAME
    
    # 运行测试
    echo "Testing LeafSheep Flatpak..."
    flatpak run $APP_ID
else
    echo "Build failed!"
    exit 1
fi