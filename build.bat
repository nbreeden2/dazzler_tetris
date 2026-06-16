@echo off
setlocal
REM ---------------------------------------------------------------
REM BUILD.BAT - Headless build of TETRIS v2.0 via CPMEMUTK.
REM Stages source onto tk\src.unpacked\0\ (drive B:), runs the build
REM script in emulated CP/M, branches on the exit code, then bundles
REM the .COM into the distribution disk image.
REM Requires: tk\cpmemutk.exe (local-use-only) + Python (CPMFMT.PY).
REM ---------------------------------------------------------------

set "HERE=%~dp0"
set "WORK=%HERE%tk\src.unpacked\0"

echo === TETRIS v2.0 Build ===

REM Format source files for CP/M (CRLF + Ctrl-Z)
echo [build] formatting source files
python CPMFMT.PY d64x64.MAC d64x64a.MAC d64x64b.MAC t64x64.MAC tetdata.MAC tetdraw.MAC tetmove.MAC tetris.MAC
if errorlevel 1 goto fail
python CPMFMT.PY README.TXT LICENSE.TXT
if errorlevel 1 goto fail

REM Stage source onto the work disk (drive B:)
echo [build] staging source onto B:
copy /Y "%HERE%tetris.MAC"  "%WORK%\" >NUL || goto stage_fail
copy /Y "%HERE%tetmove.MAC" "%WORK%\" >NUL || goto stage_fail
copy /Y "%HERE%tetdraw.MAC" "%WORK%\" >NUL || goto stage_fail
copy /Y "%HERE%tetdata.MAC" "%WORK%\" >NUL || goto stage_fail
copy /Y "%HERE%d64x64.MAC"  "%WORK%\" >NUL || goto stage_fail
copy /Y "%HERE%d64x64a.MAC" "%WORK%\" >NUL || goto stage_fail
copy /Y "%HERE%d64x64b.MAC" "%WORK%\" >NUL || goto stage_fail

REM Assemble + link inside emulated CP/M
echo [build] running cpmemutk
"%HERE%tk\cpmemutk.exe" --script "%HERE%tk\build.tks" --log "%HERE%tk\build.log" --report "%HERE%tk\build.xml"
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
    echo === BUILD FAILED ^(exit %RC%^) - see tk\build.log ===
    exit /b %RC%
)

REM Extract the .COM back to the project root
echo [build] extracting TETRIS.COM
copy /Y "%WORK%\TETRIS.COM" "%HERE%TETRIS.COM" >NUL || goto out_fail

REM Copy to distribution folders
echo [build] copying to distribution folders
copy /Y "%HERE%TETRIS.COM"  D:\CPMEMU\disks\RTRTET.unpacked\0 >NUL
copy /Y "%HERE%TETRIS.MAC"  D:\CPMEMU\disks\RTRTET.unpacked\0 >NUL
copy /Y "%HERE%README.TXT"  D:\CPMEMU\disks\RTRTET.unpacked\0 >NUL
copy /Y "%HERE%LICENSE.TXT" D:\CPMEMU\disks\RTRTET.unpacked\0 >NUL
copy /Y "%HERE%TETRIS.COM"  D:\CPMEMU\disks\TETRIS.unpacked\0 >NUL
copy /Y "%HERE%README.TXT"  D:\CPMEMU\disks\TETRIS.unpacked\0 >NUL
copy /Y "%HERE%LICENSE.TXT" D:\CPMEMU\disks\TETRIS.unpacked\0 >NUL

REM Pack distribution disk image
echo [build] packing TETRIS.dsk
pushd D:\CPMEMU\disks
if exist TETRIS.dsk del TETRIS.dsk
fdc-pack TETRIS.dsk
if not exist TETRIS.dsk (
    popd
    goto pack_fail
)
copy /Y TETRIS.dsk "%HERE%" >NUL
popd

echo === Build successful: TETRIS.COM + TETRIS.dsk ===
exit /b 0

:fail
echo === BUILD FAILED: CPMFMT step ===
exit /b 1

:stage_fail
echo === BUILD FAILED: could not stage source onto tk\src.unpacked\0\ ===
exit /b 1

:out_fail
echo === BUILD FAILED: could not copy TETRIS.COM out of work disk ===
exit /b 1

:pack_fail
echo === BUILD FAILED: fdc-pack did not produce TETRIS.dsk ===
exit /b 1
