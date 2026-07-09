#!/usr/bin/env python3
"""
AVB 签名合并工具（纯 CI 模式）
==============================
将 extract_avb.py 提取的签名文件合并到编译好的 recovery.img 上，
生成带官方 AVB 签名的 recovery.img。

所有路径从环境变量读取，由 OrangeFox-Compile.yml 传入:

环境变量:
  ANDROID_BUILD_TOP  — 源码根目录
  DEVICE_PATH        — 设备树相对路径（如 device/xiaomi/myron）
  AVB_SIG_FILE       — 签名文件名（相对于 DEVICE_PATH/AVB/，如 avb_306.bin）

格式说明:
  *.bin = [4字节 分区大小(big-endian)] [vbmeta blob] [64字节 footer]
"""

import os
import struct
import sys
import glob


def find_custom_recovery(base_dir):
    """在 out/target/product/*/ 下自动查找 recovery.img"""
    pattern = os.path.join(base_dir, "out", "target", "product", "*", "recovery.img")
    matches = glob.glob(pattern)
    if not matches:
        pattern2 = os.path.join(
            base_dir, "out", "target", "product", "*", "OrangeFox*.img"
        )
        matches = glob.glob(pattern2)
    return matches[0] if matches else None


def merge_avb(sig_file, custom_img, output_img):
    print(f"[*] 签名文件  : {sig_file}")
    print(f"[*] 自定义镜像: {custom_img}")

    # ── 1. 读取签名文件 ──────────────────────────────────────────────
    with open(sig_file, "rb") as f:
        part_size = struct.unpack(">I", f.read(4))[0]
        blob = f.read()

    if len(blob) < 64:
        print("[-] 错误：签名文件格式不正确（太短）")
        return False

    footer = blob[-64:]
    vbmeta_blob = blob[:-64]

    print(f"    分区大小  : {part_size} 字节 ({part_size / 1024 / 1024:.1f} MB)")
    print(f"    vbmeta    : {len(vbmeta_blob)} 字节")
    print(f"    footer    : {len(footer)} 字节")

    # ── 2. 读取自定义镜像，剥离可能存在的测试签名 ──────────────────
    with open(custom_img, "rb") as f_cust:
        f_cust.seek(0, os.SEEK_END)
        cust_size = f_cust.tell()
        f_cust.seek(cust_size - 64)
        has_avb = (struct.unpack(">4s", f_cust.read(4))[0] == b"AVBf")
        f_cust.seek(0)

        if has_avb:
            f_cust.seek(cust_size - 64)
            _, _, _, _, cust_vbmeta_offset, _ = struct.unpack(
                ">4sLLQQQ", f_cust.read(36)
            )
            pure_cust_data = f_cust.read(cust_vbmeta_offset)
            print(f"[+] 剥离测试签名，OrangeFox 有效体积: {len(pure_cust_data)} 字节")
        else:
            pure_cust_data = f_cust.read()
            print(f"[+] 无测试签名，OrangeFox 体积: {len(pure_cust_data)} 字节")

    # ── 3. 体积校验 ──────────────────────────────────────────────────
    total_needed = len(pure_cust_data) + len(vbmeta_blob) + 64
    if total_needed > part_size:
        print(
            f"[-] 错误：OrangeFox ({len(pure_cust_data)} 字节) + "
            f"签名 ({len(vbmeta_blob)} 字节) 超出分区容量 ({part_size} 字节)！"
        )
        return False

    # ── 4. 重建 AVB footer ───────────────────────────────────────────
    off = len(pure_cust_data)
    major = struct.unpack(">L", footer[4:8])[0]
    minor = struct.unpack(">L", footer[8:12])[0]
    new_footer = struct.pack(
        ">4sLLQQQ", b"AVBf", major, minor, off, off, len(vbmeta_blob)
    )
    new_footer += b"\0" * 28

    # ── 5. 组装最终镜像 ──────────────────────────────────────────────
    with open(output_img, "wb") as f_out:
        f_out.write(pure_cust_data)
        f_out.write(vbmeta_blob)
        pos = f_out.tell()
        f_out.write(b"\0" * (part_size - 64 - pos))
        f_out.write(new_footer)

    sz = os.path.getsize(output_img)
    print(f"\n[+] AVB 移植成功 → {output_img}")
    print(f"    最终大小: {sz} 字节 ({sz / 1024 / 1024:.2f} MB)")
    print(f"    已用/容量: {total_needed} / {part_size} ({part_size - total_needed} 字节剩余)")
    return True


# ── 主入口 ──────────────────────────────────────────────────────────────
if __name__ == "__main__":
    build_top  = os.environ.get("ANDROID_BUILD_TOP", ".")
    ws         = os.environ.get("GITHUB_WORKSPACE", ".")
    sig_name   = os.environ.get("AVB_SIG_FILE", "avb_signature.bin")

    # 签名文件在 Action Builder 仓库的 AVB/ 目录下
    sig_file = os.path.join(ws, "AVB", sig_name)
    if not os.path.exists(sig_file):
        print(f"[-] 错误：签名文件不存在 → {sig_file}")
        print("    请先用 extract_avb.py 从官方 recovery 提取签名，放入设备树 AVB/ 目录")
        sys.exit(1)

    # 编译产物路径
    custom = find_custom_recovery(build_top)
    if not custom or not os.path.exists(custom):
        print("[-] 错误：找不到编译好的 recovery.img")
        print(f"    搜索路径: {build_top}/out/target/product/*/")
        sys.exit(1)

    # 输出文件与输入同目录
    output = os.path.join(os.path.dirname(custom), "recovery_avb_signed.img")

    success = merge_avb(sig_file, custom, output)
    sys.exit(0 if success else 1)
