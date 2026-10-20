from pathlib import Path
import subprocess, json
import imageio_ffmpeg
ROOT = Path(__file__).resolve().parents[1]
ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
reports = []
for name in ['benchmark', 'animacion']:
    source = ROOT / 'output' / 'evidence' / (name + '.avi')
    target = source.with_suffix('.mp4')
    subprocess.run([ffmpeg, '-y', '-i', str(source), '-an', '-c:v', 'libx264', '-crf', '21', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', str(target)], check=True, capture_output=True)
    reader = imageio_ffmpeg.read_frames(str(target))
    meta = next(reader)
    count = sum(1 for _ in reader)
    reports.append({'file': target.name, 'size': meta['size'], 'fps':meta['fps'], 'duration_s':meta['duration'], 'decoded_frames':count, 'bytes':target.stat().st_size})
(ROOT/'output/evidence/media_validation.json').write_text(json.dumps(reports,indent=2),encoding='utf-8')
print(json.dumps(reports,indent=2))
