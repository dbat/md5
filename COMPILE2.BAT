@echo ON
@echo. COMPILE MD5x with TINY-C
@echo. REQUIRES:
@echo.   tcc.exe (https://bellard.org/tcc/)
@echo.   objconv.exe (https://github.com/gitGNU/objconv)
@setLocal enableDelayedExpansion

@echo.
@echo Set these ENVARS according to your workspace
set "ASM=MDX5A"	.asm source
set "SRC=md5"	.c source

@set "DBASE64E=/Dbase64e"
@set "DBINHEX=/Dbinhex"

@for %%s in ("%ASM%.asm" "%SRC%.c") do if not exist "%%~s" echo.ERROR "%%~s" is not found & goto done

@echo.
@echo COMPILING..
call tasm32 /q /c /la /mx /m8 /Dtasm=1 %DBASE64E% %DBINHEX% %ASM%.asm
@if not %errorlevel%==0 echo ERROR assembing & goto done

call objconv -felf32 -nu %ASM%.obj %ASM%.o
@if not %errorlevel%==0 echo ERROR converting OBJ to ELF & goto done

call tcc -Dtcc=1 -o %SRC%.exe %SRC%.c %ASM%.o
@if %errorlevel%==0 (
	@for %%f in (%SRC%.exe) do @echo.- tcc compilation OK: %%~znxf
)

:done
:: pause if not in console
@for %%v in (%cmdcmdline%) do @set blah=%%~v
@if /i not %blah%==%comspec% @echo. & @pause

