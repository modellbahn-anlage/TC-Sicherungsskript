@echo off
setlocal enabledelayedexpansion


:: Wenn Sie das Skript verwenden, koennen Sie uns ueber https://spenden.modellbahn-anlage.de gerne eine Kleinigkeit zukommen lassen, dann wird das Skript auch weiterentwickelt :)

:: Dieses Skript erstellt einen Ordner oder Datei mit dem Datum der Sicherung
::
:: Skript Version 2.0
:: Ersteller: Martin Fitzel - http://www.modellbahn-anlage.de
::
:: CHANGELOG
:: 2017-12-15: Erste Version 1.0
:: 2019-02-12: Verbesserte Version 1.3
:: 2019-02-14: Konzept Monatssicherung angedacht, automatisches Loeschen hinzugefuegt
:: 2019-02-18: Monatssicherung + Jahressicherung realisiert
:: 2019-02-19: Finalisiert als Version 1.5
:: 2019-02-21: Fehler Variable 7-Zip behoben.  Version 1.5.1
::			   Schluss "\" in den Variablen entfernt - führte zu keinen Fehlern, muss autom. in Zukunft überprüft werden...
:: 2019-02-22: Einbau einer Funktion, um Daten zum Testsystem zu kopieren - Version 1.6
:: 2020-08-29: Variable eingebaut, die später darüber entscheidet, ob nach der Jahressicherung die Monatssicherungen geloescht werden sollen.
:: 2023-04-13: Datei nach GIT überführt
:: 2023-04-14: Loeschen von alten DATEIEN (nicht Ordnern!) optimiert (Doku angepasst)
:: Version 2.0
:: 2024-01-03: Loeschen hinzugefügt - bitte dabei den Text bei der Einstellung DRINGEND dazu beachten!
:: 2024-01-06: Vergessene Codezeilen durch GIT wieder eingefügt :) 
:: 2025-08-11: Schreibfehler behoben, GIT Repository angelegt
:: 2025-10-21: Schreibfehler behoben


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::                                                NUR HIER AENDERN!!!!                                            ::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Pfad zu 7-Zip (https://7-zip.de/) auf dem eigenen Computer
set programmpfad="c:\Program Files\7-Zip\7z.exe"

:: Quellpfad - von hier die Daten holen und in das ZIP packen. Es wird der ganze Ordner gepackt inkl. Unterordner (ohne \ am Ende)
set quelle=""
::set quelle="d:\Datenquelle"

:: Zielpfad - hier werden die Daten abgelegt und Ordner erstellt Ordner wird erstellt, wenn nicht vorhanden (ohne \ am Ende)!
set ziel=""

:: Kopie zum Testsystem - hat man einen 2. Ordner mit den Dateien zum Testen, dann kopiert das Skript den letzten Stand ohne es zu zippen in einen anderen Ordner. Testsystem=1, dann aktiviert, 0=nein, deaktiviert (ohne \ am Ende)
set testsystem=0
set testsystempfad="" 

:: Kopie der Datei nach GIT lokal
set git=0
::Hier den Dateiname, z.B. "ABC.yrrg"
set gitdatei=""
::Pfad zum GIT-Ordner
set gitpfad=""

:: Erstellung einer Monatssicherung? ja=1  nein=0
set monatssicherung=1

:: Erstellung einer Jahressicherung? ja=1  nein=0
set jahressicherung=1

:: TAGESSICHERUNG: Aufbewahrungszeit der TAGESSICHERUNGEN in Tagen, Dateien (NICHT ORDNER!!!) über dem Zeitraum werden geloescht (nicht Monats- oder Jahressicherungen)! 0=keine Loeschung, Funktion deaktiviert.
:: Sinn macht bei eingeschalteter Monats-Sicherung 31 Tage, danach bleibt die letzte Sicherung des Monats im Monatssicherungs-Ordner. 
set aufbewahrungszeit=31

:: LOESCHEN VON MONATSSICHERUNGEN
:: Diese Funktion loescht die Ordner und Inhalte der Monatssicherungen, die CTER ALS 1 JAHR SIND! Monatssicherungen darunter werden nicht gelöscht! Wenn man überhaupt keine Löschung möchte, l?t man diesen Wert auf 0 stehen!
:: Jahressicherungen werden NICHT (!) geloescht, ausser man aendert deren Dateiname! 
set "minAlter=365"
set monataelteralseinjahrloeschen=1


:: FTP-Server Einstellungen (noch nicht umgesetzt - kommt noch...)



::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::                                       AB HIER NICHTS MEHR AENDERN!!!!                                          ::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Prueft, ob Quelle vorhanden
if not exist "%quelle%" (
   echo Das Skript wird abgebrochen, den Pfad %quelle% gibt es nicht!
   Pause
   EXIT
)


if "%quelle%"=="" (
    echo Fehler: Der Quellpfad ist nicht gesetzt!
    pause
    exit /b
)
if "%ziel%"=="" (
    echo Fehler: Der Zielpfad ist nicht gesetzt!
    pause
    exit /b
)

:: Datum ermitteln und in Variablen schreiben
set stunden=%time:~-11,2%
set minuten=%time:~-8,2%
set sekunden=%time:~-5,2%
set day=%date:~0,2%
set month=%date:~3,2%
set year=%date:~6%

:: Zielpfad - hier die Daten ablegen und Ordner erstellen
if not exist "%ziel%"\ md "%ziel%"\

:: Ordner nehmen und per ZIP (7Zip) packen - inkl. Pfad zur EXE Datei
%programmpfad% a %ziel%\"%year%-%month%-%day%-%stunden%-%minuten%-%sekunden%-TC-Tages-Sicherung.zip" %quelle%

::::::::::::::::::::::::::::
:: Alte ZIP-Files (Sicherungen) nach ... Tagen loeschen
if not %aufbewahrungszeit%==0 (
   echo Sicherungen, aelter als %aufbewahrungszeit% Tage, werden geloescht! 
   :: Loeschbefehl
   forfiles /p %ziel% /m *.* /d -%aufbewahrungszeit% /c "cmd /c del @path"
)

::::::::::::::::::::::::::::
:: Alte ORDNER (Monatssicherung, aelter als ein Jahr) loeschen. Wenn dies gewaehlt ist, wird alles, ausser dem Jahresarchiv, geloescht.
if not %monataelteralseinjahrloeschen%==0 (
    echo Monatssicherungen ?er als ein Jahr werden geloescht! 
    :: Loeschbefehl
    for /D %%i in ("%ziel%\*") do (
        set "Ordner=%%~fi"
        set "OrdnerName=%%~nxi"
        call :GetFolderAge "!Ordner!" alter
        if !alter! gtr %minAlter% (
            echo ?erprüfe Ordner: !OrdnerName!
            echo !OrdnerName! | find /i "Jahressicherung" > nul
            if errorlevel 1 (
                echo Loesche Ordner: !Ordner!
                rmdir /s /q "!Ordner!"
            ) else (
                echo Ueberspringe Jahressicherung: !Ordner!
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

::::::::::::::::::::::::::::
:: Monatssicherung

if not %monatssicherung%==0 (
   echo Monatssicherung wird erstellt.
   rmdir /s /q "%ziel%\%year%-%month%"
   if not exist "%ziel%\%year%-%month%" md "%ziel%\%year%-%month%"
   %programmpfad% a "%ziel%\%year%-%month%\%year%-%month%-TC-Monats-Sicherung.zip" %quelle%
)

::::::::::::::::::::::::::::
:: Jahressicherung

if not %jahressicherung%==0 (
   echo Jahressicherung wird erstellt.
   rmdir /s /q "%ziel%\%year%-Jahressicherung"
   if not exist "%ziel%\%year%-Jahressicherung" md "%ziel%\%year%-%month%"
   %programmpfad% a "%ziel%\%year%-Jahressicherung\%year%-TC-Jahres-Sicherung.zip" %quelle%
)

::::::::::::::::::::::::::::
:: Testsystem
if not %testsystem%==0 (
   echo Dateien werden zum Testsystem kopiert.
   if not exist "%testsystempfad%"\ md "%testsystempfad%"\
   xcopy %quelle%\*.* %testsystempfad%\ /s /y /c
)


::::::::::::::::::::::::::::
:: GIT
if not %git%==0 (
   echo Dateien werden zum GIT-System kopiert.
   if not exist "%gitpfad%"\ md "%gitpfad%"\
   xcopy %quelle%\%gitdatei% %gitpfad%\ /s /y /c
)

::ENDE SKRIPT