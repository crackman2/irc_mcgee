import os, osproc, random



var
    tmpdir = getTempDir() & "irc_mcgee\\"
    tmpexe_firsthalf = tmpdir & "irc_mcupdated"
    a_very_random_number = paramStr(2)
    tmpexe = tmpexe_firsthalf & a_very_random_number & ".exe"

if fileExists(tmpexe):
    echo "HELPER: Waiting 5.5seconds"
    sleep(5500)
    var
        appfilename = paramStr(1)


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
    discard startProcess(appfilename)
