# OrangeFox Recovery — Xiaomi myron (POCO F8 Ultra / Redmi K90 Pro Max)

## 设备信息

| 项目 | 规格 |
|------|------|
| 处理器 | Snapdragon 8 Elite Gen 5（SM8850 / sun） |
| CPU | Oryon（8 核） |
| 内存 | 12/16 GB |
| 存储 | 256/512 GB UFS 4.0 |
| 屏幕 | 1200×2608，120Hz OLED |
| 内核 | GKI 6.12（Android 16） |
| 分区架构 | Virtual A/B + 独立 recovery 分区 |
| 加密方式 | FBE（aes-256-xts + wrappedkey_v0） |
| KeyMint | TEE（vendor.keymint-qti）+ Strongbox（Thales JavaCard via se_omapi） |
| 振动马达 | PMIC HV haptics (qcom-hv-haptics revision 5) |

---

## 构建
```bash
git clone https://github.com/OrangeFox16/sync.git
cd sync
./orangefox_sync.sh --branch 16.0 --path ~/fox_16.0 #同步源码，这一步需要在googlesource下载大约80G的源码(This may take a very *long* time)
cd fox_16.0
source build/envsetup.sh
lunch twrp_myron-bp2a-eng
mka recoveryimage
```
如需使用github actions构建，请自行寻找脚本


## 目前支持的特性
触屏(这个不支持就难绷了)✅  
震动 ❌  
解密Data ✅  
MTP ✅  
安装KernelSU(不支持SukiSU和KernelSU Next，需要的可修改fox_myron.mk后自行构建) ✅  
手电筒 ✅  
WIFI ❌  

其余功能待补充  
后续会修复不支持的特性
## 注意
对于假回锁用户，自行构建的OrangeFox不能直接刷入recovery分区(Release里的是处理好的)，需要使用仓库下的“移植vbmeta.py”脚本把原厂recovery的avb信息移植过去后再刷入  
```bash
python transplanting_vbmeta.py <原厂recovery.img> <被修补的镜像> <修补后的文件>
```

目前除 Wi-Fi 相关二进制文件（仍来源于 變換風雲@coolapk）外，其余二进制文件均提取自 HyperOS 3.0.303.0。后续增加 Wi-Fi 支持时，将统一改为从官方系统中提取所有二进制文件。

## Maintainer
haohao3001 - 维护者  
基于[hackpupg001-a11y的设备树](https://github.com/hackpupg001-a11y/android_device_xiaomi_myron)二次开发  
recovery/root下的大部分二进制文件参考自 變換風雲@coolapk 的TWRP
