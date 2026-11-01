@echo off
setlocal EnableDelayedExpansion

:: ############################################################
:: BACKUP-SKRIPT VERSION 3.0
:: Erstellt ZIP-Sicherungen mit Tages-, Monats- und Jahresarchivierung
::
:: Autor: Martin Fitzel
:: https://www.modellbahn-anlage.de
::
:: Wenn Ihnen das Skript gefaellt:
:: https://spenden.modellbahn-anlage.de
:: ############################################################


:: CHANGELOG
:: ---------
:: 2017-12-15: Erste Version 1.0
:: 2019-02-12: Verbesserte Version 1.3
:: 2019-02-14: Konzept Monatssicherung angedacht, automatisches Loeschen hinzugefuegt
:: 2019-02-18: Monatssicherung + Jahressicherung realisiert
:: 2019-02-19: Finalisiert als Version 1.5
:: 2019-02-21: Fehler Variable 7-Zip behoben
:: 2019-02-22: Testsystem-Kopie eingebaut
:: 2020-08-29: Steuerung fuer Loeschen alter Monatssicherungen vorbereitet
:: 2023-04-13: Datei nach GIT ueberfuehrt
:: 2023-04-14: Loeschen alter Dateien optimiert
:: 2024-01-03: Erweiterte Loeschfunktion eingebaut
:: 2024-01-06: Fehlende Zeilen aus GIT wiederhergestellt
:: 2025-08-11: Diverse Korrekturen
:: 2025-10-22: Optimierungen der Verzeichnisverwaltung
:: 2026-11-01:
::    WMIC durch PowerShell ersetzt
::    Jahresordnerfehler behoben
::    Fehlerpruefung fuer 7-Zip eingebaut
::    Monatssicherungs-Loeschung vervollstaendigt
::    Ordneraltersberechnung modernisiert
::    Diverse Fehlerkorrekturen
::    Version 3.0


:: ------------------- KONFIGURATION ----------------------

set "programmpfad=C:\Program Files\7-Zip\7z.exe"

:: Quellpfad
set "quelle=D:\Backup\Datenquelle"

:: Zielpfad
set "ziel=D:\Backup\Backup"

:: Testsystem aktivieren (1 = ja, 0 = nein)
set testsystem=0
set "testsystempfad=D:\Testsystem"

:: GIT-Kopie aktivieren (1 = ja, 0 = nein)
set git=0
set "gitdatei=meinedatei.ext"
set "gitpfad=D:\GitRepo"

:: Monatssicherung aktivieren
set monatssicherung=1

:: Jahressicherung aktivieren
set jahressicherung=1

:: Aufbewahrungszeit Tagessicherung
set aufbewahrungszeit=31

:: Monatssicherungen nach einem Jahr loeschen
set monataelteralseinjahrloeschen=1
set minAlter=365


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::                    AB HIER NICHTS AENDERN                     ::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:: ------------------- VALIDIERUNG ------------------------

if not exist "%programmpfad%" (
    echo Fehler: 7-Zip nicht gefunden unter "%programmpfad%"
    pause
    exit /b 1
)

if "%quelle%"=="" (
    echo Fehler: Quellpfad nicht gesetzt!
    pause
    exit /b 1
)

if not exist "%quelle%" (
    echo Fehler: Quellpfad %quelle% existiert nicht!
    pause
    exit /b 1
)

if "%ziel%"=="" (
    echo Fehler: Zielpfad nicht gesetzt!
    pause
    exit /b 1
)

if not exist "%ziel%" (
    mkdir "%ziel%"
)


:: ------------------- DATUM ERMITTELN -------------------

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMddHHmmss"') do set datetime=%%i

set year=%datetime:~0,4%
set month=%datetime:~4,2%
set day=%datetime:~6,2%
set stunden=%datetime:~8,2%
set minuten=%datetime:~10,2%
set sekunden=%datetime:~12,2%


:: ------------------- TAGES-SICHERUNG -------------------

set "zipname=%year%-%month%-%day%-%stunden%-%minuten%-%sekunden%-TC-Tages-Sicherung.zip"

echo Erstelle Tagessicherung...

"%programmpfad%" a "%ziel%\%zipname%" "%quelle%\"

if errorlevel 1 (
    echo Fehler bei der Tagessicherung!
    pause
    exit /b 1
)


:: ------------------- MONATSSICHERUNG -------------------

if not "%monatssicherung%"=="0" (

    echo Monatssicherung wird erstellt...

    rmdir /s /q "%ziel%\%year%-%month%"

    if not exist "%ziel%\%year%-%month%" (
        md "%ziel%\%year%-%month%"
    )

    "%programmpfad%" a "%ziel%\%year%-%month%\%year%-%month%-TC-Monats-Sicherung.zip" "%quelle%"

    if errorlevel 1 (
        echo Fehler bei der Monatssicherung!
        pause
        exit /b 1
    )
)


:: ------------------- JAHRESSICHERUNG -------------------

if not "%jahressicherung%"=="0" (

    echo Jahressicherung wird erstellt...

    rmdir /s /q "%ziel%\%year%-Jahressicherung"

    if not exist "%ziel%\%year%-Jahressicherung" (
        md "%ziel%\%year%-Jahressicherung"
    )

    "%programmpfad%" a "%ziel%\%year%-Jahressicherung\%year%-TC-Jahres-Sicherung.zip" "%quelle%"

    if errorlevel 1 (
        echo Fehler bei der Jahressicherung!
        pause
        exit /b 1
    )
)


:: ------------------- TESTSYSTEM -------------------

if not "%testsystem%"=="0" (

    echo Aktualisiere Testsystem...

    if not exist "%testsystempfad%" (
        mkdir "%testsystempfad%"
    )

    xcopy "%quelle%\*" "%testsystempfad%\" /s /y /c
)


:: ------------------- GIT-KOPIE -------------------

if not "%git%"=="0" (

    echo Kopiere Datei nach GIT...

    if not exist "%gitpfad%" (
        mkdir "%gitpfad%"
    )

    xcopy "%quelle%\%gitdatei%" "%gitpfad%\" /s /y /c
)


:: ------------------- ALTE TAGESSICHERUNGEN LOESCHEN -------------------

if not "%aufbewahrungszeit%"=="0" (

    echo Loesche Tagessicherungen aelter als %aufbewahrungszeit% Tage...

    forfiles /p "%ziel%" /m *-TC-Tages-Sicherung.zip /d -%aufbewahrungszeit% /c "cmd /c del @path" 2>nul
)


:: ------------------- ALTE MONATSSICHERUNGEN LOESCHEN -------------------

if not "%monataelteralseinjahrloeschen%"=="0" (

    echo Pruefe Monatssicherungen...

    for /D %%i in ("%ziel%\*") do (

        set "Ordner=%%~fi"
        set "OrdnerName=%%~nxi"

        echo !OrdnerName! | find /i "Jahressicherung" >nul

        if errorlevel 1 (

            call :GetFolderAge "%%~fi" alter

            if defined alter (

                if !alter! gtr %minAlter% (

                    echo Loesche alten Monatsordner:
                    echo !Ordner!

                    rmdir /s /q "!Ordner!"
                )
            )
        )
    )
)


echo.
echo =============================================
echo Sicherung erfolgreich abgeschlossen.
echo =============================================
echo.

pause
exit /b 0


:GetFolderAge

setlocal

set "Ordner=%~1"

for /f %%a in ('
powershell -NoProfile -Command ^
"(New-TimeSpan -Start (Get-Item ''%Ordner%'').CreationTime -End (Get-Date)).Days"
') do set Alter=%%a

endlocal & set "%~2=%Alter%"

exit /b
