# import os


# discard execShellCmd("start /B ping localhost -n 10")

# echo "Look i am beyond"

import os, osproc, winim, strutils

proc compareStringThing(normal_string:string, fucked_up_string: array[0..259, WCHAR]): bool =
    # for checkProcessExists
    var
        indexer = 0
        proper_string:string = ""

    while fucked_up_string[indexer] != WCHAR(0):
        proper_string &= char(fucked_up_string[indexer])
        inc(indexer)
    
    echo "normal: [",normal_string,"]"
    echo "proper: [",proper_string,"]"

    return (normal_string == proper_string)


proc getProcessIdByName(processName: string): DWORD =
    const bufferSize = 1024
    var processIds: array[bufferSize, DWORD]
    var bytesReturned: DWORD
    var processCount: DWORD

    # Get the list of all process IDs
    if not (EnumProcesses(addr processIds[0], sizeof(DWORD) * bufferSize, addr bytesReturned) != 0):
        echo "memory: EnumProcesses failed"
        raiseOSError(cast[OSErrorCode](1),"EnumProcesses failed")

    # Calculate the number of processes in the list
    processCount = bytesReturned div sizeof(DWORD)
    echo "memory: process count [" & intToStr(processCount) & "]"
    
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
            echo "memory: could not open process "
            CloseHandle(hProcess)
            hProcess = 0

    echo "memory: no process with that name found"
    CloseHandle(hProcess)
    return 0



echo "Hey: ", getProcessIdByName("notepad.exe")