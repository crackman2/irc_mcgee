import winim/inc/wininet, winim, asyncdispatch

proc fileUpload*(filename:string):Future[string] {.async.}=
    var
        str_header = "Content-Type: multipart/form-data; boundary=----$$ABCXYZ$$"
        str_open =  "------$$ABCXYZ$$\r\n"&
                    "Content-Disposition: form-data; name=\"file\"; filename=\"" & filename & "\"\r\n"&
                    "Content-Type: application/octet-stream\r\n"&
                    "\r\n"
        str_close = "\r\n------$$ABCXYZ$$--\r\n"
        file_content = readFile(filename)
        file_size    = len(file_content)
        datalen = file_size + len(str_open) + len(str_close)
        data = str_open & file_content & str_close

        
        hconnect:HINTERNET = nil
        hrequest:HINTERNET = nil
        hsession:HINTERNET = InternetOpenA(LPCSTR("mcgee mcupload"), INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0.DWORD)
    

    if hsession.isNil:
        InternetCloseHandle(hsession)
        when defined(debug): echo "hsession failed"
        return
    
    hconnect = InternetConnectA(hsession, "file.io", INTERNET_DEFAULT_HTTPS_PORT, nil, nil, INTERNET_SERVICE_HTTP, 0.DWORD, cast[DWORD_PTR](0))

    if hconnect.isNil:
        InternetCloseHandle(hsession)
        InternetCloseHandle(hconnect)
        when defined(debug): echo "hconnect failed"
        return
    
    hrequest = HttpOpenRequestA(hconnect, "POST", "/", nil, nil, nil, INTERNET_FLAG_SECURE, cast[DWORD_PTR](0))

    if hrequest.isNil:
        InternetCloseHandle(hsession)
        InternetCloseHandle(hconnect)
        InternetCloseHandle(hrequest)
        when defined(debug): echo "hrequest failed"     
        return

    if HttpSendRequestA(hrequest, str_header, -1.DWORD, addr data[0], datalen.DWORD) == FALSE:
        InternetCloseHandle(hsession)
        InternetCloseHandle(hconnect)
        InternetCloseHandle(hrequest)
        when defined(debug): echo "HttpSendRequestA failed"
        return
    
    var
        received:DWORD = 0
        buf:array[1024, byte]
        response:string = ""
    while((InternetReadFile(hrequest, addr buf[0], sizeof(buf).DWORD, addr received) == TRUE) and received > 0):
        for i in 0..<received:
            response &= chr(buf[i])

    when defined(debug): echo "response: ", response
    return response