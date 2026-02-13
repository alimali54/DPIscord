@echo off
setlocal enabledelayedexpansion
title DPIscord

:: Karakter seti uyumu
chcp 1254 >nul

:: --- GOODBYEDPI (SERVÝS VE SÜREÇ) KONTROLÜ ---
set "GDPI_FOUND=0"

:: 1. Süreç kontrolü
tasklist /FI "IMAGENAME eq goodbyedpi.exe" 2>nul | findstr /i "goodbyedpi.exe" >nul
if !errorlevel! equ 0 set "GDPI_FOUND=1"

:: 2. Servis kontrolü
sc query "GoodbyeDPI" >nul 2>&1
if !errorlevel! neq 1060 set "GDPI_FOUND=1"

:: HATA BURADAYDI: Parantez bloðunu terk edip GOTO ile zýplýyoruz
if %GDPI_FOUND% equ 1 goto :GDPI_UYARI
goto :YAPILANDIRMA

:GDPI_UYARI
setlocal DisableDelayedExpansion
echo.
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
goto :YAPILANDIRMA

:YAPILANDIRMA
:: --- YAPILANDIRMA ---
set "DPI_SUBDIR=byedpi"
set "STRATEGY_FILE=%DPI_SUBDIR%\strategies.txt"
set "CIADPI_EXE=%DPI_SUBDIR%\ciadpi.exe"
set "DLL_SOURCE=version.dll"
set "TEST_URL=https://updates.discord.com"
set "PORT=8848"
set "VBS_NAME=opendiscord.vbs"

:DNS_KONTROL
cls
echo [1] DNS Zehirlenmesi Kontrol Ediliyor...

:: En baþta deðiþkenleri sýfýrla/tanýmsýz yapma, "BULUNAMADI" ata
set "LOCAL_IP=YEREL_IP_YOK"
set "SAFE_IP=GÜVENLÝ_IP_YOK"

:: 1. Yerel DNS (IPv4 Sabitlendi)
:: Çýktýyý satýr satýr tara, içinde nokta (.) olan her þeyi kontrol et
for /f "usebackq tokens=*" %%a in (`nslookup updates.discord.com 2^>nul`) do (
    echo %%a | findstr /v "#" | findstr "\." >nul
    if !errorlevel! equ 0 (
        :: Satýrýn içindeki IP'yi cýmbýzla çek (Address: kýsmýný atla)
        for %%b in (%%a) do (
            echo %%b | findstr /r "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" >nul
            if !errorlevel! equ 0 set "LOCAL_IP=%%b"
        )
    )
)

:: 2. Cloudflare DoH (Gerçek IP Ayýklama)
for /f "tokens=*" %%g in ('curl -s -H "accept: application/dns-json" "https://1.1.1.1/dns-query?name=updates.discord.com&type=A"') do (
    set "JSON_OUT=%%g"
    for %%h in (!JSON_OUT!) do (
        set "ITEM=%%h"
        echo !ITEM! | findstr /r "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" >nul
        if !errorlevel! equ 0 (
            set "SAFE_IP=!ITEM!"
            set "SAFE_IP=!SAFE_IP:"=!"
            set "SAFE_IP=!SAFE_IP:,=!"
            set "SAFE_IP=!SAFE_IP:}=!"
            set "SAFE_IP=!SAFE_IP:]=!"
            set "SAFE_IP=!SAFE_IP:data:=!"
            set "SAFE_IP=!SAFE_IP: =!"
            goto :PRINT_IPS
        )
    )
)

:PRINT_IPS
echo.
echo ------------------------------------------
:: ":" iþaretlerini ayný sütuna hizaladýk
echo Yerel Sorgu (ISS)   : %LOCAL_IP%
echo Güvenli Sorgu (DoH) : %SAFE_IP%
echo ------------------------------------------
echo.

:: Eðer ikisi de bulunamadýysa uyarý ver
if "%LOCAL_IP%"=="YEREL_IP_YOK" (
    echo [!] HATA: Yerel IP adresi tespit edilemedi. Internet baðlantýnýzý kontrol edin.
    pause & goto :DNS_KONTROL
)

:: Karþýlaþtýrma
set "LOCAL_COMP=%LOCAL_IP:~0,5%"
set "SAFE_COMP=%SAFE_IP:~0,5%"

if "%LOCAL_COMP%" neq "%SAFE_COMP%" (
    setlocal DisableDelayedExpansion
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    echo HATA: DNS Zehirlenmesi Saptandý! ^(ISS Mudahalesi Var^)
    echo/
    echo Servis saðlayýcýnýz DNS isteklerinize müdahale ediyor.
    echo Lütfen YogaDNS veya benzeri bir DoH istemcisi kullanýn.
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    echo/
    endlocal
    echo Tekrar kontrol etmek için ENTER'a basýn...
    pause >nul
    goto :DNS_KONTROL
)



echo [+] DURUM: DNS Temiz.
echo.
echo [2] ByeDPI stratejisi bulup Masaüstü kýsayolu oluþturmak için ENTER'a basýn.
pause >nul

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
    
    taskkill /f /im ciadpi.exe >nul 2>&1
    
    :: Programý baþlatýrken parametreleri týrnaksýz ama güvenli geçiyoruz
    start /b "" "%CIADPI_EXE%" !STRAT! -p %PORT%
    
    :: Test süresi (timeout bazen parantez hatasý verebilir, alternatif uyku)
    ping 127.0.0.1 -n 4 >nul
    
    curl -I --socks5-hostname 127.0.0.1:%PORT% %TEST_URL% --connect-timeout 4 >nul 2>&1
    if !errorlevel! equ 0 (
        echo.
        echo [+] ÇALIÞAN STRATEJI BULUNDU (!CURRENT_INDEX!/%TOTAL_STRATS%^): !STRAT!
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
set "VBS_PATH=%~dp0proxychains\%VBS_NAME%"
set "FULL_CIADPI_PATH=%~dp0%CIADPI_EXE%"

(
echo Option Explicit
echo Dim fso, shell, basePath, userFolder, discordPath, exePath, command, pName, processes
echo Set fso = CreateObject^("Scripting.FileSystemObject"^)
echo Set shell = CreateObject^("WScript.Shell"^)
echo.
echo ' --- Mevcut surecleri zorla sonlandir ---
echo processes = Array^("ciadpi.exe", "proxychains_win32_x64.exe", "discord.exe"^)
echo For Each pName In processes
echo    On Error Resume Next
echo    shell.Run "taskkill /F /T /IM " ^& pName, 0, True
echo    On Error GoTo 0
echo Next
echo WScript.Sleep 100
echo.
echo ' --- Otomatik Eklenen ciadpi ---
echo shell.Run "cmd /c start """" /b ""%FULL_CIADPI_PATH%"" %BEST_STRAT% -p %PORT%", 0, False
echo WScript.Sleep 200
echo.
echo basePath = "C:\Users"
echo For Each userFolder In fso.GetFolder^(basePath^).SubFolders
echo    discordPath = userFolder.Path ^& "\AppData\Local\Discord"
echo    If fso.FolderExists^(discordPath^) Then
echo        exePath = FindDiscordExe^(discordPath^)
echo        If Not exePath = "" Then
echo            ' --- Proxychains ile Discord Baslatma ---
echo            command = "cmd /c start """" /b proxychains_win32_x64.exe -f proxychains.conf """ ^& exePath ^& """"
echo            shell.Run command, 0, False
echo            Exit For
echo        End If
echo    End If
echo Next
echo.
echo Function FindDiscordExe^(folderPath^)
echo    Dim folderQueue, currentFolder, subFolder, file
echo    Set folderQueue = CreateObject^("Scripting.Dictionary"^)
echo    folderQueue.Add folderPath, folderPath
echo    FindDiscordExe = ""
echo    Do Until folderQueue.Count = 0
echo        For Each currentFolder In folderQueue
echo            folderQueue.Remove currentFolder
echo            If fso.FolderExists^(currentFolder^) Then
echo                For Each file In fso.GetFolder^(currentFolder^).Files
echo                    If LCase^(fso.GetFileName^(file^)^) = "discord.exe" Then
echo                        FindDiscordExe = file.Path
echo                        Exit Function
echo                    End If
echo                Next
echo                For Each subFolder In fso.GetFolder^(currentFolder^).SubFolders
echo                    folderQueue.Add subFolder.Path, subFolder.Path
echo                Next
echo            End If
echo        Next
echo    Loop
echo End Function
) > "%VBS_PATH%"

:: --- MASAÜSTÜ KISAYOL (Yeni VBS Yoluna Göre) ---
set "SC_PATH=%USERPROFILE%\Desktop\Discord (DPI).lnk"
:: WorkingDirectory olarak \proxychains\ klasörünü veriyoruz ki proxychains.conf dosyasýný bulabilsin
set "WK_DIR=%~dp0proxychains"

powershell -ExecutionPolicy Bypass -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SC_PATH%'); $s.TargetPath = '%VBS_PATH%'; $s.WorkingDirectory = '%WK_DIR%'; $s.IconLocation = '%LOCALAPPDATA%\Discord\app.ico'; $s.Save()"

echo [+] Masaüstü kýsayolu oluþturuldu.

:: --- STARTUP KONTROL ---
echo.
set /p "ans=[3] Sistem açýlýþýna (Startup) eklemek ister misiniz? (E/H): "
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