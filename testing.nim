import configparser, httpclient, strutils

var
    client = newHttpClient()
    ini_raw:string

try:
    ini_raw = client.getContent("http://raw.githubusercontent.com/MeteorTheLizard/SMITE-Optimizer-Update/master/index.html")

    var
        c = parseIni(ini_raw)
        versionN = c.getProperty("Version","Version")
    versionN = versionN.strip(chars = {'\"'})
    echo "current version is :[" & versionN & "]"

except:
    echo "getting content failed"

