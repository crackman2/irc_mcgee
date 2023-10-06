import configparser, httpclient, strutils

var
    client = newHttpClient()

try:
    var ini_raw = client.get("https://raw.githubusercontent.com/crackman2/irc_mcgee/master/update/update.ini")

    client.

    var
        c = parseIni(ini_raw)
        versionN = c.getProperty("Version","Version")
    #versionN = versionN.strip(chars = {'\"'})

    echo "current version is :[" & versionN & "]"

except:
    echo "getting content failed"
finally:
    client.close()

