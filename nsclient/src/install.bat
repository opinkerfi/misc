@echo on

net stop NSClientpp 

xcopy "%ProgramFiles%\NSclient++\*.ini" "%ProgramFiles%\NSclient++\backup\"  /i /h /y 

xcopy %0\..\%PROCESSOR_ARCHITECTURE%\*.*  "%ProgramFiles%\NSclient++\" /e /i /h /y
xcopy "%0\..\tmp\nscp-%PROCESSOR_ARCHITECTURE%.msi"  "%TEMP%\" /e /i /h /y
msiexec /quiet /i "%TEMP%\nscp-%PROCESSOR_ARCHITECTURE%.msi" CONF_NRPE=1
xcopy %0\..\datafiles\*.*  "%ProgramFiles%\NSclient++\" /e /i /h /y


"%ProgramFiles%\NSclient++\nscp.exe" service --uninstall
"%ProgramFiles%\NSclient++\nscp.exe" service --install
"%ProgramFiles%\NSclient++\nscp.exe" service --start

