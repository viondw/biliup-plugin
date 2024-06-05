import subprocess
import datetime
import re

# 设置要检查的多个根文件夹路径
root_folders = ["/录播", "/另一个录播"]

# 获取当前日期并计算一个月前的日期
current_date = datetime.datetime.now()
one_month_ago = current_date - datetime.timedelta(days=30)

# 遍历每个根文件夹
for root_folder in root_folders:
    # 使用 aliyunpan CLI 列出根文件夹下的所有子文件夹
    list_folders_command = f"aliyunpan ls {root_folder}"
    folders_result = subprocess.run(list_folders_command, shell=True, capture_output=True, text=True)

    # 提取子文件夹的名称
    sub_folders = re.findall(r'\d+\s+-\s+\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s+([^\s/]+)/', folders_result.stdout)

    # 遍历每个子文件夹
    for sub_folder in sub_folders:
        full_path = f"{root_folder}/{sub_folder}"
        # 列出每个子文件夹中的文件
        list_files_command = f"aliyunpan ls {full_path}"
        files_result = subprocess.run(list_files_command, shell=True, capture_output=True, text=True)
        
        # 提取文件名
        files = re.findall(r'\d+\s+-\s+\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s+([^\s/]+)/', files_result.stdout)
        
        # 检查文件命名日期并删除过旧的文件
        for file in files:
            try:
                file_date = datetime.datetime.strptime(file, "%Y-%m-%d")
                if file_date < one_month_ago:
                    delete_command = f"aliyunpan rm {full_path}/{file}"
                    subprocess.run(delete_command, shell=True)
            except ValueError:
                continue  # 如果文件名不是日期格式，则跳过

print("过旧的文件已删除")
