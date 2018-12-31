@echo off
rem v1: Retrieves EV logs, OS Version and IIS logs *if located in default path
rem ScriptVersion=1
rem TODO: - machine config, - version txt, - application host, - host 127.0.0.1, - server.hsconf

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
echo Retrieving System Information
for /f "tokens=1-7 delims=[.] " %%a in ('ver') do (set wv=%%a %%b %%c %%d.%%e.%%f.%%g)
@echo OS Version: %wv% > %DesktopPath%\OutSystems_data_%timestamp%\SystemInformation.txt

rem Retrieving IIS version
for /f "tokens=1-4 delims= " %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\InetStp" /s') do ( if %%a==VersionString set IISVersion= IIS %%c %%d)
@echo IIS Version: %IISVersion% >> %DesktopPath%\OutSystems_data_%timestamp%\SystemInformation.txt

rem Retrieving SSL Protocols
reg export "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel\Protocols" %DesktopPath%\OutSystems_data_%timestamp%\SSLProtocols.txt

rem Retrieving .NET Framework information
reg export "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP" %DesktopPath%\OutSystems_data_%timestamp%\NETFramework.txt

rem Retrieving OS information
for /f "tokens=2-10 delims= " %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName') do (set WindowsServer= %%c %%d %%e %%f %%g %%h %%i)
@echo Windows Server Version: %WindowsServer% >> %DesktopPath%\OutSystems_data_%timestamp%\SystemInformation.txt


rem Retrieve IIS Logs
echo Retrieving IIS logs
for /f "delims=:" %%N in ('findstr /i /N "<"siteDefaults">" "C:\Windows\System32\inetsrv\config\applicationHost.config"') do set line=%%N
rem Retrieve line of Logs Path in config file
for /f "tokens=1 skip=%line% delims=/>" %%a in (C:\Windows\System32\inetsrv\config\applicationHost.config) do ( set StringVar=%%a & GOTO done)
:done
rem Trim spaces
for /f "tokens=* delims= " %%a in ("%StringVar%") do set StringVar=%%a
rem Remove special characters
for /f "tokens=* delims=<" %%a in ("%StringVar%") do set StringVar=%%a

rem retrieve Path
for /f "tokens=1-3 delims==" %%a in ("%StringVar%") do ( set LogsPath=%%c)
set LogsPath=%LogsPath:"=%
rem Checking if it contains the string SystemDrive, which is an environment variable. If it does contains, it's necessary to set the LogsPath again with that variable name, otherwise, it is passed as string
if not x%LogsPath:SystemDrive=%==x%LogsPath% (
	for /f "tokens=1-3 delims=%%" %%a in ("%LogsPath%") do ( set LogsPath=%SystemDrive%%%b)
)

xcopy /s %LogsPath% %DesktopPath%\OutSystems_data_%timestamp%