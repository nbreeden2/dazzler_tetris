@echo off
REM ---------------------------------------------------------------
REM BUILD.BAT - Build SEDIT for CPM
REM
REM Requires: cpmulator.exe, M80.COM, L80.COM in current directory
REM           Python (for CPMFMT.PY)
REM ---------------------------------------------------------------

echo === SEDIT Build ===

REM Format source files for CP/M
echo Formatting source files...
python CPMFMT.PY d64x64.MAC d64x64a.MAC d64x64b.MAC t64x64.MAC 
if errorlevel 1 goto fail
python CPMFMT.PY tetdata.MAC tetdraw.PY tetmove.MAC tetris.MAC
if errorlevel 1 goto fail

REM Assemble each module
echo Assembling d64x64...
cpmulator M80.COM =d64x64
if errorlevel 1 goto fail
pause

REM Assemble each module
echo Assembling d64x64a...
cpmulator M80.COM =d64x64a
if errorlevel 1 goto fail
pause

REM Assemble each module
echo Assembling d64x64b...
cpmulator M80.COM =d64x64b
if errorlevel 1 goto fail
pause

REM Assemble each module
echo Assembling tetdata...
cpmulator M80.COM =tetdata
if errorlevel 1 goto fail
pause

REM Assemble each module
echo Assembling tetdraw...
cpmulator M80.COM =tetdraw
if errorlevel 1 goto fail
pause

REM Assemble each module
echo Assembling tetmove...
cpmulator M80.COM =tetmove
if errorlevel 1 goto fail
pause

REM Assemble each module
echo Assembling tetris...
cpmulator M80.COM =tetris
if errorlevel 1 goto fail
pause


cls
dir *.mac
dir *.rel
pause

REM Link all modules
echo Linking...

cpmulator L80.COM TETRIS,TETMOVE,TETDRAW,TETDATA,D64X64,D64X64A,D64X64B,TETRIS/N/E
if errorlevel 1 goto fail

dir tetris.com
pause

REM Clean up .REL files
del *.REL 2>nul

REM Copy to SDH folders and build SDH disk image
cls
copy /Y tetris.COM D:\SDH\DISKS\RTRTET.unpacked\0
copy /Y *.mac      D:\SDH\DISKS\RTRTET.unpacked\0
pushd D:\SDH\DISKS
if exist RTRTET.dsk del RTRTET.dsk
python ..\pack.py RTRTET.dsk
if not exist RTRTET.dsk goto fail
copy RTRTET.dsk D:\VisualStudio\Tetris
popd

echo === Build successful: RTRTET.COM ===
goto end

:fail
echo === BUILD FAILED ===
exit /b 1

:end
