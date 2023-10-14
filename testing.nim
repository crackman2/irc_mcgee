import os,  winim/inc/winhttp, strutils, json, winim, strutils, osproc, configparser, update_handler, random

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






proc set_wallpaper() =
  randomize()

  var
    imagedata = updt_fetchWebsiteContent("https://images.wallpapersden.com/image/wl-beautiful-sunset-in-horizon-ocean_60525.jpg")
    


when isMainModule:
  # echo "hey"
  # var
  #   pixelData:seq[byte]
  # setLen(pixelData,1600*900*24)
  # if srcn_captureScreen(0,0,1600,900,pixelData):
  #   srcn_saveBitmap("testfile.bmp",1600,900,pixelData)
  # else:
  #   echo "A"
