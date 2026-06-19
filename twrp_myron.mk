#
# Copyright (C) 2026 OrangeFox Recovery Project
# Device: Xiaomi myron (POCO F8 Ultra / Redmi K90 Pro Max)
# Branch: OrangeFox 14.1
# SoC   : Snapdragon 8 Elite Gen 5 (SM8850 / sun)
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/xiaomi/myron
# ─── Inheritance ──────────────────────────────────────────────────────────────
# Configure base.mk
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)

# Configure core_64_bit_only.mk
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)

# Configure virtual_ab compression.mk
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression.mk)

# Configure emulated_storage.mk
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Configure twrp common.mk
$(call inherit-product, vendor/twrp/config/common.mk)

# Configure full_base_telephony.mk
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# 配置硬件信息
$(call inherit-product, device/xiaomi/myron/device.mk)

#TWRP/OrangeFox特有的配置
$(call inherit-product, device/xiaomi/myron/fox_myron.mk)

PRODUCT_DEVICE       := myron
PRODUCT_NAME         := twrp_myron
PRODUCT_BRAND        := Xiaomi
PRODUCT_MODEL        := REDMI K90 Pro Max
PRODUCT_MANUFACTURER := Xiaomi

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="myron-user 16 BQ2A.250705.001-BP2A.250605.031.A3 OS3.0.303.0.WPMCNXM release-keys"

BUILD_FINGERPRINT := Redmi/myron/myron:16/BQ2A.250705.001-BP2A.250605.031.A3/OS3.0.303.0.WPMCNXM:user/release-keys