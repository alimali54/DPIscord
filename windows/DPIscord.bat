@echo off
setlocal enabledelayedexpansion
title DPIscord v2.3

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
set "SINGBOX_EXE=%DPI_SUBDIR%\sing-box.exe"
set "SINGBOX_CONFIG=%DPI_SUBDIR%\sing-box.json"
set "DLL_SOURCE=%DPI_SUBDIR%\version.dll"
set "INI_SOURCE=%DPI_SUBDIR%\drover.ini"
set "TEST_URL=https://discord.com/api/v9/experiments"
set "PORT=8848"
set "SINGBOX_PORT=8849"
set "VBS_NAME=opendiscord.vbs"

echo [1] ByeDPI stratejisi aranýyor...

if not exist "%STRATEGY_FILE%" (
    echo HATA: %STRATEGY_FILE% bulunamadý!
    pause
    exit
)

:: --- STRATEJÝ SAYISINI HESAPLA ---
set "TOTAL_STRATS=0"
for /f "usebackq" %%a in ("%STRATEGY_FILE%") do set /a TOTAL_STRATS+=1

echo [%TOTAL_STRATS%] adet strateji taranacak...
echo.

set "CURRENT_INDEX=0"

:STRATEJI_DONGU
:: Her seferinde dosyayý satýr satýr okur ama kaldýðýmýz indeksi atlayarak devam eder
set "TEMP_INDEX=0"
for /f "usebackq tokens=*" %%s in ("%STRATEGY_FILE%") do (
    set /a TEMP_INDEX+=1
    if !TEMP_INDEX! gtr %CURRENT_INDEX% (
        set "CURRENT_INDEX=!TEMP_INDEX!"
        set "STRAT=%%s"
        goto :STRATEJI_TEST_ET
    )
)

echo.
echo HATA: Hiçbir strateji çalýþmadý veya kullanýcý tüm stratejileri reddetti!
pause
exit

:STRATEJI_TEST_ET
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
    echo [+] Strateji Baþarýlý, test edilmesi için Discord baþlatýlýyor...
    set "BEST_STRAT=!STRAT!"
    goto :DOGRULAMA_VBS_OLUSTUR
)

goto :STRATEJI_DONGU


:DOGRULAMA_VBS_OLUSTUR
:: Kullanýcýnýn denemesi için geçici/kalýcý VBS oluþturuluyor
set "VBS_PATH=%~dp0%VBS_NAME%"
set "FULL_CIADPI_PATH=%~dp0%CIADPI_EXE%"
set "FULL_SINGBOX_PATH=%~dp0%SINGBOX_EXE%"
set "FULL_SINGBOX_CONFIG_PATH=%~dp0%SINGBOX_CONFIG%"
set "DLL_SOURCE=%~dp0%DLL_SOURCE%"

(
echo Option Explicit
echo Dim fso, shell, localAppData, discordPath, latestAppFolder, appSubFolder, targetDll, targetIni, command, pName, processes
echo Set fso = CreateObject^("Scripting.FileSystemObject"^)
echo Set shell = CreateObject^("WScript.Shell"^)
echo.
echo ' --- Mevcut surecleri zorla sonlandir ---
echo processes = Array^("ciadpi.exe", "sing-box.exe", "discord.exe"^)
echo For Each pName In processes
echo     On Error Resume Next
echo     shell.Run "taskkill /F /T /IM " ^& pName, 0, True
echo     On Error GoTo 0
echo Next
echo WScript.Sleep 200
echo.
echo ' --- Otomatik Eklenen ciadpi ve SINGBOX ---
echo shell.Run "cmd /c start """" /b ""%FULL_CIADPI_PATH%"" %BEST_STRAT% -p %PORT%", 0, False
echo WScript.Sleep 100
echo shell.Run "cmd /c start """" /b ""%FULL_SINGBOX_PATH%"" run -c ""%FULL_SINGBOX_CONFIG_PATH%""", 0, False
echo WScript.Sleep 100
echo.
echo ' --- Doðrudan Kullanýcýnýn LocalAppData Klasörünü Hedef Al ---
echo localAppData = shell.ExpandEnvironmentStrings^("%%localappdata%%"^)
echo discordPath = localAppData ^& "\Discord"
echo.
echo If fso.FolderExists^(discordPath^) Then
echo     ' app- ile baþlayan aktif sürüm klasörünü doðrudan buluyoruz
echo     For Each appSubFolder In fso.GetFolder^(discordPath^).SubFolders
echo         If InStr^(LCase^(appSubFolder.Name^), "app-"^) ^> 0 Then
echo             latestAppFolder = appSubFolder.Path
echo         End If
echo     Next
echo.
echo     ' Eðer sürüm klasörü bulunduysa DLL kopyala ve Discord'u baþlat
echo     If Not latestAppFolder = "" Then
echo         targetDll = latestAppFolder ^& "\version.dll"
echo         targetIni = latestAppFolder ^& "\drover.ini"
echo.
echo         If fso.FileExists^("%DLL_SOURCE%"^) Then
echo             On Error Resume Next
echo             fso.CopyFile "%DLL_SOURCE%", targetDll, True
echo             On Error GoTo 0
echo         End If
echo.
echo         If fso.FileExists^("%INI_SOURCE%"^) Then
echo             On Error Resume Next
echo             fso.CopyFile "%INI_SOURCE%", targetIni, True
echo             On Error GoTo 0
echo         End If
echo.
echo         ' --- Discord'u Sade Komutla Baþlatma ---
echo         command = "cmd /c start """" /b """ ^& discordPath ^& "\Update.exe"" --processStart Discord.exe"
echo         shell.Run command, 0, False
echo.
echo         WScript.Sleep 10000
echo         If fso.FileExists^(targetIni^) Then
echo             On Error Resume Next
echo             fso.DeleteFile targetIni, True
echo             On Error GoTo 0
echo         End If
echo     End If
echo End If
) > "%VBS_PATH%"

echo [^^!] Discord tetikleniyor, lütfen bekleyin...
start "" "%VBS_PATH%"

echo.
set /p "user_verify=[?] Discord açýldý mý? (E/H): "
if /i "%user_verify%"=="E" (
    echo.
    echo [+] SEÇÝLEN STRATEJÝ ONAYLANDI: %BEST_STRAT%
    goto :KISAYOL_OLUSTUR
) else (
    echo [-] Strateji baþarýsýz oldu. Sýradaki stratejiye geçiliyor...
    taskkill /f /im ciadpi.exe >nul 2>&1
    taskkill /f /im sing-box.exe >nul 2>&1
    taskkill /f /im discord.exe >nul 2>&1
    echo.
    goto :STRATEJI_DONGU
)


:KISAYOL_OLUSTUR
:: --- MASAÜSTÜ KISAYOL (OneDrive ve Bölgesel Dil Uyumlu) ---
for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "REAL_DESKTOP=%%i"

set "SC_PATH=%REAL_DESKTOP%\Discord (DPI).lnk"
set "WK_DIR=%~dp0"

powershell -ExecutionPolicy Bypass -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SC_PATH%'); $s.TargetPath = '%VBS_PATH%'; $s.WorkingDirectory = '%WK_DIR%'; $s.IconLocation = '%LOCALAPPDATA%\Discord\app.ico'; $s.Save()"

if %errorlevel% equ 0 (echo [+] Masaüstü kýsayolu oluþturuldu.) else (echo [-] HATA: Kýsayol oluþturulamadý!)

:: --- STARTUP KONTROL ---
echo.
set /p "ans=[2] Sistem açýlýþýna (Startup) eklemek ister misiniz? (E/H): "
if /i "%ans%" neq "E" goto BITIS

set "SRC_LNK=%REAL_DESKTOP%\Discord (DPI).lnk"
set "DST_LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Discord (DPI).lnk"

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