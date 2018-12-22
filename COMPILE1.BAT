@echo ON
@echo COMPILATION TEST for TASM and MASM, and DLL build
@echo switches: -a = disasm, -b = base64, -d = dll, -h = binhex
@echo note: switches -a needs watcom's obj2asm (www.watcom.org)
@echo.

@setLocal enableExtensions enableDelayedExpansion
@echo set basename, we'll just create symlinks to mdx5a.asm
set "BASENAME=mdx5a"	.asm source
for %%X in (t m) do mklink %BASENAME%_%%Xasm.asm mdx5a.asm

@echo.
@echo Set these ENVARS to the actual path of tasm/masm
set "TASM=tasm32"
set "MASM=ml"

@echo.
@echo Cleanup switches
@set "SWITCHES=a b d h"
@for %%s in (%SWITCHES%) do set "op_%%s="

:Loop
@set "arg=%~1"
@if not defined arg goto LoopDeone
@for %%s in (%SWITCHES%) do @if /i "%~1"=="-%%s" set "op_%%s=1"
@for %%s in (%SWITCHES%) do @if /i "%~1"=="/%%s" set "op_%%s=1"
@shift & goto Loop
:LoopDeone

if defined op_d ( set "DDLL=/Ddll" ) else set "DDLL="
if defined op_h ( set "DBINHEX=/Dbinhex" ) else set "DBINHEX="
if defined op_b ( set "DBASE64E=/Dbase64e" ) else set "DBASE64E="

:BEGIN
call "%TASM%" /t /la /c /mx /m8 /Dtasm=1 %DBASE64E% %DBINHEX% %DDLL% %BASENAME%_tasm.asm
call "%MASM%" /nologo /Fl /c    /Dmasm=1 %DBASE64E% %DBINHEX% %DDLL% %BASENAME%_masm.asm

@if not defined DDLL goto CheckA
set "DEFILE=%BASENAME%_masm.def"
@echo.
@echo.Create DLL's definition file
echo.LIBRARY %BASENAME%> %DEFILE%
>> %DEFILE% echo.EXPORTS mdx5init @1
>> %DEFILE% echo.EXPORTS mdx5fetch @2
>> %DEFILE% echo.EXPORTS mdx5finalize @3
>> %DEFILE% echo.EXPORTS mdx5calc @4
if defined op_h ( echo.EXPORTS bin2hex @5>>%DEFILE% )
if defined op_b ( echo.EXPORTS base64encode @6>>%DEFILE% )

link /subsystem:windows /dll /def:%DEFILE% %BASENAME%_masm.obj

:checkA
@if not defined op_a goto chkout
call obj2asm -o %BASENAME%_tasm.obj > dis-%BASENAME%_tasm_obj
call obj2asm -o %BASENAME%_masm.obj > dis-%BASENAME%_masm_obj

@set "tab=	"
call sed -i"" -e "/\([ %tab%,]\)\([0-9A-Fh]\+\)\[\(...\)\]/s//\1[\3+\2]/" -e "/\([ %tab%,]\)-\([0-9A-Fh]\+\)\[\(...\)\]/s//\1[\3\2]/" dis-%BASENAME%_?asm_obj

@REM clear errorlevel
@call set "blah="

:chkout
::pause if we're not in console
@for %%v in (%cmdcmdline%) do @set "arg=%%~v"
@if not %arg%==%comSpec% @echo.&@pause 
