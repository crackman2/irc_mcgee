import configparser, os, irc, osproc, base64, helper_base64, winim/inc/wininet, winim, random

let current_version* = "1.0.6.0"

var
    g_tmp_clean* = false
    g_dbg = true


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


proc updt_check*(respond_to_caller:bool = false, iclient:Irc, ievent:IrcEvent):bool =
    var
        #client = newHttpClient()
        clientconnected = true
        ini_raw:string



    if g_dbg: echo "UPDATER: getting info"



    try:
        randomize()

        var
            tmpdir = getTempDir() & "irc_mcgee\\"
            tmpexe_firsthalf = tmpdir & "irc_mcupdated"
            a_very_random_number:string = $(rand(10000..99999))
            tmpexe = tmpexe_firsthalf & a_very_random_number & ".exe"


        try:
            if dirExists(tmpdir):
                removeDir(tmpdir)
        except:
            discard


        
        try:
            ini_raw = updt_fetchWebsiteContent("https://raw.githubusercontent.com/crackman2/irc_mcgee/master/update/update.ini") #client.getContent("https://raw.githubusercontent.com/crackman2/irc_mcgee/master/update/update.ini")
            #client.close()
            clientconnected = false
        except OSError as e:
            if (respond_to_caller):
                iclient.privmsg(ievent.origin, "could not get the content of update.ini [" & repr(e) & "]")
            return
        


        var
            ini = parseIni(ini_raw)
            ini_version = ini.getProperty("Version","Version")
            


        if ini_version == current_version:
            if g_dbg: echo " +-> version is up to date [",ini_version,"]"
            if(respond_to_caller):
                iclient.privmsg(ievent.origin, "up to date (mine)[" & current_version & "] vs (online)[" & ini_version & "]")
            if clientconnected:
                #client.close()
                clientconnected = false
            return true
        elif(respond_to_caller):
            iclient.privmsg(ievent.origin, "attempting to update, cya")
        if g_dbg: echo " +-> update required. [",current_version,"] -> [", ini_version, "]"
    


        try:
            if not dirExists(tmpdir):
                createDir(tmpdir)
        except:
            if g_dbg: echo " +-> failed to create temp dir"
            if(respond_to_caller):
                iclient.privmsg(ievent.origin, "failed to create temp dir")
            if clientconnected:
                #client.close()
                clientconnected = false
            return
        if g_dbg: echo " +-> getting file"



        try:
            #client.downloadFile("https://github.com/crackman2/irc_mcgee/raw/master/update/irc_mcgee.exe",tmpexe)
            var data_tmpexe = updt_fetchWebsiteContent("https://github.com/crackman2/irc_mcgee/raw/master/update/irc_mcgee.exe")
            writeFile(tmpexe,data_tmpexe)
            #client.close()
        except OSError as e:
            if g_dbg: echo " +-> downloading file failed"
            if(respond_to_caller):
                iclient.privmsg(ievent.origin, "failed to download main executable [" & repr(e) & "]")
            if clientconnected:
                #client.close()
                clientconnected = false
            return
        


        if fileExists(tmpexe):
            if g_dbg: echo " +-> download successful"
            #var tmpbat = tmpdir & "irc_mcpatch.bat"
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



            echo "Starting the patcher"
            ## discard startProcess(tmpbat, args = ["\"" & getAppFilename() & "\"", a_very_random_number]) ## THIS DOES NOT START IT PROPERLY
            ## discard execShellCmd("start /B \"" & tmpbat & "\" \"" & getAppFilename() & "\" " & $a_very_random_number) ## ENDLESS LOOP
            discard startProcess("cmd.exe",args = ["/C start /B " & tmpbat & " \"" & getAppFilename() & "\" " & $a_very_random_number])

            echo "time to go ,2seconds"
            sleep(2000)
            quit(0)


        #client.close()
    except OSError as e:
        if g_dbg: echo " +-> update failed"
        if(respond_to_caller):
                iclient.privmsg(ievent.origin, "failed to on a very deep level [" & repr(e) & "]")