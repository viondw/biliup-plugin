#!/bin/bash

# 定义颜色代码
green='\033[0;32m'
plain='\033[0m'
red='\e[31m'
yellow='\e[33m'

# ANSI转义码，设置高亮
highlight="\e[1;31m"  
reset="\e[0m"      

# 获取终端宽度
columns=$(tput cols)

ascii_art="
${red}\e[1m 注意：该脚本第三方制作与官方无关 ${reset}
${green}\e[1m 注意：脚本开始结束均有爱发电链接 ${reset}
${plain}\e[1m 注意：https://afdian.net/a/biliup ${reset}"

# 计算居中的空格数量
padding=$((($columns - 32) / 2))

# 显示居中的 ASCII 艺术
echo -e "${highlight}$(echo "$ascii_art" | sed "s/^/$(printf "%${padding}s")/")${reset}"

# 获取国家代码
country_code=$(curl -s https://ipinfo.io/country)
if [ "$country_code" = "CN" ]; then
    url="https://j.iokun.top/https://"
    pipsource="https://mirrors.cernet.edu.cn/pypi/web/simple"
else
    url="https://"
    pipsource="https://pypi.org/simple"
fi

# 全局工作目录
BILIUP_DIR=/opt/biliup

# 运行前置条件查询python版本
found=false
for version in python python3 python3.8 python3.9 python3.10 python3.11 python3.12; do
    if ! command -v $version &> /dev/null ; then
        continue
    fi
    python_version=$($version --version 2>&1 | cut -d " " -f2)
    if [[ $(echo -e "3.8\n$python_version" | sort -V | head -n1) == "3.8" ]]; then
        echo -e "Python3的版本是${yellow} $python_version ${reset} ..."
        found=true
        break
    fi
done

# 检查Python版本是否大于等于3.8
source /etc/os-release
if [[ "$found" = false && "$ID" != "centos" ]] ; then
    echo -e "Python ${yellow} 小于3.8 ${reset} 请手动更新，退出脚本 ..."
    exit 1
fi

# 获取MAC地址密钥
api_key_base="mcj61eu11g3sk7o366afxv6pnacwd9"
mac_address=$(ifconfig -a | grep ether | awk '{print $2}' | head -n 1 | tr -d ':')
api_key="$api_key_base$mac_address"

# 发送运行次数到后端服务器
backend_url="https://run.iokun.cn/update_run_count/Linux"
curl -X POST -d "run_count=1" -H "X-API-KEY: $api_key" -H "X-MAC-ADDRESS: $mac_address" "$backend_url" > /dev/null 2>&1

# 获取最新版本的链接
latest_url=$(curl -Ls -o /dev/null -w %{url_effective} ${url}github.com/biliup/biliup-rs/releases/latest/download/)

# 从链接中提取版本号
biliuprs_version=$(echo $latest_url | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+')

# 安装下载命令
install_biliup() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
    
    if [ ! -f "install.sh" ]; then
        wget ${url}github.com/ikun1993/biliupstart/releases/download/biliupstart/install.sh && chmod +x install.sh && bash install.sh
        echo -e "biliup完成：${green}安装命令已经运行${reset}"
    else
        bash install.sh
        echo -e "biliup完成：${green}安装命令已经存在${reset}"
    fi

    # 定义函数来运行biliup命令
    version=$(pip3 show biliup | grep Version | cut -d ' ' -f 2 | tr -d '.')
    if [[ -z "$version" ]]; then
        version=$(pip3.8 show biliup | grep Version | cut -d ' ' -f 2 | tr -d '.')
    fi    
    biliup_version=$((10#$(version)))
    if [[ $biliup_version -lt 453 ]]; then
        if ! find  -name "*-linux.tar.xz" -print -quit | grep -q .; then
            echo "你的CPU架构是："
            echo -e "    （${red}默认${reset}）0: ${yellow}x86_64${reset}"
            echo -e "            1: ${green}ARMa64${reset}"
            echo -e "            2: ${green} ARM${reset}"
            read -p "请输入[0/1/2]：" arch_choice
            if [[ -z "$arch_choice" || ! "$arch_choice" =~ [0-2] ]]; then
                echo -e "你输入错误，使用默认 ${yellow}x86_64${reset} CPU架构："
                arch_choice=0
            fi
            if [ "$arch_choice" -eq 2 ]; then
                wget ${url}github.com/biliup/biliup-rs/releases/latest/download/biliupR-${biliuprs_version}-arm-linux.tar.xz && tar -xf biliupR-${biliuprs_version}-arm-linux.tar.xz && mv "biliupR-${biliuprs_version}-arm-linux/biliup" "biliupR"
            elif [ "$arch_choice" -eq 1 ]; then
                wget ${url}github.com/biliup/biliup-rs/releases/latest/download/biliupR-${biliuprs_version}-aarch64-linux.tar.xz && tar -xf biliupR-${biliuprs_version}-aarch64-linux.tar.xz && mv "biliupR-${biliuprs_version}-aarch64-linux/biliup" "biliupR"
            else
                wget ${url}github.com/biliup/biliup-rs/releases/latest/download/biliupR-${biliuprs_version}-x86_64-linux.tar.xz && tar -xf biliupR-${biliuprs_version}-linux.tar.xz && mv "biliupR-${biliuprs_version}-x86_64-linux/biliup" "biliupR"
            fi
            echo -e "biliup-rs完成：${green}已经下载${reset}"
        else
            echo -e "biliup-rs完成：${green}已经存在${reset}"
        fi
    fi
}

if pgrep -f "biliup" > /dev/null; then
    read -p "biliup 已安装 你希望重新安装biliup吗？[Y/N]："  rerun
    if [ -z "$rerun" ]; then
        rerun=0
    fi
    if [ "$rerun" = "y" ]; then
        pkill -f "biliup" ; rm -f "watch_process.pid" 
        echo -e "${green}已经杀死biliup程，将重新运行biliup${reset}"
    else
        echo -e "${red}取消重新启动biliup${reset}"
        read -p "biliup 已运行 你希望新增一个biliup进程吗？[Y/N]："  addnew
        if [ "$addnew" = "y" ]; then
            BILIUP_DIR="/opt/biliup/$(date +%s)"
            echo -e "将${green}新增${reset}一个biliup进程"
        else
            echo -e "${red}退出脚本${reset}"
            exit 1
        fi
    fi
fi

# 检查biliup是否安装
if [ ! -d "${BILIUP_DIR}" ]; then
    mkdir ${BILIUP_DIR}
fi
cd ${BILIUP_DIR}
echo -e "录播文件和日志储存在${green} ${BILIUP_DIR} ${reset}"

pip3_version=$(pip3 --version)
if [[ -z "$pip3_version" ]]; then
    pip=pip3.8
else
    pip=pip3
fi
if ! $pip show biliup > /dev/null 2>&1; then
    install_biliup
fi

# 使用sort命令和版本比较来决定使用哪个pip命令
if printf '3.11\n%s' "$python_version" | sort -V | head -n1 | grep -q '3.11'; then
    echo -e "使用${green}pip install --break-system-packages${reset} 来安装..."
    pip_install_cmd="$pip install -i $pipsource --break-system-packages"
    python3_install_cmd="-i $pipsource --break-system-packages"
else
    echo -e "使用标准${green} pip install ${reset}来安装..."
    pip_install_cmd="$pip install -i $pipsource"
fi

echo -n "检查biliup版本中，请等待"
for i in {1..3}
do
    echo -n "."
    sleep 1
done
echo ""

# 检查pip3版本并获取biliup的官方版本
if ! $pip --version &> /dev/null; then
    sudo apt-get update
    sudo apt-get install python3-pip
fi
if ! $pip --version &> /dev/null; then
    curl "${url}github.com/ikun1993/biliupstart/releases/download/biliupstart/get-pip.py" -o "get-pip.py" && sudo python3 "get-pip.py" &&  rm -f "get-pip.py"
    echo -e "检测到只安装python3 已自动安装${green}最新版本pip3${reset}"   
else
    official_version=$($pip index versions biliup | grep -oP '(?<=LATEST:    ).*')
fi

local_version=$($pip show biliup | grep Version | cut -d ' ' -f 2)
echo -e "本地版本：${green} $local_version ${reset}"
if [ "$id" != "centos" ]; then
    if [ -n "$official_version" ]; then
        echo -e "最新版本：${yellow} $official_version ${reset}"
    else
        echo -e "最新版本：${red} 失败跳过更新检查 手动更新${yellow} sudo $pip_install_cmd -U biliup ${reset}"
    fi
fi

# 如果本地版本和最新版本不一致，提示用户更新
biliup_version=$((10#$($pip show biliup | grep Version | cut -d ' ' -f 2 | tr -d '.')))
if [ ! -f "/opt/biliup/upgrade.txt" ] || [[ $biliup_version -gt 431 ]]; then
    if [ -n "$official_version" ] && [ "$local_version" != "$official_version" ]; then
        read -p "本地版本和最新版本不一致，你希望更新biliup吗？[Y/N]：" update_choice
        if [ -z "$update_choice" ]; then
            update_choice=y
        fi
        if [ "$update_choice" = "y" ]; then
            sudo $pip_install_cmd -U biliup==$official_version
            echo -e "更新后的版本是：${green} $official_version ${reset}"
            biliup_version=$($pip show biliup | grep Version | cut -d ' ' -f 2 | tr -d '.')
        else
            echo -e "最新库中版本是：${green} $official_version ${reset}"
            echo $update_choice > "/opt/biliup/upgrade.txt"
        fi
    fi
fi

# 登录biliup-rs
if [[ $biliup_version -lt 452 ]]; then
    if [ ! -f "cookies.json" ]; then
        read -p "未登录B站（cookier.json不存在）推荐使用扫码登录，是否登录？[Y/N]：" choice
        if [ -z "$choice" ]; then
            choice=y
        fi
        if [ "$choice" = "y" ]; then
            sudo bash -c "biliupR login"
            if [ -f "cookies.json" ]; then
                echo -e "已从biliup-rs获取${yellow}cookie${red} 泄露会被盗登B站${reset}"
            else
                echo -e "未登录biliup-rs 请控制台手动执行${red} biliupR login${reset}"
            fi
        else
            echo -e "cookie是登录B站所需 如上传请控制台手动执行${red} biliupR login${reset}"
        fi
    fi
else
    NODE_VERSION=$(node -v | tr -d 'v' | cut -d '.' -f 1)
    if [ $NODE_VERSION -lt 20 ]; then
        wget -qO- ${url}github.com/ikun1993/biliupstart/releases/download/biliupstart/nvm.sh | bash
        export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
        source ~/.bashrc

        echo -e "检测版本低于20是否更新，${red}可能能解决斗鱼录制错误 ${reset}"
        nvm install --lts
        nvm use --lts
    fi
fi

# 禁用的端口列表
ForbiddenPorts="0 1 7 9 11 13 15 17 19 20 21 22 23 25 37 42 43 53 77 79 87 95 101 102 103 104 109 110 111 113 115 117 119 123 135 139 143 179 389 465 512 513 514 515 526 530 531 532 540 556 563 587 601 636 993 995 2049 3659 4045 6000 6665 6666 6667 6668 6669 137 139 445 593 1025 2745 3127 6129 3389"

# 互动输入端口
while true; do
    read -p  "请输入一个小于65535的端口(回车默认19159)： " UserPort
    if [ -z "$UserPort" ]; then
        UserPort=19159
        echo -e "你使用了默认端口 ${green}$UserPort ${reset}  等待进入下一步"
    fi
    if [[ $UserPort =~ ^[0-9]+$ ]] && [ $UserPort -le 65535 ]; then
        if [[ $ForbiddenPorts =~ (^|[[:space:]])$UserPort($|[[:space:]]) ]]; then
            echo "错误: 端口 $UserPort 被禁用，请重新输入。"
        elif timeout 1 bash -c "</dev/tcp/localhost/$UserPort" 2>/dev/null; then
            echo "错误: 端口 $UserPort 已被占用，请重新输入。"
        else
            if [ $UserPort != 19159 ]; then
                echo -e "注意: 你选择的端口 ${yellow} $UserPort ${reset} 不是默认端口。如果你的防火墙设置阻止了该端口通信，请确保你已经在防火墙中打开了这个端口。"
            fi
            break
        fi
    else
        echo "错误: 你输入的不是有效的端口号，请重新输入。"
    fi
done

# 互动输入密码
while true; do
    read -r -p  "请输入密码(回车为不使用密码公网慎用）：" UserPassword
    if [ -z "$UserPassword" ]; then
        UserPassword=0
        break
    elif [[ "$UserPassword" =~ [$'\001'-$'\037'] ]]; then
        echo "错误: 你输入的密码包含无效的字符，请重新输入。"
    else
        echo -e "账号：${green} biliup ${reset} 密码：${yellow} $UserPassword ${reset}"
        break
    fi
done

# 定义函数来运行biliup命令
run_biliup() {
    if [[ $biliup_version -lt 431 ]]; then
        curl -L "${url}raw.githubusercontent.com/biliup/biliup/master/public/config.toml" -o "config.toml"
        read -p  "0.4.32以下 是否开启hhtp？回车默认开启[Y/N]：" rrun
        if [ -z "$rerun" ]; then
            rrun=y
        fi
        echo -e "biliup v0.4.32以下 请到${red} config.toml ${reset}进行配置"
        if [ "$rrun" = "y" ]; then
           HTTP_FLAG=--http
        else
           HTTP_FLAG=
        fi   
    fi
    if [ "$UserPassword" = "0" ]; then
        biliup -P $UserPort $HTTP_FLAG start
    else
        biliup -P $UserPort --password '$UserPassword' $HTTP_FLAG start
    fi   
}
run_biliup

# 检查biliup是否正在运行
rm_biliup() {
    if [ -n "$(curl -s ipinfo.io/ip)" ]; then    
        echo -e "biliup已运行请至浏览器配置WEBUI  ${green}http://$(curl -s ipinfo.io/ip):$UserPort${reset}"
    else
        echo -e "biliup已运行请至浏览器配置WEBUI  ${green}http://[$(curl -s 6.ipw.cn)]:$UserPort${reset}"
    fi
    if find ${BILIUP_DIR} -name install.sh -print -quit 2>/dev/null | grep -q '^'
    then
        read -p  "你希望清理安装包吗？回车默认清理[Y/N]：" rerun
        if [ -z "$rerun" ]; then
            rerun=y
        fi
        if [ "$rerun" = "y" ]; then
            rm -f biliupR-v0.1.19-*-linux.tar.xz
            rm -rf biliupR-v0.1.19-*-linux
            rm -f install.sh
            rm -f qrcode.png
            echo -e "${green}已清理安装包,biliu启动成功${reset}"
        fi
    fi
}

# 最后给用户一个提示
if pgrep -f "biliup" > /dev/null; then
    rm_biliup
else
    if [ -f "watch_process.pid" ]; then 
        rm -f "watch_process.pid" ; run_biliup
    else
        run_biliup
    fi
    if ! pgrep -f "biliup" > /dev/null; then
        echo $err_output
        echo -e "${red}真一键biliup出问题了，请在QQ群中反馈${reset}"
    else
        rm_biliup
    fi
fi
echo -e "爱发电赞助作者维护${plain} https://afdian.net/a/biliup${reset}"
echo -e "反馈问题需带上文件${red} ${BILIUP_DIR}/ds_update.log${reset}"
