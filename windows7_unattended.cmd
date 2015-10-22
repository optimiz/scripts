@echo off
cls
regedit /s \\svr06\public\w7x64\w7_samba.reg
start secpol.msc
rem change next line to valid product key before deployment...
slmgr -ipk XXXXX-XXXXX-XXXXX-XXXXX-XXXXX
slmgr -ato
rem start /wait gpedit.msc
rem copy /y \\svr06\public\w7x64\machine.pol %windir%\system32\grouppolicy\machine\registry.pol
rem copy /y \\svr06\public\w7x64\user.pol %windir%\system32\grouppolicy\user\registry.pol
rem delete %windir%\system32\grouppolicy\gpt.ini
rem gpupdate /force
msiexec /quiet /i \\svr06\public\w7x64\delprof.msi
rem msiexec /quiet /i \\svr06\public\wpkg\software\flash10.msi
msiexec /quiet /i \\svr06\public\wpkg\software\install_flash_player_11_plugin_64bit.msi
\\svr06\public\wpkg\software\quicktimealt175lite.exe /verysilent /noreboot /noicons
\\svr06\public\wpkg\software\realalt150lite.exe /verysilent /noreboot /noicons
\\svr06\public\wpkg\software\cccp-2009-09-09.exe /verysilent /noreboot /noicons
\\svr06\public\wpkg\software\Adobe9.exe /sAll /rs
rem \\svr06\public\w7x64\java6u18x64.exe /s IEXPLORER=1 MOZILLA=1 ADDLOCAL=ALL REBOOT=Suppress JAVAUPDATE=0 JU=0 AUTOUPDATECHECK=0
\\svr06\public\w7x64\msse_w7x64.exe
\\svr06\public\installs\office12\setup.exe /config \\svr06\public\w7x64\config.xml
winsat formal -restart clean
shutdown /r /t 0
rem exit
