@echo off
rem v1: Retrieves EV logs, OS Version and IIS logs *if located in default path
rem ScriptVersion=1

rem Setting Path for Desktop
set DesktopPath=%USERPROFILE%\Desktop

rem Getting the date timestamp. Format may vary due to machine configuration
For /f "tokens= 1-4 delims=/ " %%a in ("%DATE%") do (set mydate=%%a%%b%%c%%d)
For /f "tokens= 1-3 delims=/:. " %%a in ("%TIME%") do (set mytime=%%a%%b%%c)
set timestamp=%mydate%_%mytime%

rem Check if folder already exists before creating it
if not exist %DesktopPath%\OutSystems_data_%timestamp% (
	mkdir %DesktopPath%\OutSystems_data_%timestamp%
) else (
	echo Unable to create path because directory %DesktopPath%\OutSystems_data_%timestamp% already exists
	Exit /b
)

rem Export Event Viewer logs: Application, System and Security
echo Exporting Event Viewer logs
WEVTUtil export-log Application %DesktopPath%\OutSystems_data_%timestamp%\Application.evtx
WEVTUtil export-log System %DesktopPath%\OutSystems_data_%timestamp%\System.evtx
rem Note: Must run batch as Administrator, otherwise, you'll get permissions denied 
WEVTUtil export-log Security %DesktopPath%\OutSystems_data_%timestamp%\Security.evtx

rem Retrieving Windows version. For full list of releases, check https://en.wikipedia.org/wiki/List_of_Microsoft_Windows_versions
for /f "tokens=1-7 delims=[.] " %%a in ('ver') do (set wv=%%a %%b %%c %%d.%%e.%%f.%%g)
@echo OS Version: %wv% > %DesktopPath%\OutSystems_data_%timestamp%\SystemInformation.txt

rem Retrieve IIS Logs
echo Retrieving IIS logs
set LogsPath=%SystemDrive%\inetpub\logs\LogFiles
xcopy /s %LogsPath% %DesktopPath%\OutSystems_data_%timestamp%