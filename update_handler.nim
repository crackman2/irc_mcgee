import httpclient, configparser

let current_version = "1.0.0"

proc updt_check*() =
    var
        client = newHttpClient()
        #ini_raw = client.getContent()
        #wip
    discard