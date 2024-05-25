@echo off
 
echo 你正在使用 powershell 脚本，第一次会下载后再运行请等待 ....

for /f %%b in ('powershell -command "(Invoke-WebRequest -Uri 'https://ipinfo.io/country').Content"') do (
    set "CountryCode=%%b"
)
if "%CountryCode%"=="CN" (
    set "iokun=https://j.iokun.top/"
) else (
    set "iokun="
)

if not exist "./start.ps1" (
    powershell -command "(Invoke-WebRequest -Uri '%iokun%https://github.com/ikun1993/biliupstart/releases/download/biliupstart/start.ps1' -OutFile 'start.ps1')"
    if errorlevel 1 (
        echo 下载start.ps1脚本失败，请检查网络连接或稍后重试。
        pause
        exit /b 1
    )
)

PowerShell -ExecutionPolicy Bypass -File "./start.ps1"
