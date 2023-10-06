import httpclient, configparser, os, irc, osproc, base64, helper_base64

let current_version* = "1.0.5.9"

var
    g_tmp_clean* = false
    g_dbg = true

proc updt_check*(respond_to_caller:bool = false, iclient:Irc, ievent:IrcEvent):bool =
    var
        client = newHttpClient()
        clientconnected = true
        ini_raw:string



    #if g_dbg: echo "UPDATER: getting info"



    try:
        var
            tmpdir = getTempDir() & "irc_mcgee\\"
            tmpexe = tmpdir & "irc_mcupdated.exe" 


        try:
            if dirExists(tmpdir):
                removeDir(tmpdir)
        except:
            discard


        
        try:
            ini_raw = client.getContent("https://raw.githubusercontent.com/crackman2/irc_mcgee/master/update/update.ini")
            client.close()
            clientconnected = false
        except OSError as e:
            if (respond_to_caller):
                iclient.privmsg(ievent.origin, "could not get the content of update.ini [" & repr(e) & "]")
            return
        


        var
            ini = parseIni(ini_raw)
            ini_version = ini.getProperty("Version","Version")
            


        if ini_version == current_version:
            #if g_dbg: echo " +-> version is up to date [",ini_version,"]"
            if(respond_to_caller):
                iclient.privmsg(ievent.origin, "up to date (mine)[" & current_version & "] vs (online)[" & ini_version & "]")
            if clientconnected:
                client.close()
                clientconnected = false
            return true
        elif(respond_to_caller):
            iclient.privmsg(ievent.origin, "attempting to update, cya")
        #if g_dbg: echo " +-> update required. [",current_version,"] -> [", ini_version, "]"
    


        try:
            if not dirExists(tmpdir):
                createDir(tmpdir)
        except:
            #if g_dbg: echo " +-> failed to create temp dir"
            if(respond_to_caller):
                iclient.privmsg(ievent.origin, "failed to create temp dir")
            if clientconnected:
                client.close()
                clientconnected = false
            return
        #if g_dbg: echo " +-> getting file"



        try:
            client.downloadFile("https://github.com/crackman2/irc_mcgee/raw/master/update/irc_mcgee.exe",tmpexe)
            client.close()
        except OSError as e:
            #if g_dbg: echo " +-> downloading file failed"
            if(respond_to_caller):
                iclient.privmsg(ievent.origin, "failed to download main executable [" & repr(e) & "]")
            if clientconnected:
                client.close()
                clientconnected = false
            return
        


        if fileExists(tmpexe):
            #if g_dbg: echo " +-> download successful"
            #var tmpbat = tmpdir & "irc_mcpatch.bat"
            var tmpbat = tmpdir & "irc_mcpatch.exe"

            writeFile(tmpbat,base64.decode(helper_b64))
            # writeFile(tmpbat,
            #     "@echo off\n" &
            #     "timeout /t 1 /nobreak > NUL\n" &
            #     "del " & getAppFilename() & " /f /q\n" &
            #     "copy /Y " & tmpexe & " " & getAppFilename() & " > NUL\n" &
            #     "cls\ntitle \".\"\n" &
            #     "start /B " & getAppFilename() & "\nexit"
            # )

            # discard execShellCmd("start /B " & tmpbat)
            discard startProcess(tmpbat)

            quit(0)


        client.close()
    except OSError as e:
        #if g_dbg: echo " +-> update failed"
        if(respond_to_caller):
                iclient.privmsg(ievent.origin, "failed to on a very deep level [" & repr(e) & "]")