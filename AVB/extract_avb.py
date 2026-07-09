#!/usr/bin/env python3
"""
AVB 签名提取工具
=================
从官方 recovery.img 中仅提取 AVB 签名尾部（vbmeta blob + footer），
生成一个小体积文件（通常 < 1MB）

用法:
  python extract_avb.py <原厂recovery.img> <输出文件>

示例:
  python extract_avb.py recovery_306.img avb_306.bin
"""

import os
import struct
import sys


def extract_avb_signature(official_img, output_path):
    print(f"[*] 官方镜像: {official_img}")

    with open(official_img, "rb") as f:
        # ── 读取 AVB footer（最后 64 字节）──
        f.seek(0, os.SEEK_END)
        part_size = f.tell()
        print(f"    分区大小: {part_size} 字节 ({part_size / 1024 / 1024:.1f} MB)")

        f.seek(part_size - 64)
        footer = f.read(64)
        magic, major, minor, orig_size, vbmeta_offset, vbmeta_size = struct.unpack(
            ">4sLLQQQ", footer[:36]
        )

        if magic != b"AVBf":
            print("[-] 错误：镜像不包含 AVB 尾部签名！")
            return False

        print(f"    AVB 版本: {major}.{minor}")
        print(f"    vbmeta 偏移: {vbmeta_offset}, 大小: {vbmeta_size} 字节")

        # ── 读取 vbmeta blob ──
        f.seek(vbmeta_offset)
        vbmeta_blob = f.read(vbmeta_size)

    # ── 写入提取文件 ──
    # 格式: [4字节 分区大小(big-endian)] [vbmeta blob] [64字节 footer]
    with open(output_path, "wb") as out:
        out.write(struct.pack(">I", part_size))  # 分区总大小
        out.write(vbmeta_blob)                    # vbmeta 签名数据
        out.write(footer)                         # 原始 AVB footer

    file_size = os.path.getsize(output_path)
    print(f"\n[+] 提取成功 → {output_path}")
    print(f"    文件大小: {file_size} 字节 ({file_size / 1024:.1f} KB)")
    print(f"    可以上传到 GitHub 了！(远小于 25MB 限制)")
    return True


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python extract_avb.py <原厂recovery.img> <输出文件>")
        print("示例: python extract_avb.py recovery_306.img avb_306.bin")
        sys.exit(1)

    official = sys.argv[1]

    if len(sys.argv) >= 3:
        output = sys.argv[2]
    else:
        output = os.path.join(
            os.path.dirname(official) or ".",
            "avb_signature.bin",
        )

    if not os.path.exists(official):
        print(f"[-] 错误：文件不存在: {official}")
        sys.exit(1)

    success = extract_avb_signature(official, output)
    sys.exit(0 if success else 1)
