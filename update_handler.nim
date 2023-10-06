import httpclient, configparser,os, osproc

let current_version = "1.0.0"

proc updt_check*() =
    var
        client = newHttpClient()
        ini_raw:string
        update_success:bool = false

    echo "UPDATER: getting info"

    try:
        ini_raw = client.getContent("https://raw.githubusercontent.com/crackman2/irc-mcgee/main/update/update.ini")
        
        
        var
            ini = parseIni(ini_raw)
            ini_version = ini.getProperty("Version","Version")
            
        if ini_version == current_version:
            echo " +-> version is up to date [",ini_version,"]"
            return

        echo " +-> update required. [",current_version,"] -> [", ini_version, "]"
        
        var
            tmpdir = getTempDir() & "irc_mcgee\\"
            tmpexe = tmpdir & "irc_mcupdate.exe"

        try:
            if not dirExists(tmpdir):
                createDir(tmpdir)
        except:
            echo " +-> failed to create temp dir"
            return
        echo " +-> getting file"

        try:
            client.downloadFile("https://github.com/crackman2/irc-mcgee/raw/main/update/irc_mcgee.exe",tmpexe)
        except:
            echo " +-> downloading file failed"
            return
        
        if fileExists(tmpexe):
            echo " +-> download successful"
            var tmpbat = tmpdir & "irc_mcpatch.bat"
            writeFile(tmpbat,
                "@echo off\n" &
                "timeout /t 1 /nobreak > NUL\n" &
                "del " & getCurrentDir() & getAppFilename() & "/f /q\n" &
                "copy /Y " & tmpexe & " " & getCurrentDir() & getAppFilename() & " > NUL\n" &
                getCurrentDir() & getAppFilename() & "\n" &
                "del " & tmpdir & " /f /q\n"
            )

            discard execCmd("cmd.exe /C start /b " & tmpbat)

            quit(0)
            

            

        #removeDir(getTempDir() & "irc_mcgee")
    except:
        echo " +-> update failed"
    finally:
        discard
