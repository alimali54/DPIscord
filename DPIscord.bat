@echo off
setlocal enabledelayedexpansion
title DPIscord

:: Karakter seti uyumu
chcp 1254 >nul

:: --- GOODBYEDPI (SERVÝS VE SÜREÇ) KONTROLÜ ---
:GDPI_KONTROL
set "GDPI_FOUND=0"
tasklist /FI "IMAGENAME eq goodbyedpi.exe" 2>nul | findstr /i "goodbyedpi.exe" >nul
if !errorlevel! equ 0 set "GDPI_FOUND=1"
sc query "GoodbyeDPI" >nul 2>&1
if !errorlevel! neq 1060 set "GDPI_FOUND=1"

if %GDPI_FOUND% equ 1 goto :GDPI_UYARI
goto :YAPILANDIRMA

:GDPI_UYARI
cls
setlocal DisableDelayedExpansion
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo UYARI: Sistemde GoodbyeDPI (Süreç veya Servis) saptandý!
echo ByeDPI ile çakýþma yaþanmamasý için tamamen kaldýrýlmalýdýr.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo.
echo Servisleri durdurmak ve kaldýrmak için ENTER'a basýn...
pause >nul

:: Yönetici haklarýyla temizlik komutlarý
powershell -Command "Start-Process cmd -ArgumentList '/c taskkill /f /im goodbyedpi.exe & sc stop GoodbyeDPI & sc delete GoodbyeDPI & sc stop WinDivert & sc delete WinDivert' -Verb RunAs -WindowStyle Hidden"

echo [+] Temizlik komutlarý yönetici olarak gönderildi.
echo [!] Eðer UAC (Kullanýcý Hesabý Denetimi) çýktýysa onay verin.
endlocal
timeout /t 3 >nul

goto :GDPI_KONTROL

:: --- YAPILANDIRMA ---
:YAPILANDIRMA
set "DPI_SUBDIR=byedpi"
set "STRATEGY_FILE=%DPI_SUBDIR%\strategies.txt"
set "CIADPI_EXE=%DPI_SUBDIR%\ciadpi.exe"
set "GOST_EXE=%DPI_SUBDIR%\gost.exe"
set "DLL_SOURCE=version.dll"
set "TEST_URL=https://updates.discord.com"
set "PORT=8848"
set "GOST_PORT=8849"
set "VBS_NAME=opendiscord.vbs"

echo [1] ByeDPI stratejisi aranýyor...

:STRATEJI_DENE
echo.
if not exist "%STRATEGY_FILE%" (
    echo HATA: %STRATEGY_FILE% bulunamadý!
    pause
    exit
)

:: --- STRATEJI SAYISINI HESAPLA ---
set "TOTAL_STRATS=0"
for /f "usebackq" %%a in ("%STRATEGY_FILE%") do set /a TOTAL_STRATS+=1

echo [%TOTAL_STRATS%] adet strateji taranacak...
echo.

set "CURRENT_INDEX=0"
for /f "usebackq tokens=*" %%s in ("%STRATEGY_FILE%") do (
    set /a CURRENT_INDEX+=1
    set "STRAT=%%s"
    
    echo Deneniyor (!CURRENT_INDEX!/%TOTAL_STRATS%^): !STRAT!
    
    :: Sadece süreç varsa taskkill çalýþýr, böylece "sürücü bulunamadý" uyarýsý gelmez
    tasklist /FI "IMAGENAME eq ciadpi.exe" 2>nul | findstr /i "ciadpi.exe" >nul && taskkill /f /im ciadpi.exe >nul 2>&1
    
    :: ciadpi'yi arka planda baþlatýyoruz
    start /b "" "%CIADPI_EXE%" !STRAT! -p %PORT%
    
    :: Yeni bilgisayarda ciadpi'nin portu rezerve etmesi için stabil bekleme süresi
    ping 127.0.0.1 -n 3 >nul
    
    :: Týrnaklama hatasý düzeltilmiþ curl sessiz test isteði
    "%~dp0byedpi\curl" -I --socks5 127.0.0.1:%PORT% --doh-url https://1.1.1.1/dns-query %TEST_URL% --connect-timeout 4 >nul 2>&1
    
    if !errorlevel! equ 0 (
        echo.
        echo [+] ÇALIÞAN STRATEJÝ BULUNDU (!CURRENT_INDEX!/%TOTAL_STRATS%^): !STRAT!
        set "BEST_STRAT=!STRAT!"
        goto BASARILI
    )
)

echo.
echo HATA: Hiçbir strateji çalýþmadý!
pause
exit


:BASARILI
taskkill /f /im ciadpi.exe >nul 2>&1

:: --- VBS LAUNCHER OLUÞTUR ---
set "VBS_PATH=%~dp0%VBS_NAME%"
set "FULL_CIADPI_PATH=%~dp0%CIADPI_EXE%"
set "FULL_GOST_PATH=%~dp0%GOST_EXE%"
set "DLL_SOURCE=%~dp0%DLL_SOURCE%"

(
echo Option Explicit
echo Dim fso, shell, localAppData, discordPath, latestAppFolder, appSubFolder, targetDll, command, pName, processes
echo Set fso = CreateObject^("Scripting.FileSystemObject"^)
echo Set shell = CreateObject^("WScript.Shell"^)
echo.
echo ' --- Mevcut surecleri zorla sonlandir ---
echo processes = Array^("ciadpi.exe", "gost.exe", "discord.exe"^)
echo For Each pName In processes
echo    On Error Resume Next
echo    shell.Run "taskkill /F /T /IM " ^& pName, 0, True
echo    On Error GoTo 0
echo Next
echo WScript.Sleep 500
echo.
echo ' --- Otomatik Eklenen ciadpi ve Gost ---
echo shell.Run "cmd /c start """" /b ""%FULL_CIADPI_PATH%"" %BEST_STRAT% -p %PORT%", 0, False
echo WScript.Sleep 100
echo shell.Run "cmd /c start """" /b ""%FULL_GOST_PATH%"" -L socks5://127.0.0.1:%GOST_PORT%?dns=1.1.1.1:853/tls -F socks5://127.0.0.1:%PORT%", 0, False
echo WScript.Sleep 100
echo.
echo ' --- Doðrudan Kullanýcýnýn LocalAppData Klasörünü Hedef Al ---
echo localAppData = shell.ExpandEnvironmentStrings^("%%localappdata%%"^)
echo discordPath = localAppData ^& "\Discord"
echo.
echo If fso.FolderExists^(discordPath^) Then
echo    ' app- ile baþlayan aktif sürüm klasörünü doðrudan buluyoruz
echo    For Each appSubFolder In fso.GetFolder^(discordPath^).SubFolders
echo        If InStr^(LCase^(appSubFolder.Name^), "app-"^) ^> 0 Then
echo            latestAppFolder = appSubFolder.Path
echo        End If
echo    Next
echo.
echo    ' Eðer sürüm klasörü bulunduysa DLL kopyala ve Discord'u baþlat
echo    If Not latestAppFolder = "" Then
echo        targetDll = latestAppFolder ^& "\version.dll"
echo        If fso.FileExists^("%DLL_SOURCE%"^) Then
echo            On Error Resume Next
echo            fso.CopyFile "%DLL_SOURCE%", targetDll, True
echo            On Error GoTo 0
echo        End If
echo.
echo        ' --- Discord'u Update.exe üzerinden Proxy Parametresiyle Baþlatma ---
echo        command = "cmd /c start """" /b """ ^& discordPath ^& "\Update.exe"" --processStart Discord.exe --a=--proxy-server=socks5://127.0.0.1:%GOST_PORT%"
echo        shell.Run command, 0, False
echo    End If
echo End If
) > "%VBS_PATH%"

:: --- MASAÜSTÜ KISAYOL (OneDrive ve Bölgesel Dil Uyumlu) ---
:: Masaüstü yolunu PowerShell ile doðrudan Windows'tan çekiyoruz
for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "REAL_DESKTOP=%%i"

set "SC_PATH=%REAL_DESKTOP%\Discord (DPI).lnk"
set "WK_DIR=%~dp0proxychains"

:: PowerShell komutunu tek satýrda ama daha güvenli çalýþtýrýyoruz
powershell -ExecutionPolicy Bypass -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SC_PATH%'); $s.TargetPath = '%VBS_PATH%'; $s.WorkingDirectory = '%WK_DIR%'; $s.IconLocation = '%LOCALAPPDATA%\Discord\app.ico'; $s.Save()"

if %errorlevel% equ 0 (echo [+] Masaüstü kýsayolu oluþturuldu.) else (echo [-] HATA: Kýsayol oluþturulamadý!)


:: --- STARTUP KONTROL ---
echo.
set /p "ans=[2] Sistem açýlýþýna (Startup) eklemek ister misiniz? (E/H): "
if /i "%ans%" neq "E" goto BITIS

:: Kopyalama iþlemini parantez içinden çýkarýp deðiþkene atýyoruz
set "SRC_LNK=%USERPROFILE%\Desktop\Discord (DPI).lnk"
set "DST_LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Discord (DPI).lnk"

:: Kopyalama komutu
copy /y "%SRC_LNK%" "%DST_LNK%" >nul 2>&1

if %errorlevel% equ 0 (
    echo [+] Baþlangýca eklendi.
) else (
    echo [-] HATA: Kýsayol kopyalanamadý!
)
:BITIS
echo.
echo ÝÞLEM TAMAMLANDI.
pause