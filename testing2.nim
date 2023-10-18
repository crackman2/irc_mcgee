import winim, winim/inc/wininet, strutils, os

proc FileCloser(h: HANDLE) =
  if h != INVALID_HANDLE_VALUE:
    CloseHandle(h)

proc InetCloser(h: HINTERNET) =
  if h != nil:
    InternetCloseHandle(h)

proc UploadFile() =
  const
    DEFAULT_USERAGENT = "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1"
    MY_HOST = "192.168.1.101"
    ALT_HTTP_PORT = 8080
    METHOD_POST = "POST"

    szHeaders = "Content-Type: multipart/form-data; boundary=----974767299852498929531610575"
    szContent = "------974767299852498929531610575\r\nContent-Disposition: form-data; name=\"file\"; filename=\"main.cpp\"\r\nContent-Type: application/octet-stream\r\n\r\n"
    szEndData = "\r\n------974767299852498929531610575--\r\n"

  var hIn: HANDLE
  hIn = CreateFile("main.cpp", GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, nil)
  if hIn == INVALID_HANDLE_VALUE:
    echo "CreateFile Error"
    return

  var dwFileSize: DWORD
  dwFileSize = GetFileSize(hIn, nil) 
  if dwFileSize == INVALID_FILE_SIZE:
    echo "GetFileSize Error"
    return

  let sContentSize = szContent.len
  let sEndDataSize = szEndData.len

  var vBuffer: seq[byte]
  setLen(vBuffer, sContentSize + int(dwFileSize) + sEndDataSize)
  var szData: ptr byte = addr(vBuffer[0])

  memcpy(cast[ptr byte](szData), addr(szContent[0]), sContentSize)

  var dw: DWORD = 0
  while dw < dwFileSize:
    let buffer: seq[byte]
    setLen(buffer, 1024)
    var dwBytes: DWORD = 0
    if not ReadFile(hIn, addr(buffer[0]), buffer.len, addr(dwBytes), nil):
      echo "ReadFile Error"
      return

    memcpy(szData, addr(buffer[0]), int(dwBytes))
    szData += int(dwBytes)
    dw += dwBytes

  CloseHandle(hIn)

  memcpy(cast[ptr byte](szData), addr(szEndData[0]), sEndDataSize)

  var io, ic, hreq: HINTERNET
  io = InternetOpen(DEFAULT_USERAGENT, INTERNET_OPEN_TYPE_DIRECT, nil, nil, 0)
  if io == nil:
    echo "InternetOpen Error"
    return

  ic = InternetConnect(io, MY_HOST, ALT_HTTP_PORT, nil, nil, INTERNET_SERVICE_HTTP, 0, 0)
  if ic == nil:
    echo "InternetConnect Error"
    return

  hreq = HttpOpenRequest(ic, METHOD_POST, "/upload", nil, nil, nil, 0, 0)
  if hreq == nil:
    echo "HttpOpenRequest Error"
    return

  if not HttpSendRequest(hreq, szHeaders, -1, addr(vBuffer[0]), vBuffer.len):
    echo "HttpSendRequest Error"
