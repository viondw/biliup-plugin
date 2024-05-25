@echo off
setlocal enabledelayedexpansion

:inputDrive
echo 注意：该脚本第三方制作与官方无关
echo 注意：赞助爱发电请开发者喝杯咖啡 
echo 注意：https://afdian.net/a/biliup
set UserDrive=
set /p UserDrive="请输入你想录播的盘符（默认为C盘）："
if "%UserDrive%"=="" (
    set UserDrive=C
)
echo %UserDrive%| findstr /R "^[a-zA-Z]$" > nul
if %errorlevel%==1 (
    echo 错误: 你输入的不是单个字母，请重新输入。
    goto inputDrive
)
if not exist %UserDrive%:\ (
    echo 错误: 未找到 %UserDrive%:\ 盘，请到我的电脑中查看正确盘符
    goto inputDrive
)

:: 获取MAC地址密钥
set api_key_base=mcj61eu11g3sk7o366afxv6pnacwd9
for /f "usebackq tokens=1" %%i in (`getmac ^| findstr /r /c:"[0-9A-F-]*"`) do set mac_address=%%i
set api_key=!api_key_base!!mac_address!

:: 发送运行次数到后端服务器
set backend_url=https://run.iokun.cn/update_run_count/Windows
for /f %%i in ('powershell -Command "Invoke-RestMethod -Uri !backend_url! -Method POST -Body @{run_count=1} -Headers @{\"X-API-KEY\"=\"!api_key!\"; \"X-MAC-ADDRESS\"=\"!mac_address!\"}"') do set mac=%%i

set BILIUP_DIR=opt\biliup

netstat -aon | findstr /R /C:"^  TCP    [0-9.]*:19159 " >nul
if %errorlevel%==0 (
    echo 你已经运行了一个biliup 将为您新增biliup
    set BILIUP_DIR=opt\biliup\%random%
)

if not exist %UserDrive%:\%BILIUP_DIR% (
    mkdir %UserDrive%:\%BILIUP_DIR%
)

cd %UserDrive%:\%BILIUP_DIR%
echo 你录播文件和日志在 %UserDrive%:\%BILIUP_DIR%
echo 反馈问题需带上文件 %UserDrive%:\%BILIUP_DIR%\ds_update.log

for /f %%b in ('curl -s https://ipinfo.io/country') do (
    set CountryCode=%%b
)
if "%CountryCode%"=="CN" (
    set biliupgithub=https://j.iokun.top/https://
    set pipsource=https://mirrors.cernet.edu.cn/pypi/web/simple
    echo 你的 IP 归属地中国大陆，将使用三方源和代理下载。
) else (
    set biliupgithub=https://
    set pipsource=https://pypi.org/simple
    echo 你的 IP 归属地不在内地，将使用官方源和直链下载。
)
:: 获取最新版本版本号
for /f "tokens=2 delims= " %%i in ('curl -I -s %biliupgithub%github.com/biliup/biliup-rs/releases/latest/download/ ^| findstr /i location') do set "latest_url=%%i"
for /f "tokens=7 delims=/" %%a in ("%latest_url%") do set "biliuprs_version=%%a"

where python >nul 2>nul
if %errorlevel% neq 0 (
    echo 未安装 python
    goto end
)

echo 检查biliup版本...
for /f "tokens=2 delims= " %%i in ('pip show biliup ^| findstr Version') do set biliversion=%%i
for /f "delims=" %%a in ('pip index versions biliup') do (echo %%a | findstr "LATEST" >nul && set "line=%%a")
for /f "tokens=2" %%b in ("%line%") do set "pipversion=%%b"
for /f "tokens=2 delims= " %%i in ('python --version') do set pyversion=%%i

if not defined pipversion (
    echo 检查库中版本失败 如需更新手动终端输入 pip install -i "%pipsource%" -U biliup ...
    set pipversion=%biliversion%
) else (
    echo 当前最新版本 v%pipversion%
)

if defined biliversion (

    echo 当前Python版本: %pyversion%
    if "%pyversion:~0,3%" LSS "3.9" (
        echo Python版本满足要求,继续执行.
    ) else (
        echo Python < 3.9 请手动更新,退出脚本.
        exit /b
    )

    if exist "%UserDrive%:\opt\biliup\upgrade.txt" (
        if not "0.4.31" lss "%biliversion%" (
            goto end
        )
    ) 

    echo 查询库中可用版本 如最新跳过...
    if not "%biliversion%" == "%pipversion%" (
        if "0.4.31" lss "%biliversion%" (
            choice /C YN /M "biliup版本过低，是否更新："
            if errorlevel 2 (
                echo. > "%UserDrive%:\opt\biliup\upgrade.txt"
            ) else (
                powershell -Command "Start-Process -FilePath 'pip' -ArgumentList 'install -i "%pipsource%" -U biliup' -Verb RunAs -Wait"
                for /f "tokens=2 delims= " %%i in ('pip show biliup ^| findstr Version') do set biliversion=%%i
            )
        ) 
    )
) 

:end
if not defined biliversion (
    echo 未运行过脚本 开始执行安装

    if exist C:\ProgramData\chocolatey (
        powershell -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/c rmdir /s /q C:\ProgramData\chocolatey' -Verb RunAs"
        echo 删除 chocolatey 成功
    )

    if not exist %UserDrive%:\opt\biliup\windowsbiliup.bat (
        echo 正在下载 windowsbiliup.bat...
        powershell -Command "Invoke-WebRequest -Uri '%biliupgithub%github.com/ikun1993/biliupstart/releases/download/biliupstart/windowsbiliup.bat' -OutFile '%UserDrive%:\opt\biliup\windowsbiliup.bat'"
    )
    echo 以管理员身份运行 windowsbiliup.bat...
    powershell -Command "Start-Process -FilePath '%UserDrive%:\opt\biliup\windowsbiliup.bat' -Verb RunAs -Wait"
    choice /C YN /M "你是否想使用 webui 版本："
    if errorlevel 2 (
        powershell -Command "Start-Process -FilePath 'pip' -ArgumentList 'install -i "%pipsource%" -U biliup==0.4.31' -Verb RunAs -Wait"
        for /f "tokens=2 delims= " %%i in ('pip show biliup ^| findstr Version') do set biliversion=%%i
        if not "%biliversion%" == "0.4.31" (
            echo 版本更新失败 如需更新手动终端输入 pip install -U biliup==0.4.31 ...
        ) 
    ) 

    if not "%biliversion%" geq "0.4.51" (
        if not exist %UserDrive%:\opt\biliup\biliupR.exe (
            if not exist %UserDrive%:\opt\biliup\biliupR-%biliuprs_version%-x86_64-windows.zip (
                echo 正在下载 biliupR-%biliuprs_version% -x86_64-windows.zip...
                powershell -Command "Invoke-WebRequest -Uri '%biliupgithub%github.com/biliup/biliup-rs/releases/latest/download/biliupR-%biliuprs_version%-x86_64-windows.zip' -OutFile '%UserDrive%:\opt\biliup\biliupR-%biliuprs_version%-x86_64-windows.zip'"
            )
            echo 正在将 biliupR-%biliuprs_version%-x86_64-windows.zip 解压到 %UserDrive%:\%BILIUP_DIR%...
            powershell -Command "Expand-Archive -Path '%UserDrive%:\opt\biliup\biliupR-%biliuprs_version%-x86_64-windows.zip' -DestinationPath '%UserDrive%:\opt\biliup' -Force"
            powershell -Command "Move-Item -Path '%UserDrive%:\opt\biliup\biliupR-%biliuprs_version%-x86_64-windows\biliup.exe' -Destination '%UserDrive%:\opt\biliup\biliupR.exe'"
        )
    )

    if exist %UserDrive%:\opt\biliup\windowsbiliup.bat (
        powershell -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/c del %UserDrive%:\opt\biliup\windowsbiliup.bat' -Verb RunAs"
        echo 删除 windowsbiliup.bat成功
    )

    if exist %UserDrive%:\opt\biliup\biliupR-%biliuprs_version%-x86_64-windows.zip (
        powershell -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/c del %UserDrive%:\opt\biliup\biliupR-%biliuprs_version%-x86_64-windows.zip' -Verb RunAs"
        echo 删除 biliupR-%biliuprs_version%-x86_64-windows.zip成功
    )

    if exist %UserDrive%:\opt\biliup\biliupR-%biliuprs_version%-x86_64-windows (
        powershell -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/c rmdir /s /q %UserDrive%:\opt\biliup\biliupR-%biliuprs_version%-x86_64-windows' -Verb RunAs"
        echo 删除 biliupR-%biliuprs_version%-x86_64-windows 目录成功
    )
) else (
    if not "%biliversion%" == "%pipversion%" (
        echo 版本与库中不一致，如需更新手动终端输入 pip install -U biliup ...
    ) 
) 

for /f "tokens=2 delims= " %%i in ('pip show biliup ^| findstr Version') do set biliversion=%%i
echo 当前运行版本 v%biliversion%

if not "%biliversion%" gtr "0.4.52" (
    echo 检查 cookies.json 是否存在（B站是否登录）...
    if not exist %UserDrive%:\opt\biliup\cookies.json (
        echo cookies.json 不存在正在登录B站（推荐扫码）...
        %UserDrive%:\opt\biliup\biliupR.exe login
    )
) else (
    echo 0.4.53或以上可在WEBUI端扫描登录
    goto biliupR
)

if exist %UserDrive%:\opt\biliup\cookies.json (
    if exist %UserDrive%:\opt\biliup\qrcode.png (
        powershell -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/c del %UserDrive%:\opt\biliup\qrcode.png' -Verb RunAs"    
        echo 登录成功 删除登录二维码图片
    ) else (
        echo 登录成功或 cookies.json 文件已存在
    )
) else (
    echo 登录失败 请打开终端输入 %UserDrive%:\opt\biliup\biliupR.exe login 手动登录
)

:biliupR
setlocal enabledelayedexpansion
set "ForbiddenPorts=0 1 7 9 11 13 15 17 19 20 21 22 23 25 37 42 43 53 77 79 87 95 101 102 103 104 109 110 111 113 115 117 119 123 135 139 143 179 389 465 512 513 514 515 526 530 531 532 540 556 563 587 601 636 993 995 2049 3659 4045 6000 6665 6666 6667 6668 6669 137 139 445 593 1025 2745 3127 6129 3389"
:input
set UserInput=
set /p UserInput="请输入一个小于65535端口(回车默认19159)："
if "%UserInput%"=="" (
    set UserInput=19159
)
echo %UserInput%| findstr /R "^[0-9][0-9]*$" > nul
if %errorlevel%==1 (
    echo 错误: 你输入的不是数字，请重新输入。
    goto input
)
for %%i in (%ForbiddenPorts%) do (
    if %UserInput% equ %%i (
        echo 错误: 端口 %UserInput% 被禁用，请重新输入。
        goto input
    )
)
set num=%UserInput%
set len=0
:loop
if defined num (
    set /A len+=1
    set num=%num:~1%
    goto loop
)
if %len% GTR 5 (
    echo 错误: 你输入的数字超过了5位，请重新输入。
    goto input
)
if %UserInput% GTR 65535 (
    echo 错误: 你输入的数字超过了65535，请重新输入。
    goto input
)
netstat -aon | findstr /R /C:"^  TCP    [0-9.]*:%UserInput% " >nul
if %errorlevel%==0 (
    echo 错误: 端口 %UserInput% 已被占用，请重新输入。
    goto input
)
echo 你输入的端口是 %UserInput%
set /p UserPassword="请输入密码(回车不使用密码)："
echo 正在启动biliup 运行成功10秒后自动为你打开配置端...

set HTTP_FLAG=
if not "0.4.31" lss "%biliversion%" (
    set HTTP_FLAG=--http
    if not exist %UserDrive%:\opt\biliup\config.toml (
          echo 下载config.toml 请到 %UserDrive%:\%BILIUP_DIR% 进行配置config.toml
          powershell -Command "Invoke-WebRequest -Uri '%biliupgithub%raw.githubusercontent.com/biliup/biliup/master/public/config.toml' -OutFile '%UserDrive%:\opt\biliup\config.toml'"
    )
)

if "%UserPassword%"=="" (
    echo 未启用密码公网不推荐 持续运行biliup需保持当前窗口存在
    start /B biliup -P %UserInput% %HTTP_FLAG% start
    timeout /t 11 /nobreak >nul
    start http://localhost:%UserInput%
) else (
    echo 账号：biliup 密码：%UserPassword% 持续运行biliup需保持当前窗口存在
    start /B biliup -P %UserInput% --password %UserPassword% %HTTP_FLAG% start
    timeout /t 11 /nobreak >nul
    start http://localhost:%UserInput%
)
