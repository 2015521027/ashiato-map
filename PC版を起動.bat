@echo off
rem 足跡マップをPCのブラウザで起動する(終了するにはこの黒い窓を閉じる)
cd /d "%~dp0"
echo 起動準備中... 1分ほどでブラウザが開きます。この窓は閉じないでください。
start "" http://localhost:8787
call C:\Users\w5521\dev\tools\flutter\bin\flutter.bat run -d web-server --web-port=8787 --release
pause
