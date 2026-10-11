@echo off
setlocal enabledelayedexpansion
title DPIscord - Kaldýrýcý

:: Karakter seti uyumu
chcp 1254 >nul

echo ==============================================================
echo [+] DPIscord Kaldýrýlýyor...
echo ==============================================================
echo.

:: --- SÜREÇLERÝ SONLANDIR ---
echo [1] Arka plan iþlemleri ve Discord durduruluyor...

taskkill /F /T /IM discord.exe >nul 2>&1
if !errorlevel! equ 0 (
    echo [+] discord.exe baþarýyla durduruldu.
) else (
    echo [-] discord.exe çalýþmýyor veya zaten durdurulmuþ.
)

taskkill /F /T /IM sing-box.exe >nul 2>&1
if !errorlevel! equ 0 (
    echo [+] sing-box.exe baþarýyla durduruldu.
) else (
    echo [-] sing-box.exe çalýþmýyor veya zaten durdurulmuþ.
)

taskkill /F /T /IM ciadpi.exe >nul 2>&1
if !errorlevel! equ 0 (
    echo [+] ciadpi.exe baþarýyla durduruldu.
) else (
    echo [-] ciadpi.exe çalýþmýyor veya zaten durdurulmuþ.
)
echo.

:: --- DLL SÝLME ---
echo [2] Discord dizinindeki version.dll temizleniyor...
set "DISCORD_PATH=%localappdata%\Discord"

if exist "%DISCORD_PATH%" (
    set "FOUND_APP=0"
    for /d %%d in ("%DISCORD_PATH%\app-*") do (
        set "LATEST_APP=%%d"
        set "FOUND_APP=1"
    )
    
    if !FOUND_APP! equ 1 (
        set "TARGET_DLL=!LATEST_APP!\version.dll"
        if exist "!TARGET_DLL!" (
            del /q /f "!TARGET_DLL!" >nul 2>&1
            if !errorlevel! equ 0 (
                echo [+] version.dll dosyasý "!LATEST_APP!" klasöründen silindi.
            ) else (
                echo [-] HATA: version.dll silinemedi!
            )
        ) else (
            echo [-] version.dll zaten bulunamadý veya daha önceden silinmiþ.
        )
    ) else (
        echo [-] Discord 'app-' klasörü bulunamadý.
    )
) else (
    echo [-] Discord kurulumu bulunamadý.
)
echo.

:: --- KISAYOLLARI TEMÝZLE ---
echo [3] Kýsayollar kaldýrýlýyor...

:: Masaüstü kýsayolu
for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "REAL_DESKTOP=%%i"
set "SC_PATH=!REAL_DESKTOP!\Discord (DPI).lnk"
if exist "!SC_PATH!" (
    del /q /f "!SC_PATH!" >nul 2>&1
    echo [+] Masaüstü kýsayolu silindi.
)

:: Startup kýsayolu
set "STARTUP_LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Discord (DPI).lnk"
if exist "%STARTUP_LNK%" (
    del /q /f "%STARTUP_LNK%" >nul 2>&1
    echo [+] Baþlangýç kýsayolu silindi.
)
echo.

:: --- SONLANDIRMA UYARISI ---
echo ==============================================================
echo [+] ÝÞLEM TAMAMLANDI.
echo DPIscord eklentileri baþarýyla kaldýrýldý.
echo.
echo Þu anda bulunduðunuz bu klasörü ^(ve içindekileri^) artýk 
echo güvenle silebilirsiniz.
echo ==============================================================
echo.
pause
exit