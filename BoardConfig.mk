#
# 版权所有 (C) 2026 OrangeFox Recovery 项目
# 设备 : 小米 POCO F8 Ultra / Redmi K90 Pro Max (myron)
# SoC  : 骁龙 8 Elite Gen 5 (SM8850 / sun)
# 分支 : OrangeFox 14.1
#
# 以下配置已从真机验证确认:
#   fastboot getvar all  (分区大小、槽位、逻辑分区标志)
#   adb shell getprop    (平台、主板、first_api_level=35、fbe 加密参数)
#   adb shell /proc/cmdline + /proc/bootconfig
#   adb shell /odm vintf manifests (keymint v3、weaver、振动器 fqname)
#
# SPDX 许可证标识符: Apache-2.0
#

# 设备树路径变量，指向当前设备配置目录
DEVICE_PATH := device/xiaomi/myron

# ─────────────────────────────────────────────────────────
# 构建规则
# ─────────────────────────────────────────────────────────
# 允许缺失依赖项（recovery 环境下某些 Android 组件不需要）
ALLOW_MISSING_DEPENDENCIES := true
# 允许重复的构建规则（避免因模块重复定义导致构建失败）
BUILD_BROKEN_DUP_RULES := true
# 允许预编译 ELF 文件的 PRODUCT_COPY_FILES 规则
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
# 将 RTIC_MPGEN 环境变量透传给 Ninja 构建系统
BUILD_BROKEN_NINJA_USES_ENV_VARS += RTIC_MPGEN
# 跳过这些 soong 模块的插件校验（recovery 专用库）
BUILD_BROKEN_PLUGIN_VALIDATION := soong-libaosprecovery_defaults soong-libguitwrp_defaults soong-libminuitwrp_defaults soong-vold_defaults

# ─────────────────────────────────────────────────────────
# 架构 — Oryon CPU (骁龙 8 Elite Gen 5)
# 已验证: cpu-abi=arm64-v8a (fastboot), ro.product.cpu.abi=arm64-v8a (getprop)
# ─────────────────────────────────────────────────────────
# 目标架构：64 位 ARM
TARGET_ARCH             := arm64
# ARMv8-A 指令集变体
TARGET_ARCH_VARIANT     := armv8-a
# 应用程序二进制接口：arm64-v8a
TARGET_CPU_ABI          := arm64-v8a
# 第二 ABI 为空（纯 64 位，不支持 32 位）
TARGET_CPU_ABI2         :=
# 通用 CPU 变体（运行时由 oryon 优化）
TARGET_CPU_VARIANT      := generic
# 运行时针对 Oryon 微架构（骁龙 8 Elite 定制核心）进行调度优化
TARGET_CPU_VARIANT_RUNTIME := oryon

# 启用 cpusets（CPU 分组调度）
ENABLE_CPUSETS    := true
# 启用调度增强（SCHEDBOOST）
ENABLE_SCHEDBOOST := true

# ─────────────────────────────────────────────────────────
# 平台信息
# 已验证: ro.board.platform=xiaomi_sm8750, ro.product.board=sun (getprop)
# ─────────────────────────────────────────────────────────
# 产品平台代号：canoe（高通内部代号）
PRODUCT_PLATFORM      := canoe
# Bootloader 主板名称
TARGET_BOOTLOADER_BOARD_NAME := canoe
# 不编译 bootloader（使用预编译的 bootloader）
TARGET_NO_BOOTLOADER  := true
# 使用 UEFI 固件启动（高通新平台特性）
TARGET_USES_UEFI      := true

# 板级平台标识
TARGET_BOARD_PLATFORM := canoe
# GPU 型号：Adreno 840
TARGET_BOARD_PLATFORM_GPU := qcom-adreno840
# 将该平台加入高通平台列表
QCOM_BOARD_PLATFORMS  += canoe

# ─────────────────────────────────────────────────────────
# 内核 — 预编译 GKI 6.12, boot header v4, vendor_boot 风格
# 已验证:
#   ro.boot.hardware.cpu.pagesize=4096 (getprop)  — 页大小 4KB
#   kernel 存放于 vendor_boot 中 (boot.img 中 kernel_size=0)
#   ro.bootimage.build.version.sdk=36 → BOARD_BOOT_HEADER_VERSION=4
# ─────────────────────────────────────────────────────────
# 内核架构：ARM64
TARGET_KERNEL_ARCH        := arm64
# 内核头架构：ARM64
TARGET_KERNEL_HEADER_ARCH := arm64
# 内核镜像名称
BOARD_KERNEL_IMAGE_NAME   := Image
# Boot 镜像头部版本 4（Android 13+ 标准）
BOARD_BOOT_HEADER_VERSION := 4
# 内核页大小：4096 字节（4KB）
BOARD_KERNEL_PAGESIZE     := 4096
# 使用 Clang 编译器构建内核
TARGET_KERNEL_CLANG_COMPILE := true
# 指向预编译的二进制内核文件
TARGET_PREBUILT_KERNEL    := $(DEVICE_PATH)/prebuilt/kernel
# mkbootimg 参数：添加 boot header 版本
BOARD_MKBOOTIMG_ARGS      += --header_version $(BOARD_BOOT_HEADER_VERSION)
# mkbootimg 参数：设置页大小
BOARD_MKBOOTIMG_ARGS      += --pagesize $(BOARD_KERNEL_PAGESIZE)
# 使用 LZ4 压缩 ramdisk（减小体积，加快加载）
BOARD_RAMDISK_USE_LZ4     := true

# 内核存在于 vendor_boot 分区中 —— 不要将其嵌入 recovery.img
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
# 内核命令行参数为空 —— 所有启动参数通过 bootconfig 机制传递
# （已验证: /proc/cmdline 与 /proc/bootconfig 对比确认）
BOARD_KERNEL_CMDLINE :=

# ─────────────────────────────────────────────────────────
# A/B 分区架构 — 独立 recovery 分区
#
# 验证依据 (fastboot getvar all):
#   partition-size:recovery_a = 0x6400000 (104857600 = 100MB) — recovery 分区大小 100MB
#   has-slot:recovery = yes                               — recovery 支持 A/B 双槽位
#   is-logical:recovery_a = no                            — 物理分区，不在 super 中
#   BOARD_USES_RECOVERY_AS_BOOT = false                   — recovery 不由 boot 兼任
#
# AB_OTA_PARTITIONS 来源于原厂 ROM getprop 验证:
#   ro.product.ab_ota_partitions:
#   boot,dtbo,init_boot,odm,product,system,system_dlkm,
#   system_ext,vbmeta,vbmeta_system,vendor,vendor_boot,vendor_dlkm
# ─────────────────────────────────────────────────────────
# 启用 A/B OTA 更新器
AB_OTA_UPDATER   := true
# A/B OTA 管理的分区列表（支持无缝更新的分区）
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    init_boot \
    odm \
    product \
    system \
    system_dlkm \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor \
    vendor_boot \
    vendor_dlkm

# recovery 不作为 boot 分区使用（独立 recovery 分区架构）
BOARD_USES_RECOVERY_AS_BOOT             := false
# recovery 需要与 bootloader 控制接口通信（用于槽位切换等操作）
BOARD_RECOVERY_NEEDS_BOOTLOADER_CONTROL := true

# ─────────────────────────────────────────────────────────
# Android 验证启动 (AVB — Android Verified Boot)
# 验证依据:
#   ro.boot.verifiedbootstate=orange (设备已解锁, getprop)
#   ro.boot.vbmeta.avb_version=1.3           — AVB 协议版本 1.3
#   secure=no (fastboot getvar)              — 安全启动已关闭
#   → 编译阶段使用测试密钥签名即可，无需设备端验证
# ─────────────────────────────────────────────────────────
# 启用 AVB
BOARD_AVB_ENABLE                           := true
# recovery 镜像 AVB 签名密钥路径（使用 AOSP 测试密钥）
BOARD_AVB_RECOVERY_KEY_PATH                := external/avb/test/data/testkey_rsa4096.pem
# recovery 签名算法：SHA256 哈希 + RSA4096 非对称加密
BOARD_AVB_RECOVERY_ALGORITHM               := SHA256_RSA4096
# 全局 AVB 签名算法
BOARD_AVB_ALGORITHM                        := SHA256_RSA4096
# recovery 防回滚索引（0 表示不检查回滚）
BOARD_AVB_RECOVERY_ROLLBACK_INDEX          := 0
# 防回滚索引在 recovery 镜像中的存储位置
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 0

# ─────────────────────────────────────────────────────────
# 分区大小 — 全部从 fastboot getvar all 验证确认
#   recovery_a  : 0x6400000  = 104857600  (100MB) ← 已修正（原先错误值为 100663296）
#   boot_a      : 0x6000000  = 100663296  (96MB)
#   vendor_boot : 0x6000000  = 100663296  (96MB)
#   init_boot_a : 0x800000   = 8388608    (8MB)
#   super       : 0x360000000= 14495514624 (13.5GB)
# ─────────────────────────────────────────────────────────
# 启用分区属性覆写分离（system/product 等各自有独立 build.prop）
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true
# boot 镜像分区大小：100663296 字节 ≈ 96MB
BOARD_BOOTIMAGE_PARTITION_SIZE         := 100663296
# init_boot 镜像分区大小：8388608 字节 ≈ 8MB
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE   := 8388608
# vendor_boot 镜像分区大小：100663296 字节 ≈ 96MB
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE  := 100663296
# recovery 镜像分区大小：104857600 字节 = 100MB
BOARD_RECOVERYIMAGE_PARTITION_SIZE     := 104857600

# 支持大文件系统（>4GB 文件）
BOARD_HAS_LARGE_FILESYSTEM         := true
# userdata 分区默认文件系统类型：F2FS（闪存友好型文件系统）
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
# 支持 ext4 文件系统镜像生成
TARGET_USERIMAGES_USE_EXT4         := true
# 支持 F2FS 文件系统镜像生成
TARGET_USERIMAGES_USE_F2FS         := true

# ─────────────────────────────────────────────────────────
# 动态分区 (super 超级分区)
# 已验证 (fastboot getvar, is-logical=yes 标识为逻辑分区):
#   system, system_ext, product, vendor, vendor_dlkm, odm,
#   system_dlkm, mi_ext, neo_inject
#
# 注意事项:
#   OrangeFox R12.1 的 PARTITION_LIST 最多支持 7 个分区名。
#   system_dlkm 必须包含 (is-logical=yes 且在 AB_OTA 中)。
#   mi_ext 是小米专用分区，不在 AB_OTA 中 → 排除。
#   neo_inject 没有 _b 槽位 → 不由 OrangeFox 管理。
# ─────────────────────────────────────────────────────────
# super 分区总大小：14495514624 字节 ≈ 13.5GB
BOARD_SUPER_PARTITION_SIZE := 14495514624
# 动态分区组名：xiaomi_dynamic_partitions
BOARD_SUPER_PARTITION_GROUPS := xiaomi_dynamic_partitions
# 该分区组内所有逻辑分区的总大小
BOARD_XIAOMI_DYNAMIC_PARTITIONS_SIZE := 14491320320
# 该分区组管理的逻辑分区列表
BOARD_XIAOMI_DYNAMIC_PARTITIONS_PARTITION_LIST := \
    system \
    system_ext \
    product \
    vendor \
    vendor_dlkm \
    odm \
    system_dlkm

# 文件系统类型配置
# vendor 镜像输出目录
TARGET_COPY_OUT_VENDOR     := vendor
# 启用 vendor_dlkm 独立镜像
BOARD_USES_VENDOR_DLKMIMAGE := true
# vendor_dlkm 镜像输出目录
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
# vendor_dlkm 文件系统类型：EROFS（增强型只读文件系统）
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs

# ODM — 显式声明 (符合 SM8850 参考设计模式)
# 单一数据源: 仅 recovery/root/odm/，顶层 odm/ 已移除
TARGET_COPY_OUT_ODM             := odm
# ODM 镜像文件系统类型：EROFS
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs

# 所有逻辑分区统一使用 EROFS (已验证于 recovery.fstab)
# (TARGET_COPY_OUT_ODM 上面的声明优先; foreach 循环设置相同值)
# 将分区名转换为大写，用于后续 foreach 变量拼接
BOARD_PARTITION_LIST := $(call to-upper, $(BOARD_XIAOMI_DYNAMIC_PARTITIONS_PARTITION_LIST))
# 为每个逻辑分区设置 IMAGE_FILE_SYSTEM_TYPE 为 EROFS
$(foreach p, $(BOARD_PARTITION_LIST), $(eval BOARD_$(p)IMAGE_FILE_SYSTEM_TYPE := erofs))
# 为每个逻辑分区设置 TARGET_COPY_OUT 路径
$(foreach p, $(BOARD_PARTITION_LIST), $(eval TARGET_COPY_OUT_$(p) := $(call to-lower,$(p))))

# ─────────────────────────────────────────────────────────
# 加密 / FBE (基于文件的加密)
# 已验证 (getprop):
#   fbe.contents=aes-256-xts                             — 文件内容加密算法
#   fbe.filenames=aes-256-cts:v2+inlinecrypt_optimized+wrappedkey_v0 — 文件名加密
#   metadata.contents=aes-256-xts                        — 元数据内容加密
#   metadata.filenames=wrappedkey_v0                     — 元数据密钥封装方式
#   prepdecrypt.setpatch=true                            — 预解密补丁模式
# 已验证 (odm vintf): keymint v3 (strongbox NXP JavaCard 安全元件)
#   weaver-service 运行路径 /odm/bin/hw/android.hardware.weaver-service
# ─────────────────────────────────────────────────────────
# 启用 metadata 分区（存储加密密钥信息）
BOARD_USES_METADATA_PARTITION    := true
# 使用高通 QCOM FBE 解密方案
BOARD_USES_QCOM_FBE_DECRYPTION   := true
# 启用 TWRP 加密支持
TW_INCLUDE_CRYPTO                := true
# 启用 TWRP FBE 加密支持
TW_INCLUDE_CRYPTO_FBE            := true
# 启用 metadata 加密解密支持
TW_INCLUDE_FBE_METADATA_DECRYPT  := true

# KeyMint AIDL — v4 QTI TEE + v3 ODM strongbox (NXP/Thales JavaCard)
# 使用 vendor 分区中的 KeyMint HAL 进行加密操作
TW_CRYPTO_USE_VENDOR_KEYMINT      := true
# KeyMint 客户端连接超时：4000ms（标准设备为 2000ms，
# 此处增大以适配 NXP JavaCard 强盒较慢的初始化过程）
TW_KEYMINT_CLIENT_CONNECT_TIMEOUT := 4000
# 使用 fscrypt 策略版本 2（Android 12+ 标准）
TW_USE_FSCRYPT_POLICY            := 2

# 安全补丁绕过（抗回滚 workaround）
# 已验证: version-os=99.87.36 (fastboot), ro.build.version.release=99.87.36 (getprop)
# 将平台版本设为极高值 99.87.36，绕过版本降级检查
PLATFORM_VERSION              := 99.87.36
# 上一个稳定平台版本
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
# 安全补丁日期设为 2099-12-31，永远是最新的补丁级别
PLATFORM_SECURITY_PATCH      := 2099-12-31
# Vendor 安全补丁级别
VENDOR_SECURITY_PATCH        := $(PLATFORM_SECURITY_PATCH)
# Boot 安全补丁级别
BOOT_SECURITY_PATCH          := $(PLATFORM_SECURITY_PATCH)

# ─────────────────────────────────────────────────────────
# Recovery 配置
# ─────────────────────────────────────────────────────────
# Recovery UI 像素格式：RGBX_8888 (32 位色深，忽略 Alpha 通道)
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
# 修复高通平台 RTC（实时时钟）问题
TARGET_RECOVERY_QCOM_RTC_FIX := true
# Recovery 分区挂载表文件路径
TARGET_RECOVERY_FSTAB        := $(DEVICE_PATH)/recovery.fstab
# 启用 FastbootD（Userspace Fastboot，用于动态分区刷写）
TW_INCLUDE_FASTBOOTD         := true
# 跳过额外的 fstab 文件（只使用 recovery.fstab）
TW_SKIP_ADDITIONAL_FSTAB     := true
# 追加 system.prop 中的系统属性到构建
TARGET_SYSTEM_PROP          += $(DEVICE_PATH)/system.prop

# ─────────────────────────────────────────────────────────
# 显示配置
# 已验证:
#   ro.boot.panel_build_id=Pc0, panel_cell_id=AL7557J01UB961 (getprop) — 面板型号
#   分辨率 1200x2608 (来自 TWRP ramdisk 中的 variant-script.sh)
#   y_offset=111, h_offset=-111 确认自 bootconfig
#   TW_BRIGHTNESS_PATH 确认自 /sys/class/backlight/panel0-backlight
#   TW_MAX_BRIGHTNESS=4094 (小米 OLED 面板标准最大亮度值)
# ─────────────────────────────────────────────────────────
# 使用 Vulkan 图形 API 渲染（Android 13+ recovery 标准）
TARGET_USES_VULKAN       := true
# TWRP 主题：竖屏高 DPI（portrait_hdpi）
TW_THEME                 := portrait_hdpi
# 屏幕刷新率：120Hz
TW_FRAMERATE             := 120
# 亮度控制 sysfs 路径
TW_BRIGHTNESS_PATH       := "/sys/class/backlight/panel0-backlight/brightness"
# 默认亮度值：1200
TW_DEFAULT_BRIGHTNESS    := 1200
# 最大亮度值：4094（小米 OLED 典型值）
TW_MAX_BRIGHTNESS        := 4094
# 不允许屏幕完全熄灭
TW_NO_SCREEN_BLANK  := true
# 启动时先黑屏再显示
TW_SCREEN_BLANK_ON_BOOT  := true
# Y 轴偏移量：141 像素（为状态栏/刘海留出空间）
# TW_Y_OFFSET              := 141
# 高度偏移量：-141 像素（减去状态栏高度）
# TW_H_OFFSET              := -141
# 状态栏图标居中对齐
TW_STATUS_ICONS_ALIGN    := center

# ─────────────────────────────────────────────────────────
# 存储配置
# 已验证: RECOVERY_SDCARD_ON_DATA — sdcard 挂载自 /data/media
# (ro.boot.dynamic_partitions=true, data 分区为 f2fs 格式)
# ─────────────────────────────────────────────────────────
# 将 SD 卡模拟存储挂载在 /data/media 上（而非独立分区）
RECOVERY_SDCARD_ON_DATA   := true
# 使用 mke2fs 工具格式化 ext 文件系统
TARGET_USES_MKE2FS        := true
# 启用文件系统压缩支持
TW_ENABLE_FS_COMPRESSION  := true
# 启用 FUSE exFAT 支持（U 盘等外置存储）
TW_INCLUDE_FUSE_EXFAT     := true
# 启用 FUSE NTFS 支持（Windows 格式 U 盘）
TW_INCLUDE_FUSE_NTFS      := true
# 不包含 NTFS-3G（使用 FUSE NTFS 替代）
TW_INCLUDE_NTFS_3G        := false
# 不使用 exFAT FUSE（内核支持 exFAT）
TW_NO_EXFAT_FUSE          := true

# ─────────────────────────────────────────────────────────
# 工具集
# ─────────────────────────────────────────────────────────
# 包含 7-Zip 压缩工具（支持 .7z 格式）
TW_INCLUDE_7ZA          := true
# 包含 libresetprop（修改系统属性）
TW_INCLUDE_LIBRESETPROP := true
# 包含 lpdump（查看动态分区布局）
TW_INCLUDE_LPDUMP        := true
# 包含 lptools（创建/管理动态分区）
TW_INCLUDE_LPTOOLS      := true
# 包含 repacktools（重新打包 boot/recovery 镜像）
TW_INCLUDE_REPACKTOOLS  := true
# 包含 resetprop 工具
TW_INCLUDE_RESETPROP    := true
# 使用 toolbox 替代 busybox（更轻量）
TW_USE_TOOLBOX          := true
# 启用所有分区工具（备份/恢复/格式化等操作）
TW_ENABLE_ALL_PARTITION_TOOLS := true
# 使用 device-mapper 控制工具
TW_USE_DMCTL            := true
# TW_USE_QCOM_HAPTICS_VIBRATOR := true  ← 已禁用: vibratorfeature 服务在 recovery 中未运行 → 每次触摸卡 UI 5 秒
# 启用电池 sysfs 统计信息读取
TW_USE_BATTERY_SYSFS_STATS    := true
# myron: mca_business_battery 驱动在平台特定路径下暴露电池信息
TW_POWER_SUPPLY_BATTERY_PATH  := "/sys/class/power_supply/battery"

# 定义时区
TW_DEFAULT_TIMEZONE           := Asia/Shanghai

# ─────────────────────────────────────────────────────────
# 调试工具
# ─────────────────────────────────────────────────────────
# 使用 logd 守护进程收集日志
TARGET_USES_LOGD         := true
# 包含 logcat 日志查看工具
TWRP_INCLUDE_LOGCAT      := true
# recovery 模式下额外包含 debuggerd 和 strace 调试模块
TARGET_RECOVERY_DEVICE_MODULES += debuggerd strace
# 将 debuggerd 二进制文件加入 recovery 资源
RECOVERY_BINARY_SOURCE_FILES += $(TARGET_OUT_EXECUTABLES)/debuggerd
# 将 strace 二进制文件加入 recovery 资源
RECOVERY_BINARY_SOURCE_FILES += $(TARGET_OUT_EXECUTABLES)/strace

# ─────────────────────────────────────────────────────────
# Vendor 内核模块 (触屏 / 音频 / ADSP 等驱动)
# 触屏: focaltech_touch_3683.ko (FTS 触控 IC — 已从 odm ramdisk 确认)
# 音频: ADSP 模块为 keymint/weaver 初始化链路所需
# ─────────────────────────────────────────────────────────
# 需要加载的 vendor 内核模块列表
TW_LOAD_VENDOR_MODULES := "focaltech_touch_3683.ko xiaomi_touch.ko adsp_loader_dlkm.ko q6_dlkm.ko q6_pdr_dlkm.ko q6_notifier_dlkm.ko snd_event_dlkm.ko gpr_dlkm.ko spf_core_dlkm.ko rproc_qcom_common.ko qcom_q6v5.ko qcom_q6v5_pas.ko qcom_sysmon.ko qcom-hv-haptics.ko swr_haptics_dlkm.ko"
# 排除 GKI 内核已内置的模块，避免重复加载
TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true
# 在 recovery 启动初期就加载预编译的内核模块
TW_LOAD_PREBUILT_MODULES_AT_FIRST  := true

# ─────────────────────────────────────────────────────────
# 振动器 (cs40l26 haptics 驱动)
# ─────────────────────────────────────────────────────────
# 禁用振动（因为 recovery 中 vibratorfeature 服务不可用）
TW_EXCLUDE_VIBRATOR := true
# 禁用触觉反馈
TW_EXCLUDE_HAPTICS := true

# 不使用旧版属性系统
TW_NO_LEGACY_PROPS           := true
# 延长电池路径等待时间
TW_BATTERY_SYSFS_WAIT_SECONDS := 8

# ─────────────────────────────────────────────────────────
# 杂项配置
# ─────────────────────────────────────────────────────────
# 支持多语言
TW_EXTRA_LANGUAGES    := true
# 默认 language：简体中文
TW_DEFAULT_LANGUAGE   := zh_CN
# 输入设备黑名单
TW_INPUT_BLACKLIST    := "hbtp_vm:qcom-hv-haptics:uinput-xiaomi"
# 排除 APEX 包（recovery 不需要）
TW_EXCLUDE_APEX       := true
# 排除默认 USB 初始化（使用自定义 init.recovery.usb.rc）
TW_EXCLUDE_DEFAULT_USB_INIT := true
# 不支持 EDL（紧急下载模式）
TW_HAS_EDL_MODE       := false
# 使用序列号属性作为设备 ID
TW_USE_SERIALNO_PROPERTY_FOR_DEVICE_ID := true
# 自定义 CPU 温度读取路径
TW_CUSTOM_CPU_TEMP_PATH := "/sys/class/thermal/thermal_zone45/temp"
# 备份时排除 /data/fonts 目录
TW_BACKUP_EXCLUSIONS  := /data/fonts
# 设备版本标识
TW_DEVICE_VERSION     := REDMI_K90_Pro_Max

# 解密 Data 分区
# 包含 OMAPI (Open Mobile API) 支持，用于与 SE (安全元件) 通信
TW_INCLUDE_OMAPI := true

# MTP 支持（通过 USB 传输文件）
TW_HAS_MTP := true
