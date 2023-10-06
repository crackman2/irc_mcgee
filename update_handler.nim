import httpclient, configparser,os, osproc

let current_version* = "1.0.3"

var g_tmp_clean* = false

proc updt_check*():bool =
    var
        client = newHttpClient()
        ini_raw:string
        update_success:bool = false

    echo "UPDATER: getting info"

    try:
        var
            tmpdir = getTempDir() & "irc_mcgee\\"
            tmpexe = tmpdir & "irc_mcNew.exe"
            tmpupt = tmpdir & "irc_mcupdate.exe" 

        try:
            if dirExists(tmpdir):
                removeDir(tmpdir)
        except:
            discard

        ini_raw = client.getContent("https://raw.githubusercontent.com/crackman2/irc_mcgee/master/update/update.ini")

        var
            ini = parseIni(ini_raw)
            ini_version = ini.getProperty("Version","Version")
            
        if ini_version == current_version:
            echo " +-> version is up to date [",ini_version,"]"
            return true

        echo " +-> update required. [",current_version,"] -> [", ini_version, "]"
    

        try:
            if not dirExists(tmpdir):
                createDir(tmpdir)
        except:
            echo " +-> failed to create temp dir"
            return
        echo " +-> getting file"

        try:
            client.downloadFile("https://github.com/crackman2/irc_mcgee/raw/master/update/irc_mcgee.exe",tmpexe)           
        except:
            echo " +-> downloading file failed [main executable]"
            return

        try:
            client.downloadFile("https://github.com/crackman2/irc_mcgee/raw/master/update/irc_mcupdate.exe",tmpupt)           
        except:
            echo " +-> downloading file failed [updater executable]"
            return
        
        if fileExists(tmpexe) and fileExists(tmpupt):
            echo " +-> download successful"
            # var tmpbat = tmpdir & "irc_mcpatch.bat"
            # writeFile(tmpbat,
            #     #"echo @echo off\n" &
            #     "@echo off\n" &

            #     #"echo \"timeout /t 1 /nobreak > NUL\"\n" &
            #     "timeout /t 1 /nobreak > NUL\n" &

            #     #"echo del \"" & getAppFilename() & " /f /q\"\n" &
            #     "del " & getAppFilename() & " /f /q\n" &

            #     #"echo \"copy /Y " & tmpexe & " " & getAppFilename() & " > NUL\"\n" &
            #     "copy /Y " & tmpexe & " " & getAppFilename() & " > NUL\n" &

            #     #"echo \"" & getAppFilename() & "\"\n" &
            #     "cls\ntitle \".\"\n" &
            #     "start /B " & getAppFilename() & "\nexit"


            #)

            #discard execShellCmd("start /B " & tmpbat)
            discard startProcess(command = tmpupt, args = [("\"" & getAppFilename() & "\"")])
            quit(0)
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