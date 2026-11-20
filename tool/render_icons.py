#!/usr/bin/env python3
"""Draw an original cat-mark launcher icon. No third-party art."""

import struct
import zlib
from pathlib import Path


def png(width, height, pixel):
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        for x in range(width):
            raw.extend(pixel(x, y))

    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")


def blend(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))


def cat(size, paper=(246, 241, 232, 255), ink=(62, 52, 44, 255)):
    def dot(x, y):
        nx = (x + 0.5) / size - 0.5
        ny = (y + 0.5) / size - 0.5
        # Rounded paper tile.
        radius = 0.46
        outside = max(abs(nx), abs(ny))
        if outside > radius:
            return (0, 0, 0, 0) if size < 64 else paper
        color = paper

        def inside_circle(cx, cy, r):
            return (nx - cx) ** 2 + (ny - cy) ** 2 <= r * r

        def inside_ear(sign):
            px, py = nx * sign, ny
            return py < -0.02 and abs(px - 0.16) * 1.7 + (py + 0.02) * 0.15 < 0.16 and py > -0.34

        if inside_ear(1) or inside_ear(-1) or inside_circle(0, 0.04, 0.22):
            color = ink
        if inside_circle(-0.07, 0.01, 0.025) or inside_circle(0.07, 0.01, 0.025):
            color = paper
        if abs(nx) < 0.028 and -0.02 < ny - 0.09 < 0.045 and ny > 0.08:
            color = paper
        return color

    return png(size, size, dot)


def main():
    root = Path(__file__).resolve().parents[1]
    android = {
        48: root / "android/app/src/main/res/mipmap-mdpi/ic_launcher.png",
        72: root / "android/app/src/main/res/mipmap-hdpi/ic_launcher.png",
        96: root / "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png",
        144: root / "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png",
        192: root / "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png",
    }
    for size, path in android.items():
        path.write_bytes(cat(size))
    ios = root / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for path in ios.glob("Icon-App-*.png"):
        # Filename encodes the pixel size via the existing file; keep that size.
        data = path.read_bytes()
        width, height = struct.unpack(">II", data[16:24])
        path.write_bytes(cat(width))
    launch = root / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    for name, size in [("LaunchImage.png", 200), ("LaunchImage@2x.png", 400), ("LaunchImage@3x.png", 600)]:
        (launch / name).write_bytes(cat(size, paper=(246, 241, 232, 255)))
    print("icons written")


if __name__ == "__main__":
    main()
