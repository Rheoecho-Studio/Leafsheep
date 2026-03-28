#! /bin/sh
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

MOZ_APP_BASENAME=Leafsheep
MOZ_APP_VENDOR=RheoEcho
MOZ_PHOENIX=1
MOZ_AUSTRALIS=1
MC_BASILISK=1
MOZ_UPDATER=

if test "$MOZ_WIDGET_TOOLKIT" = "windows" -o \
        "$MOZ_WIDGET_TOOLKIT" = "gtk2" -o \
        "$MOZ_WIDGET_TOOLKIT" = "gtk3"; then
  MOZ_BUNDLED_FONTS=1
fi

# 从LSVERSION文件读取版本信息
# LSVERSION格式：
# 第一行：频道
# 第二行：版本号 
# 第三行：服务包 
# 第四行：UXP commit ID 

LSVERSION_FILE="${_topsrcdir}/LSVERSION"
if test -f "$LSVERSION_FILE"; then
    # 读取LSVERSION文件内容
    CHANNEL=$(head -n 1 "$LSVERSION_FILE")
    VERSION=$(sed -n '2p' "$LSVERSION_FILE")
    SERVICE_PACK=$(sed -n '3p' "$LSVERSION_FILE")
    COMMIT_ID=$(sed -n '4p' "$LSVERSION_FILE")
    
    # 如果COMMIT_ID为空，设置为dev
    if [ -z "$COMMIT_ID" ]; then
        COMMIT_ID="dev"
    fi
    
    # 提取SP数字（去掉SP前缀）
    SP_NUMBER=$(echo "$SERVICE_PACK" | sed 's/SP//')
    
    # MOZ_APP_VERSION
    MOZ_APP_VERSION="$VERSION.$SP_NUMBER"
    
    # MOZ_APP_VERSION_DISPLAY: 格式为 版本号 SP数 (kernel-commit_id)
    MOZ_APP_VERSION_DISPLAY="$VERSION $SERVICE_PACK (kernel-$COMMIT_ID)"
else
    # 如果LSVERSION文件不存在，回退到原来的逻辑
    MOZ_APP_VERSION=`cat ${_topsrcdir}/$MOZ_BUILD_APP/config/version.txt`
    MOZ_APP_VERSION_DISPLAY=`cat ${_topsrcdir}/$MOZ_BUILD_APP/config/version_display.txt`
fi

#MOZ_EXTENSIONS_DEFAULT=" gio"

# MOZ_APP_DISPLAYNAME will be set by branding/configure.sh
# MOZ_BRANDING_DIRECTORY is the default branding directory used when none is
# specified. It should never point to the "official" branding directory.
MOZ_BRANDING_DIRECTORY=leafsheep/branding/unofficial
MOZ_OFFICIAL_BRANDING_DIRECTORY=leafsheep/branding/official
MOZ_APP_ID={ec8030f7-c20a-464f-9b0e-13a3a9e97384}
# This should usually be the same as the value MAR_CHANNEL_ID.
# If more than one ID is needed, then you should use a comma separated list
# of values.
ACCEPTED_MAR_CHANNEL_IDS=unofficial,technology,rolling,release
# The MAR_CHANNEL_ID must not contain the following 3 characters: ",\t "
MAR_CHANNEL_ID=unofficial

# Features
MOZ_PROFILE_MIGRATOR=1
MOZ_APP_STATIC_INI=1
MOZ_WEBGL_CONFORMANT=1
MOZ_JSDOWNLOADS=1
MOZ_WEBRTC=1
MOZ_DEVTOOLS=1
MOZ_SERVICES_COMMON=1
MOZ_SERVICES_SYNC=1
MOZ_GAMEPAD=1
MOZ_AV1=1
MOZ_SECURITY_SQLSTORE=1

if test "$OS_ARCH" = "WINNT" -o \
        "$OS_ARCH" = "Darwin"; then
  MOZ_CAN_DRAW_IN_TITLEBAR=1
fi