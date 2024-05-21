import json
import subprocess
from datetime import datetime, timedelta

# 配置
drive_name = "myod"
base_paths = ["/录播", "/lubo"]  # 现在有两个基础路径
date_format = "%Y-%m-%d"  # 日期格式

# 当前日期
now = datetime.now()

def list_folders(path):
    """使用rclone列出指定路径下的直接子文件夹"""
    cmd = f"rclone lsf {drive_name}:{path} --dirs-only"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    folders = result.stdout.strip().split('\n')
    return folders

def delete_old_folders(sub_path):
    """删除指定路径下，日期超过30天的文件夹"""
    folders = list_folders(sub_path)
    for folder in folders:
        try:
            # 从文件夹名称尝试解析日期
            folder_date = datetime.strptime(folder.rstrip('/'), date_format)
            # 计算日期差异
            diff = now - folder_date
            if diff > timedelta(days=30):
                # 删除超过30天的文件夹
                folder_path = f"{drive_name}:{sub_path}/{folder}"
                delete_cmd = f"rclone purge {folder_path}"
                print(f"Deleting old folder: {folder_path}")
                subprocess.run(delete_cmd, shell=True)
        except ValueError:
            # 文件夹名称不符合日期格式，跳过
            print(f"Skipping non-date folder: {folder}")

# 对每个基础路径下的文件夹执行操作
for base_path in base_paths:
    # 列出base_path下的所有直接子文件夹
    sub_folders = list_folders(base_path)
    for sub_folder in sub_folders:
        full_path = f"{base_path}/{sub_folder.rstrip('/')}"
        print(f"Checking folder: {full_path}")
        delete_old_folders(full_path)

print("Deletion process completed.")
