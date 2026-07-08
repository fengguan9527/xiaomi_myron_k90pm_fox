#!/bin/bash
# 本脚本是 OrangeFox Recovery 项目的一部分
# 版权所有 (C) 2020-2026 OrangeFox Recovery 项目
#
# OrangeFox 是自由软件：你可以自由地重新发布和/或修改
# 它遵循 GNU 通用公共许可证（GPL）第 3 版，或
# （按你的选择）任何更新版本。
#
# OrangeFox 分发的目的是希望它有用，
# 但不提供任何担保；甚至没有对
# 适销性或特定用途适用性的隐含担保。详情请参阅
# GNU 通用公共许可证。
#
# 本软件基于 GPL 第 3 版或更高版本发布。
# 详见 <http://www.gnu.org/licenses/>。
#
# 如果你使用此脚本或其任何部分，请保持此声明。
#
# 设备: Xiaomi myron (POCO F8 Ultra / Redmi K90 Pro Max)
# SoC  : Snapdragon 8 Elite Gen 5 (SM8850 / sun)
# 分支 : OrangeFox 14.1

# 输出加载成功提示（用于调试确认 vendorsetup.sh 被正确 source）
echo vendorsetup load successfully
# 强制设置 C 语言环境（避免本地化对构建脚本的影响）
export LC_ALL="C"

# ─── A/B 分区 + 独立 recovery 分区架构 ─────────────────────────────────────
# 声明本设备为 A/B 分区设备
export FOX_AB_DEVICE=1
# A/B 设备使用独立 recovery 分区（而非 recovery 兼任 boot）
export OF_AB_DEVICE_WITH_RECOVERY_PARTITION=1
# 声明本设备为 Virtual A/B 设备（Android 动态分区压缩 OTA）
export FOX_VIRTUAL_AB_DEVICE=1

# ─── device-mapper 控制工具 ─────────────────────────────────────────────────
# 使用 dmctl 工具管理 device-mapper 设备（动态分区映射）
export OF_USE_DMCTL=1

# ─── Boot 控制接口 ─────────────────────────────────────────────────────────
# 使用 AIDL 接口与 boot 控制 HAL 通信（Android 12+ 标准）
export OF_USE_AIDL_BOOT_CONTROL=1

# ─── 压缩工具 / 二进制文件 ─────────────────────────────────────────────────
# 使用 LZ4 压缩算法（ramdisk 压缩）
export OF_USE_LZ4_COMPRESSION=1
# 使用自定义 tar 二进制（用于备份/恢复归档）
export FOX_USE_TAR_BINARY=1
# 使用自定义 sed 二进制（文本流处理）
export FOX_USE_SED_BINARY=1
# 使用自定义 LZ4 二进制（解压缩支持）
export FOX_USE_LZ4_BINARY=1
# 使用自定义 Zstd 二进制（高压缩比算法）
export FOX_USE_ZSTD_BINARY=1
# 使用自定义 date 二进制（时间日期处理）
export FOX_USE_DATE_BINARY=1
# 使用自定义 grep 二进制（文本搜索）
export FOX_USE_GREP_BINARY=1
# 不使用 busybox（使用 toolbox + 独立工具替代，更轻量）
export FOX_USE_BUSYBOX_BINARY=0
# 使用 XZ Utils 压缩工具（.xz 格式支持）
export FOX_USE_XZ_UTILS=1
# 使用 EROFS 文件系统检查工具（fsck.erofs）
export FOX_USE_FSCK_EROFS_BINARY=1
# 使用 patchelf 工具（修改 ELF 二进制动态链接器）
export FOX_USE_PATCHELF_BINARY=1
# 使用更新版 magiskboot 工具（解包/打包 boot 镜像）
export FOX_USE_UPDATED_MAGISKBOOT=1
# 将 Magisk 安装器移动到 ramdisk 中执行
export FOX_MOVE_MAGISK_INSTALLER_TO_RAMDISK=1

# ─── 兼容性与特殊处理 ──────────────────────────────────────────────────────
# 启用 TWRP 兼容模式（兼容旧版 TWRP 的 zip 包格式）
export OF_TWRP_COMPATIBILITY_MODE=1
# 解密完成后不自动重新加载 UI（避免闪烁）
export OF_NO_RELOAD_AFTER_DECRYPTION=1
# 跳过 Treble 兼容性检查（不验证 vendor 接口版本）
export OF_NO_TREBLE_COMPATIBILITY_CHECK=1
# 删除 AromaFM 文件管理器（不包含，减小 recovery 体积）
export FOX_DELETE_AROMAFM=1
# 不显示 MIUI 补丁警告提示
export OF_NO_MIUI_PATCH_WARNING=1
# 默认禁用 MIUI OTA 更新选项
export OF_DISABLE_MIUI_OTA_BY_DEFAULT=1

# ─── 设置存储 ──────────────────────────────────────────────────────────────
# OrangeFox 设置文件存储根目录（存于 /data/recovery）
export FOX_SETTINGS_ROOT_DIRECTORY=/data/recovery
# 允许在解密前就加载早期设置
export FOX_ALLOW_EARLY_SETTINGS_LOAD=1

# ─── KernelSU 支持 ─────────────────────────────────────────────────────────
# 启用 KernelSU 安装支持
export FOX_ENABLE_KERNELSU_SUPPORT=1
# 启用 KernelSU Next 安装支持
export FOX_ENABLE_KERNELSU_NEXT_SUPPORT=1
# 启用 sukisu ultra 安装支持
export FOX_ENABLE_SUKISU_SUPPORT=1

# ─── 显示 / 刘海处理 ────────────────────────────────────────────────────────
# 隐藏挖孔屏/刘海：强制状态栏绘制纯黑背景（fox_16.0 可能仅在 shell 环境变量中生效）
export OF_HIDE_NOTCH=1
# 状态栏高度：141 像素
export OF_STATUS_H=141

# ─── OrangeFox 主题 / 强调色 ───────────────────────────────────────────────
# 启用 OrangeFox SPR（系统属性恢复）特性
export FOX_SPR=1

# ─── 维护者 / 设备变体信息 ────────────────────────────────────────────────
# 构建目标设备代号
export FOX_BUILD_DEVICE="myron"
# 设备变体标识名
export FOX_VARIANT="Xiaomi_myron_K90_ProMax"
# 维护者补丁版本号（格式：年月日，如 250708）
export FOX_MAINTAINER_PATCH_VERSION=$(date +%y%m%d)
# 维护者标识
export OF_MAINTAINER="haohao3001@github"

# ─── Magisk 配置 ───────────────────────────────────────────────────────────
# Magisk 安装包路径
export OF_MAGISK="/tmp/misc/Magisk.zip"
# 指定使用的 Magisk zip 包路径
export FOX_USE_SPECIFIC_MAGISK_ZIP="/tmp/misc/Magisk.zip"
