@echo off

REM ------------------------------------------------------------------
REM Spell checking of the source file (Bash version for Windows)
REM Usage: aspell-check.bat
REM ------------------------------------------------------------------

REM Check if Aspell exists, otherwise print instructions and exits
for %%X in (aspell.exe) do (set FOUND=%%~$PATH:X)
if defined FOUND goto :error

REM Run Aspell
aspell --home-dir=. --lang=en --mode=tex --add-tex-command="nospellcheck p" check Source/paper.tex
goto :end

REM Print instructions
:error
type aspell-check.readme

:end

