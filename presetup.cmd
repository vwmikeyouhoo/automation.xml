@@ -0,0 +1,65 @@
@ECHO OFF 

set UDA_IPADDR=%1
set UDA_TEMPLATE=%2
set UDA_SUBTEMPLATE=%3

echo UDA_IPADDR=%UDA_IPADDR%
echo UDA_TEMPLATE=%UDA_TEMPLATE%
echo UDA_SUBTEMPLATE=%UDA_SUBTEMPLATE%

echo Subtemplate information can be found in
echo I:\pxelinux.cfg\templates\%UDA_TEMPLATE%\subtemplates.txt

SET UDADIR=%SYSTEMDRIVE%\sources\uda
SET INSTALLDRIVE=I
SET DISKPART=%SYSTEMDRIVE%\windows\system32\diskpart.exe
SET DISKPARTTXT=%UDADIR%\diskpart.txt
SET UNATTEND=%INSTALLDRIVE%:\pxelinux.cfg\templates\%UDA_TEMPLATE%\%UDA_SUBTEMPLATE%.xml
SET REGEXE=%SYSTEMDRIVE%\windows\system32\reg.exe

cd %UDADIR%

echo Preparing the diskpart file

echo select disk 0                                   >%DISKPARTTXT%
echo clean                                           >>%DISKPARTTXT%
echo create partition primary size=100               >>%DISKPARTTXT%
echo select partition 1                              >>%DISKPARTTXT%
echo active                                          >>%DISKPARTTXT%
echo format fs=ntfs LABEL=^"System Reserved^" QUICK OVERRIDE  >>%DISKPARTTXT%
echo create partition primary                        >>%DISKPARTTXT%
echo select partition 2                              >>%DISKPARTTXT%
echo active                                          >>%DISKPARTTXT%
echo assign letter=c                                 >>%DISKPARTTXT%
echo format fs=ntfs LABEL=^"Windows^" QUICK OVERRIDE >>%DISKPARTTXT%
echo select disk 1                                   >>%DISKPARTTXT%
echo clean                                           >>%DISKPARTTXT%
echo create partition primary                        >>%DISKPARTTXT%
echo select partition 2                              >>%DISKPARTTXT%
echo active                                          >>%DISKPARTTXT%
echo assign letter=d                                 >>%DISKPARTTXT%
echo format fs=ntfs LABEL=^"Secondary^" QUICK OVERRIDE >>%DISKPARTTXT%
echo exit    
                                        
echo.
echo Partioning the disk
%DISKPART% /s %DISKPARTTXT%

echo.
mkdir c:\tmp
mkdir c:\tmp2
move x:\sources\uda\*.* c:\tmp

echo.
cscript c:\tmp\postscript.vbs

echo.
echo Removing PXE information from registry to prevent WDS installation
%REGEXE% delete HKLM\SYSTEM\CurrentControlSet\Control\PXE /f



echo.
echo Starting setup with unattend file %UNATTEND%
%SYSTEMDRIVE%\setup.exe /unattend:%UNATTEND%
