import httpclient, configparser,os

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

        if not dirExists(getTempDir() & "irc_mcgee"):
            createDir(getTempDir() & "irc_mcgee")


        removeDir(getTempDir() & "irc_mcgee")
    except:
        echo " +-> update failed"
    finally:
        discard
