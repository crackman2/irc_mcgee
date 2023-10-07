import osproc


discard startProcess("cmd.exe",args = ["/C start/B ping localhost -n 10"])

echo "Look i am beyond"