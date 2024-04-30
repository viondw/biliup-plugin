import os
import re
import shutil
import subprocess
from datetime import datetime

def extract_anchor_name_and_date(file_path):
    # 正则表达式匹配文件名中的主播名和日期
    match = re.search(r"/([^/]+)(\d{4}-\d{2}-\d{2})T\d{2}_\d{2}_\d{2}\.mp4$", file_path)
    if match:
        return match.group(1), match.group(2)
    else:
        return None, None

def main():
    print("开始处理文件...")

    processed_dirs = set()

    for line in sys.stdin:
        file_path = line.strip()
        anchor_name, date = extract_anchor_name_and_date(file_path)

        if not anchor_name or not date:
            print(f"无法从路径提取主播名或日期: {file_path}")
            continue

        target_dir = os.path.join("./backup", anchor_name, date)
        os.makedirs(target_dir, exist_ok=True)
        
        # 移动文件
        shutil.move(file_path, target_dir)
        print(f"文件已移动到: {target_dir}")
        processed_dirs.add(target_dir)

    # 上传到阿里云盘并删除本地文件
    for dir_path in processed_dirs:
        anchor_name = os.path.basename(os.path.dirname(dir_path))
        date = os.path.basename(dir_path)
        target_cloud_path = f"/录播/{anchor_name}"
        print(f"开始上传 {dir_path} 到阿里云盘目录 {target_cloud_path}...")
        cmd = ['aliyunpan', 'upload', dir_path, target_cloud_path]
        subprocess.run(cmd, check=True)
        shutil.rmtree(dir_path)
        print(f"上传完成并已删除本地文件夹：{dir_path}")

if __name__ == "__main__":
    import sys
    main()
