import platform
import subprocess
import requests
import os
import time

def is_admin():
    if platform.system() == "Windows":
        try:
            return ctypes.windll.shell32.IsUserAnAdmin()
        except:
            return False
    else:
        return os.getuid() == 0

def download_and_run_script(url):
    script_name = url.split('/')[-1]
    # 如果文件不存在，那么下载
    if not os.path.exists(script_name):
        # 检查IP地址的国家
        response = requests.get('https://ipinfo.io/country')
        country = response.text.strip()
        if country.lower() == 'cn':
            url = 'https://j.iokun.top/' + url

        response = requests.get(url)
        with open(script_name, 'wb') as file:
            file.write(response.content)
    else:
        print(f"{script_name} 已经存在跳过下载开始执行")

    # 运行脚本
    if platform.system() == "Windows":
        try:
            subprocess.run(['cmd', '/c', script_name])
        except:
            print("start.cmd 运行出错，尝试下载并运行 start.bat")
            download_and_run_script('https://github.com/ikun1993/biliupstart/releases/latest/download/start.bat')
            subprocess.run(['cmd', '/c', 'start.bat'])
    else:
        # 赋予脚本执行权限
        subprocess.run(['chmod', 'a+x', script_name])
        if not is_admin():
            print("请以管理员身份运行此脚本。")
            return
        subprocess.run(['bash', script_name])

# 检查操作系统类型
os_type = platform.system()
if os_type == "Windows":
    # Windows
    print("你是Windows系统 正在下载对应脚本")
    download_and_run_script('https://github.com/ikun1993/biliupstart/releases/latest/download/start.cmd')
elif os_type in ["Linux", "Darwin"]:
    # Linux or Mac
    print("你是Linux系统 正在下载对应脚本")
    download_and_run_script('https://github.com/ikun1993/biliupstart/releases/latest/download/start.sh')
else:
    print("Unsupported operating system.")
