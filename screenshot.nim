import winim

proc srcn_captureScreen(x,y,width,height:int, pixelData: var seq[byte]):bool =
  var
    hdcScreen:HDC = GetDC(0)
    hdcMem:HDC = CreateCompatibleDC(hdcScreen)
    hBitmap:HBITMAP  = CreateCompatibleBitmap(hdcScreen, width, height)
  discard SelectObject(hdcMem, hBitmap)
  BitBlt(hdcMem, 0, 0, width, height, hdcScreen, x, y, SRCCOPY)

  var
    bi:BITMAPINFOHEADER 
  bi.biSize = sizeof(BITMAPINFOHEADER)
  bi.biWidth = width
  bi.biHeight = height
  bi.biPlanes = 1
  bi.biBitCount = 24
  bi.biCompression = BI_RGB
  bi.biSizeImage = 0
  bi.biXPelsPerMeter = 0
  bi.biYPelsPerMeter = 0
  bi.biClrUsed = 0
  bi.biClrImportant = 0
  
  GetDIBits(hdcMem, hBitmap, 0, height, addr pixelData[0], cast[LPBITMAPINFO](addr bi), DIB_RGB_COLORS)
  DeleteDC(hdcMem)
  ReleaseDC(0, hdcScreen)
  DeleteObject(hBitmap)

  return true

proc srcn_saveBitmap(filename:string, width,height:uint32, pixelData: seq[byte]) =
  var
    file:File
  if file.open(filename,fmWrite):
    var
      headerSize:uint32 = 14
      infoHeaderSize:uint32 = 40
      imageSize:uint32 = width * height
      fileSize:uint32 = headerSize + infoHeaderSize + imageSize

      header:seq[uint8] = @[
        'B'.uint8, 'M'.uint8,
        0,0,0,0, #filzeSize 4 bytes: i = 2
        0,0,0,0,
        (headerSize+infoHeaderSize).uint8,
        0,0,0
      ]

      headerPtr:ptr array[4, uint32]
    
      infoHeader:seq[uint8] = @[
        0,0,0,0, # infoHeaderSize 4 bytes : i = 0
        0,0,0,0,  #width  4 bytes : i = 4
        0,0,0,0, #height 4 bytes : i = 8
        1,0,
        24,0,
        0,0,0,0,
        imageSize.uint8,0,0,0,
        0,0,0,0,
        0,0,0,0,
        0,0,0,0,
        0,0,0,0
      ]
      infoHeaderPtr:ptr array[10, uint32]

    headerPtr = cast[ptr array[4,uint32]](addr header[2])
    headerPtr[][0] = fileSize

    infoHeaderPtr = cast[ptr array[10,uint32]](addr infoHeader[0])
    infoHeaderPtr[][0] = infoHeaderSize
    infoHeaderPtr[][1] = width
    infoHeaderPtr[][2] = height

    discard file.writeBytes(header,0,len(header))
    discard file.writeBytes(infoHeader,0,len(infoHeader))
    discard file.writeBytes(pixelData, 0, len(pixelData))
    file.close()
  else:
    echo "error: opening file failed"
    return 


proc srcn_screenshot*(filename:string) =
  var 
    pixelData:seq[byte]
    left   = GetSystemMetrics(SM_XVIRTUALSCREEN)
    top    = GetSystemMetrics(SM_YVIRTUALSCREEN)
    right  = GetSystemMetrics(SM_CXVIRTUALSCREEN)
    bottom = GetSystemMetrics(SM_CYVIRTUALSCREEN)

  echo "LEFT  : ", left
  echo "TOP   : ", top
  echo "RIGHT : ", right
  echo "BOTTOM: ", bottom
  

  setLen(pixelData,right*bottom*24)
  if srcn_captureScreen(left,top,right,bottom,pixelData):
    srcn_saveBitmap(filename,right.uint32,bottom.uint32,pixelData)
    echo "image saved"
  else:
    echo "ERROR TAKING SCREENSHOT"



# when isMainModule:
#   srcn_screenshot("eeeeee2.bmp")
  
  #SM_XVIRTUALSCREEN   origin
  #SM_YVIRTUALSCREEN   origin
  #SM_CXVIRTUALSCREEN  size
  #SM_CYVIRTUALSCREEN  size