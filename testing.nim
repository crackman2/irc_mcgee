import winim, os

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


var exe_path = "C:\\Windows\\notepad.exe"


echo "Startup: [", getEnv("APPDATA"), "\\Microsoft\\Windows\\Start Menu\\Programs\\Startup","]"



import winim

proc createShortcut(targetPath: string, shortcutPath: string) =
  var shellLink: ptr IShellLink
  var persistFile: ptr IPersistFile
  var hr: HRESULT

  hr = CoInitialize(nil)
  if hr != S_OK and hr != S_FALSE:
    raise newException(OSError, "Failed to initialize COM")

  hr = CoCreateInstance(
    addr CLSID_ShellLink, nil, CLSCTX_INPROC_SERVER, addr IID_IShellLink,
    cast[ptr pointer](addr shellLink)
  )

  if hr != S_OK:
    CoUninitialize()
    raise newException(OSError, "Failed to create shell link")

  shellLink.SetPath(targetPath)

  hr = shellLink.QueryInterface(addr IID_IPersistFile, cast[ptr pointer](addr persistFile))
  if hr != S_OK:
    shellLink.Release()
    CoUninitialize()
    raise newException(OSError, "Failed to get IPersistFile")

  persistFile.Save(shortcutPath, true)
  persistFile.Release()
  shellLink.Release()
  CoUninitialize()

let targetPath = "C:\\Windows\\notepad.exe"
let shortcutPath = getEnv("APPDATA") & "\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\shortcut.lnk"

createShortcut(targetPath, shortcutPath)
