@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\win\60-smoke.ps1" -Quick %*
