import winim

proc launchProcess(command: string): bool =
  var
    si: STARTUPINFO
    pi: PROCESS_INFORMATION
  let cmd: string = command

  ZeroMemory(addr si, sizeof(si))
  si.cb = sizeof(si)
  ZeroMemory(addr pi, sizeof(pi))

  if CreateProcess(nil, cmd, nil, nil, false, CREATE_NO_WINDOW, nil, nil, addr si, addr pi):
  #if CreateProcess(nil, cmd, nil, nil, false, CREATE_NO_WINDOW, nil, nil, addr si, addr pi):
    CloseHandle(pi.hThread)
    CloseHandle(pi.hProcess)
    result = true
  else:
    result = false

discard launchProcess("notepad.exe")