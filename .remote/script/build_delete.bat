@echo off
for /f "delims=" %%i in ('dir /s/b/ad 123*') do (
rd /s/q "%%~i"
)