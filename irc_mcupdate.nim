import os, std/private/osfiles, osproc

## DOESNT WORK

var
    tmpdir = getTempDir() & "irc_mcgee\\"
    tmpexe = tmpdir & "irc_mcNew.exe" 


if fileExists(tmpexe):
    sleep(1500)
    var appfilename = paramStr(0)

    echo "Removing file: [", appfilename, "]"
    try:
        removeFile(appfilename)
    except:
        quit(0)

    echo "Copying [",tmpexe,"] to [" & appfilename & "]"
    copyFile(tmpexe, appfilename)

    discard startProcess(appfilename)

    # if fileExists(tmpexe):
    #     echo " +-> download successful"
    #     var tmpbat = tmpdir & "irc_mcpatch.bat"
    #     writeFile(tmpbat,
    #         #"echo @echo off\n" &
    #         "@echo off\n" &

    #         #"echo \"timeout /t 1 /nobreak > NUL\"\n" &
    #         "timeout /t 1 /nobreak > NUL\n" &

    #         #"echo del \"" & getAppFilename() & " /f /q\"\n" &
    #         "del " & getAppFilename() & " /f /q\n" &

    #         #"echo \"copy /Y " & tmpexe & " " & getAppFilename() & " > NUL\"\n" &
    #         "copy /Y " & tmpexe & " " & getAppFilename() & " > NUL\n" &

    #         #"echo \"" & getAppFilename() & "\"\n" &
    #         "cls\ntitle \".\"\n" &
    #         "start /B " & getAppFilename() & "\nexit"
    #     )