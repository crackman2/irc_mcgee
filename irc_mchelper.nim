import os, osproc, winim


proc getProcessIdByName(processName: string): DWORD =
    const bufferSize = 1024
    var processIds: array[bufferSize, DWORD]
    var bytesReturned: DWORD
    var processCount: DWORD

    # Get the list of all process IDs
    if not (EnumProcesses(addr processIds[0], sizeof(DWORD) * bufferSize, addr bytesReturned) != 0):
        #echo "memory: EnumProcesses failed"
        raiseOSError(cast[OSErrorCode](1),"EnumProcesses failed")

    # Calculate the number of processes in the list
    processCount = bytesReturned div sizeof(DWORD)
    #echo "memory: process count [" & intToStr(processCount) & "]"
    
    # Iterate through the list and find the process with the given name

    
    var hProcess:HANDLE = 0
    for i in 0 ..< processCount:
        var buffer: array[bufferSize, char]
        hProcess = OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, false, processIds[i])
        if hProcess != 0:
            if GetModuleFileNameEx(hProcess, 0, cast[LPTSTR](addr buffer[0]), sizeof(buffer)) != 0:
                var
                    exeName:string = ""
                    tmp_exeName:string = "" 
                    j = 0 
                while buffer[j] != char(0):
                    tmp_exeName = tmp_exeName & char(buffer[j])
                    inc(j)
                    inc(j)

                var (_,name,ext) = splitFile(tmp_exeName)
                exeName = name & ext


                # Check if the executable file name matches the desired process name
                if exeName == processName:
                    echo "memory: process found! [" & exeName & "]"
                    CloseHandle(hProcess)
                    hProcess = 0
                    return processIds[i]
        else:                
            #echo "memory: could not open process "
            CloseHandle(hProcess)
            hProcess = 0

    echo "memory: no process with that name found"
    CloseHandle(hProcess)
    return 0




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






var
    appfilename = paramStr(1)
    tmpdir = getTempDir() & "irc_mcgee\\"
    tmpexe_firsthalf = tmpdir & "irc_mcupdated"
    a_very_random_number = paramStr(2)
    tmpexe = tmpexe_firsthalf & a_very_random_number & ".exe"
    (_, name, ext) = splitFile(appfilename)
    appfile_processname = name & ext



if fileExists(tmpexe):
    echo "HELPER: Waiting for parent to close"

    while getProcessIdByName(appfile_processname) != 0:
        sleep(1000)


    echo "HELPER: Path: ", appfilename

    echo "HELPER: Removing file: [", appfilename, "]"
    try:
        removeFile(appfilename)
    except:
        echo "HELPER: File not found"
        quit(0)

    echo "HELPER: Copying [",tmpexe,"] to [" & appfilename & "]"
    copyFile(tmpexe, appfilename)
    echo "HELPER: Executing new version!"
    #discard startProcess(appfilename)
    discard launchProcess(appfilename)