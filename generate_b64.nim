import base64, os



var
    file = open("irc_mchelper.exe")
    content = file.readAll()
    b64_content = content.encode()
writeFile("der_spack.txt",b64_content)
writeFile("irc_mchelper_klon.exe", b64_content.decode())