import os
import shutil
import re

# 创建一个名为“视频”的文件夹用于存放视频文件
output_folder = "视频"
os.makedirs(output_folder, exist_ok=True)

# 获取当前文件夹下的所有视频文件
video_files = [f for f in os.listdir() if os.path.isfile(f) and f.lower().endswith((".mp4", ".flv", ".mkv"))]

# 根据视频文件名中的特定部分创建文件夹并移动视频文件
for video_file in video_files:
    match = re.search(r'(.*?)\d{4}-\d{2}-\d{2}T\d{2}_\d{2}_\d{2}', video_file)
    if match:
        folder_name = match.group(1).strip()
        folder_path = os.path.join(output_folder, folder_name)
        os.makedirs(folder_path, exist_ok=True)
        shutil.move(os.path.join(os.getcwd(), video_file), os.path.join(folder_path, video_file))
    else:
        print(f"Ignoring file: {video_file} as it does not match the expected pattern.")

print("视频文件已按要求移动到对应文件夹中。")

