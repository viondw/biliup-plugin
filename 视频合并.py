import json
import os
import subprocess
import sys
from typing import List
import tempfile


def merge_videos(video_list: List[str]):
    if len(video_list) <= 1:
        print("视频文件数量小于等于 1。")
        return

    # 对文件进行排序以确保按顺序处理
    video_list.sort()

    # 生成输出视频文件名
    out_name = f"{os.path.splitext(video_list[0])[0]}-1.mp4"

    # 创建临时playlist文件
    with tempfile.NamedTemporaryFile(mode='wt', delete=False) as playlist:
        for video_file in video_list:
            playlist.write(f"file '{os.path.abspath(video_file)}'\n")
        playlist_file = playlist.name

    # 创建用于合并视频的ffmpeg命令
    cmd = ['ffmpeg', '-f', 'concat', '-safe', '0', '-i', playlist_file, '-c', 'copy', out_name]

    # 运行ffmpeg命令，指定encoding为'utf-8'
    subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, encoding='utf-8')

    print(f"视频合并成功。")

    # 删除临时playlist文件
    os.remove(playlist_file)

    # 删除原始视频文件
    for file in video_list:
        os.remove(file)
        print(f"已删除原始视频：{file}")

    os.rename(out_name, video_list[0])


if __name__ == "__main__":
    # 调用函数合并视频
    json_str = sys.stdin.read()

    data = json.loads(json_str)
    file_list = data.get("file_list", [])
    merge_videos(file_list)