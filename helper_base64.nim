import base64
const
    file_data = readFile("irc_mchelper.exe")
    helper_b64* = file_data.encode()