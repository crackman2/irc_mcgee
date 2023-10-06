import httpclient, configparser, os, irc

let current_version* = "1.0.4.9"

var g_tmp_clean* = false

proc updt_check*(respond_to_caller:bool = false, iclient:Irc, ievent:IrcEvent):bool =
    var
        client = newHttpClient()
        clientconnected = true
        ini_raw:string
        update_success:bool = false

    echo "UPDATER: getting info"

    try:
        var
            tmpdir = getTempDir() & "irc_mcgee\\"
            tmpexe = tmpdir & "irc_mcupdated.exe" 
            tmpini = tmpdir & "irc_mcversion.ini"

        try:
            if dirExists(tmpdir):
                removeDir(tmpdir)
        except:
            discard
        try:
            client.downloadFile("https://raw.githubusercontent.com/crackman2/irc_mcgee/master/update/update.ini",tmpini)
            var inifile = open(tmpini)
            ini_raw = inifile.readAll()
            client.close()
            clientconnected = false
        except:
            if (respond_to_caller):
                iclient.privmsg(ievent.origin, "could not download update.ini")
            return
        
        var
            ini = parseIni(ini_raw)
            ini_version = ini.getProperty("Version","Version")
            

        if ini_version == current_version:
            echo " +-> version is up to date [",ini_version,"]"
            if(respond_to_caller):
                iclient.privmsg(ievent.origin, "up to date (mine)[" & current_version & "] vs (online)[" & ini_version & "]")
            if clientconnected:
                client.close()
                clientconnected = false
            return true
        elif(respond_to_caller):
            iclient.privmsg(ievent.origin, "attempting to update, cya")
        echo " +-> update required. [",current_version,"] -> [", ini_version, "]"
    

        try:
            if not dirExists(tmpdir):
                createDir(tmpdir)
        except:
            echo " +-> failed to create temp dir"
            if clientconnected:
                client.close()
                clientconnected = false
            return
        echo " +-> getting file"

        try:
            client.downloadFile("https://github.com/crackman2/irc_mcgee/raw/master/update/irc_mcgee.exe",tmpexe)
            client.close()
        except:
            echo " +-> downloading file failed"
            if clientconnected:
                client.close()
                clientconnected = false
            return
        
        if fileExists(tmpexe):
            echo " +-> download successful"
            var tmpbat = tmpdir & "irc_mcpatch.bat"
            writeFile(tmpbat,
                #"echo @echo off\n" &
                "@echo off\n" &

                #"echo \"timeout /t 1 /nobreak > NUL\"\n" &
                "timeout /t 1 /nobreak > NUL\n" &

                #"echo del \"" & getAppFilename() & " /f /q\"\n" &
                "del " & getAppFilename() & " /f /q\n" &

                #"echo \"copy /Y " & tmpexe & " " & getAppFilename() & " > NUL\"\n" &
                "copy /Y " & tmpexe & " " & getAppFilename() & " > NUL\n" &

                #"echo \"" & getAppFilename() & "\"\n" &
                "cls\ntitle \".\"\n" &
                "start /B " & getAppFilename() & "\nexit"
            )

            discard execShellCmd("start /B " & tmpbat)

            quit(0)


        client.close()
    except:
        echo " +-> update failed"
    finally:
        discard


# proc updt_tmp_cleanup*() =
#     if not g_tmp_clean:
#         var f1, f2, d1 = false
#         if fileExists(getTempDir() & "irc_mcgee\\irc_mcpatch.bat"):
#             removeFile(getTempDir() & "irc_mcgee\\irc_mcpatch.bat")
#             f1 = not fileExists(getTempDir() & "irc_mcgee\\irc_mcpatch.bat")
        
#         if fileExists(getTempDir() & "irc_mcgee\\irc_mcupdate.exe"):
#             removeFile(getTempDir() & "irc_mcgee\\irc_mcupdate.exe")
#             f2 = not fileExists(getTempDir() & "irc_mcgee\\irc_mcupdate.exe") 

#         if dirExists(getTempDir() & "irc_mcgee"):
#             removeDir(getTempDir() & "irc_mcgee")
#             d1 = not dirExists(getTempDir() & "irc_mcgee")
        
#         g_tmp_clean = f1 and f2 and d1