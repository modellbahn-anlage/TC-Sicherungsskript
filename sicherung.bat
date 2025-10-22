@echo off
setlocal EnableDelayedExpansion

:: ############################################################
:: BACKUP-SKRIPT VERSION 2.2
:: Erstellt ZIP-Sicherungen mit Tages-, Monats- und Jahresarchivierung
:: Autor: Martin Fitzel - http://www.modellbahn-anlage.de
:: ############################################################
::
::
:: Wenn Sie das Skript verwenden, koennen Sie uns ueber https://spenden.modellbahn-anlage.de gerne eine Kleinigkeit zukommen lassen, dann wird das Skript auch weiterentwickelt :)
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
:: 2020-08-29: Variable eingebaut, die spaeter darueber entscheidet, ob nach der Jahressicherung die Monatssicherungen geloescht werden sollen.
:: 2023-04-13: Datei nach GIT ueberfuehrt
:: 2023-04-14: Loeschen von alten DATEIEN (nicht Ordnern!) optimiert (Doku angepasst)
:: Version 2.0
:: 2024-01-03: Loeschen hinzugefuegt - bitte dabei den Text bei der Einstellung DRINGEND dazu beachten!
:: 2024-01-06: Vergessene Codezeilen durch GIT wieder eingefuegt :) 
:: 2025-08-11: Schreibfehler behoben, GIT Repository angelegt
::             Diverse Aenderungen, Anpassungen
:: 2025-10-22: Diverse Aenderungen - Optimierung des Skripts - kein Loeschen der Ordner - hier noch Fehler!
::
::
::
:: ------------------- KONFIGURATION ----------------------
::
:: Pfad zu 7-Zip (bitte ohne Anfuehrungszeichen)
set "programmpfad=C:\Program Files\7-Zip\7z.exe"

:: Quellpfad (Ordner, der gesichert werden soll)
set "quelle=D:\Backup\Datenquelle"

:: Zielpfad fuer Sicherungen
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

:: Aufbewahrungszeit der Tagessicherungen in Tagen
set aufbewahrungszeit=31

:: Monatssicherungen loeschen, wenn aelter als 365 Tage
set monataelteralseinjahrloeschen=1
set minAlter=365


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::                                       AB HIER NICHTS MEHR AENDERN!!!!                                          ::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::



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

:: Datum/Zeit via WMIC (lokalitaetsunabhaengig)
for /f %%i in ('wmic os get localdatetime ^| find "."') do set datetime=%%i
set year=%datetime:~0,4%
set month=%datetime:~4,2%
set day=%datetime:~6,2%
set stunden=%datetime:~8,2%
set minuten=%datetime:~10,2%
set sekunden=%datetime:~12,2%


rem ------------------- TAGES-SICHERUNG -------------------

set "zipname=%year%-%month%-%day%-%stunden%-%minuten%-%sekunden%-TC-Tages-Sicherung.zip"
"%programmpfad%" a "%ziel%\%zipname%" "%quelle%\"


:: ------------------- MONATSSICHERUNG -------------------

if not "%monatssicherung%"==0 (
   echo Monatssicherung wird erstellt.
   rmdir /s /q "%ziel%\%year%-%month%"
   if not exist "%ziel%\%year%-%month%" md "%ziel%\%year%-%month%"
   "%programmpfad%" a "%ziel%\%year%-%month%\%year%-%month%-TC-Monats-Sicherung.zip" %quelle%
)


:: ------------------- JAHRESSICHERUNG -------------------

if not "%jahressicherung%"==0 (
   echo Jahressicherung wird erstellt.
   rmdir /s /q "%ziel%\%year%-Jahressicherung"
   if not exist "%ziel%\%year%-Jahressicherung" md "%ziel%\%year%-%month%"
   "%programmpfad%" a "%ziel%\%year%-Jahressicherung\%year%-TC-Jahres-Sicherung.zip" %quelle%
)


:: ------------------- TESTSYSTEM-KOPIE -------------------

if not "%testsystem%"==0 (
    echo Testsystem wird aktualisiert...
    if not exist "%testsystempfad%" mkdir "%testsystempfad%"
    xcopy "%quelle%\*" "%testsystempfad%\" /s /y /c
)

:: ------------------- GIT-KOPIE -------------------

if not "%git%"==0 (
    echo Kopiere Datei nach GIT...
    if not exist "%gitpfad%" mkdir "%gitpfad%"
    xcopy "%quelle%\%gitdatei%" "%gitpfad%\" /s /y /c
)

:: ------------------- TAGESSICHERUNGEN NACH... TAGEN LOESCHEN (KONFIG) -------------------

if not "%aufbewahrungszeit%"==0 (
    echo Tagessicherungen, aelter als %aufbewahrungszeit% Tage, werden geloescht...
    forfiles /p "%ziel%" /m *.zip /d -%aufbewahrungszeit% /c "cmd /c del @path" 2>nul  
)



:: ------------------- MONATSSICHERUNGEN ALT LOESCHEN -------------------

:: Dieser Teil ist noch nicht funktional!!!

exit /b

:: Alte ORDNER (Monatssicherung), die aelter als %minAlter% Tage sind, loeschen (ausser "Jahressicherung")

if not %monataelteralseinjahrloeschen%==0 (
    echo Monatssicherungen aelter als ein Jahr werden geloescht! 
    :: Loeschbefehl
    for /D %%i in ("%ziel%\*") do (
        set "Ordner=%%~fi"
        set "OrdnerName=%%~nxi"
        call :GetFolderAge "!Ordner!" alter
        if !alter! gtr %minAlter% (
            echo Ueberpruefe Ordner: !OrdnerName!
            echo !OrdnerName! | find /i "Jahressicherung" > nul
            if errorlevel 1 (
                echo Loesche Ordner: !Ordner!
                rmdir /s /q "!Ordner!"
            ) else (
                echo Ueerspringe Jahressicherung: !Ordner!
            )
        )
    )
    goto :eof
)

:GetFolderAge
setlocal
set "Ordner=%~1"
set "alter=%~2"

rem Ermittelt das Alter des Ordners in Tagen
for /f %%a in ('robocopy "%Ordner%" null /l /nocopy /is /njh /njs /ndl /nc /ns /np ^| find "Zusammenfassung" ^| find /v "Dateien"') do (
    for /f %%b in ("%%a") do set "Alter=%%b"
)

endlocal & set "%alter%=%Alter%"



echo Sicherung abgeschlossen.
pause
exit /b
