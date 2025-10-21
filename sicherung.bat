@echo off
setlocal EnableDelayedExpansion

:: ############################################################
:: BACKUP-SKRIPT VERSION 2.2
:: Erstellt ZIP-Sicherungen mit Tages-, Monats- und Jahresarchivierung
:: Autor: Martin Fitzel
:: ############################################################
::
::
::
:: Wenn Sie das Skript verwenden, koennen Sie uns ueber https://spenden.modellbahn-anlage.de gerne eine Kleinigkeit zukommen lassen, dann wird das Skript auch weiterentwickelt :)
::
:: Dieses Skript erstellt einen Ordner oder Datei mit dem Datum der Sicherung
:: ***********************************************************************************************************************************
:: Skript Version 2.0
:: Ersteller: Martin Fitzel - http://www.modellbahn-anlage.de
:: ***********************************************************************************************************************************
::
::
::
:: CHANGELOG
:: ---------
:: 2017-12-15: Erste Version 1.0
:: 2019-02-12: Verbesserte Version 1.3
:: 2019-02-14: Konzept Monatssicherung angedacht, automatisches Loeschen hinzugefuegt
:: 2019-02-18: Monatssicherung + Jahressicherung realisiert
:: 2019-02-19: Finalisiert als Version 1.5
:: 2019-02-21: Fehler Variable 7-Zip behoben.  Version 1.5.1
::			   Schluss "\" in den Variablen entfernt - fuehrte zu keinen Fehlern, muss autom. in Zukunft ueberprueft werden...
:: 2019-02-22: Einbau einer Funktion, um Daten zum Testsystem zu kopieren - Version 1.6
:: 2020-08-29: Variable eingebaut, die später darueber entscheidet, ob nach der Jahressicherung die Monatssicherungen geloescht werden sollen.
:: 2023-04-13: Datei nach GIT ueberfuehrt
:: 2023-04-14: Loeschen von alten DATEIEN (nicht Ordnern!) optimiert (Doku angepasst)
:: Version 2.0
:: 2024-01-03: Loeschen hinzugefuegt - bitte dabei den Text bei der Einstellung DRINGEND dazu beachten!
:: 2024-01-06: Vergessene Codezeilen durch GIT wieder eingefuegt :) 
:: 2025-08-11: Schreibfehler behoben, GIT Repository angelegt
::             Diverse Aenderungen, Anpassungen
::
::
::
:: ------------------- KONFIGURATION ----------------------
::
:: Pfad zu 7-Zip (bitte ohne Anfuehrungszeichen)
set "programmpfad=C:\Program Files\7-Zip\7z.exe"

:: Quellpfad (Ordner, der gesichert werden soll)
set "quelle=D:\Datenquelle"

:: Zielpfad fuer Sicherungen
set "ziel=D:\Backups"

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

:: Aufbewahrungszeit der Tagessicherungen in Tagen
set aufbewahrungszeit=31

:: Monatssicherungen loeschen, wenn älter als 365 Tage
set monataelteralseinjahrloeschen=1
set minAlter=365

:: ------------------- VALIDIERUNG ------------------------

:: Pruefen, ob 7-Zip vorhanden ist
if not exist "%programmpfad%" (
    echo Fehler: 7-Zip nicht gefunden unter "%programmpfad%"
    pause
    exit /b
)

:: Pruefen, ob Quellpfad gesetzt und vorhanden ist
if "%quelle%"=="" (
    echo Fehler: Quellpfad nicht gesetzt!
    pause
    exit /b
)
if not exist "%quelle%" (
    echo Fehler: Quellpfad %quelle% existiert nicht!
    pause
    exit /b
)

:: Pruefen, ob Zielpfad gesetzt
if "%ziel%"=="" (
    echo Fehler: Zielpfad nicht gesetzt!
    pause
    exit /b
)

:: Zielordner ggf. erstellen
if not exist "%ziel%" (
    mkdir "%ziel%"
)

:: ------------------- DATUM ERMITTELN -------------------

:: Datum/Zeit via WMIC (lokalitätsunabhängig)
for /f %%i in ('wmic os get localdatetime ^| find "."') do set datetime=%%i
set year=%datetime:~0,4%
set month=%datetime:~4,2%
set day=%datetime:~6,2%
set stunden=%datetime:~8,2%
set minuten=%datetime:~10,2%
set sekunden=%datetime:~12,2%

:: ------------------- TAGES-SICHERUNG -------------------

set "zipname=%year%-%month%-%day%-%stunden%-%minuten%-%sekunden%-TC-Tages-Sicherung.zip"
"%programmpfad%" a "%ziel%\%zipname%" "%quelle%\"

:: ------------------- TAGESSICHERUNGEN LoeSCHEN -------------------

if not %aufbewahrungszeit%==0 (
    echo Tagessicherungen, älter als %aufbewahrungszeit% Tage, werden geloescht...
    forfiles /p "%ziel%" /m *.zip /d -%aufbewahrungszeit% /c "cmd /c del @path"
)

:: ------------------- MONATSSICHERUNG -------------------

if not %monatssicherung%==0 (
    echo Monatssicherung wird erstellt...
    set "monatspfad=%ziel%\%year%-%month%"
    if exist "%monatspfad%" rmdir /s /q "%monatspfad%"
    mkdir "%monatspfad%"
    "%programmpfad%" a "%monatspfad%\%year%-%month%-TC-Monats-Sicherung.zip" "%quelle%\"
)

:: ------------------- JAHRESSICHERUNG -------------------

if not %jahressicherung%==0 (
    echo Jahressicherung wird erstellt...
    set "jahrespfad=%ziel%\%year%-Jahressicherung"
    if exist "%jahrespfad%" rmdir /s /q "%jahrespfad%"
    mkdir "%jahrespfad%"
    "%programmpfad%" a "%jahrespfad%\%year%-TC-Jahres-Sicherung.zip" "%quelle%\"
)

:: ------------------- MONATSSICHERUNGEN ALT LoeSCHEN -------------------

if not %monataelteralseinjahrloeschen%==0 (
    echo Alte Monatssicherungen (älter als %minAlter% Tage) werden ueberprueft...
    for /d %%D in ("%ziel%\*-*") do (
        set "ordner=%%~fD"
        set "name=%%~nxD"
        call :GetFolderAge "%%~fD" age
        if !age! GTR %minAlter% (
            echo ueberpruefe: !name!
            echo !name! | find /i "Jahressicherung" >nul
            if errorlevel 1 (
                echo Loesche Ordner: !ordner!
                rmdir /s /q "!ordner!"
            ) else (
                echo Behalte Jahressicherung: !ordner!
            )
        )
    )
)

:: ------------------- TESTSYSTEM-KOPIE -------------------

if not %testsystem%==0 (
    echo Testsystem wird aktualisiert...
    if not exist "%testsystempfad%" mkdir "%testsystempfad%"
    xcopy "%quelle%\*" "%testsystempfad%\" /s /y /c
)

:: ------------------- GIT-KOPIE -------------------

if not %git%==0 (
    echo Kopiere Datei nach GIT...
    if not exist "%gitpfad%" mkdir "%gitpfad%"
    xcopy "%quelle%\%gitdatei%" "%gitpfad%\" /s /y /c
)

echo Sicherung abgeschlossen.
pause
exit /b

:: ------------------- FUNKTION: GetFolderAge -------------------

:GetFolderAge
:: Eingabe: Pfad %1, Ausgabevariable %2
:: Ermittelt das Alter eines Ordners in Tagen (ueber PowerShell)
setlocal
set "ordner=%~1"
for /f %%a in ('powershell -nologo -command "(Get-Date) - (Get-Item '%ordner%').CreationTime.TotalDays"') do (
    set /a age=%%a
)
endlocal & set "%~2=%age%"
exit /b
