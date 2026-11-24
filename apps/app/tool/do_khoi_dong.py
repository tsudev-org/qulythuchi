#!/usr/bin/env python3
"""Đo thời gian khởi động bản RELEASE desktop tới khung hình đầu tiên (LANGUAGE_SELECTION 5.1: ≤ 1 giây).

Chạy app N lần với QT_DO_KHOI_DONG=1 (lib/startup_probe_io.dart thoát với mã 37 ngay khi khung hình đầu tiên đã
raster), đo từ lúc gọi tiến trình tới khi tiến trình thoát với mã đó. Lần 1 = chạy đầu (tạo khóa + CSDL), các lần sau = chạy lại.
Dùng: python3 -I tool/do_khoi_dong.py <tệp chạy> [số lần]
"""
import os
import statistics
import subprocess
import sys
import time

sys.stdout.reconfigure(encoding='utf-8')  # console Windows mặc định cp1252
MA_KHUNG_DAU = 37
exe = sys.argv[1]
lan = int(sys.argv[2]) if len(sys.argv) > 2 else 6
ket_qua = []
for i in range(lan):
    env = dict(os.environ, QT_DO_KHOI_DONG='1')
    t0 = time.perf_counter()
    p = subprocess.Popen([exe], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        ma = p.wait(timeout=60)
    except subprocess.TimeoutExpired:
        p.kill()
        sys.exit(f'lần {i + 1}: quá 60 giây chưa có khung hình đầu tiên')
    ms = (time.perf_counter() - t0) * 1000
    if ma != MA_KHUNG_DAU:
        sys.exit(f'lần {i + 1}: app thoát mã {ma} trước khung hình đầu tiên')
    ket_qua.append(ms)
    print(f'lần {i + 1}: {ms:.0f} ms')

lai = ket_qua[1:] or ket_qua
dong = (f'Khởi động tới khung hình đầu tiên ({sys.platform}): lần đầu {ket_qua[0]:.0f} ms; chạy lại trung vị '
        f'{statistics.median(lai):.0f} ms, lớn nhất {max(lai):.0f} ms ({len(lai)} lần)')
print(dong)
tom_tat = os.environ.get('GITHUB_STEP_SUMMARY')
if tom_tat:
    with open(tom_tat, 'a', encoding='utf-8') as f:
        f.write(dong + '\n')
