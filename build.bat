@echo off
REM ---------------------------------------------------------------
REM BUILD.BAT - Build Tetris for Cromemco Dazzler
REM
REM Requires: cpmulator.exe, M80.COM, L80.COM in current directory
REM           Python (for CPMFMT.PY)
REM ---------------------------------------------------------------

echo === Tetris Build ===

REM Format source files for CP/M
echo Formatting source files...
python CPMFMT.PY tetris.mac tetmove.mac tetdraw.mac tetdata.mac d64x64.mac d64x64a.mac d64x64b.mac
if errorlevel 1 goto fail

REM Assemble each module
echo Assembling TETRIS...
cpmulator M80.COM =TETRIS
if errorlevel 1 goto fail

echo Assembling TETMOVE...
cpmulator M80.COM =TETMOVE
if errorlevel 1 goto fail

echo Assembling TETDRAW...
cpmulator M80.COM =TETDRAW
if errorlevel 1 goto fail

echo Assembling TETDATA...
cpmulator M80.COM =TETDATA
if errorlevel 1 goto fail

echo Assembling D64X64...
cpmulator M80.COM =D64X64
if errorlevel 1 goto fail

echo Assembling D64X64A...
cpmulator M80.COM =D64X64A
if errorlevel 1 goto fail

echo Assembling D64X64B...
cpmulator M80.COM =D64X64B
if errorlevel 1 goto fail

REM Link all modules
echo Linking...
cpmulator L80.COM TETRIS,TETMOVE,TETDRAW,TETDATA,D64X64,D64X64A,D64X64B,TETRIS/N/E
if errorlevel 1 goto fail

REM Clean up .REL files
del *.REL 2>nul

REM Copy to SDH folders and build SDH disk image
cls
copy /Y *.MAC      D:\SDH\DISKS\RTRTET.unpacked\0
copy /Y tetris.com D:\SDH\DISKS\RTRTET.unpacked\0
pushd D:\SDH\DISKS
if exist RTRTET.dsk del RTRTET.dsk
python ..\pack.py RTRTET.dsk
if not exist RTRTET.dsk goto fail
popd

echo === Build successful: TETRIS.COM ===
goto end

:fail
echo === BUILD FAILED ===
exit /b 1

:end
