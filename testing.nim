import os,  winim/inc/winhttp, strutils, json, winim, strutils, osproc


proc uploadFile(filePath: string): string =
  let url = "https://file.io"
  let session = WinHttpOpen("Nim File Upload", WINHTTP_ACCESS_TYPE_NO_PROXY, nil, nil, 0)
  let connection = WinHttpOpenRequest(session, "POST", "/", nil, nil, nil, WINHTTP_FLAG_SECURE)

  # Set content type
  let headers = "Content-Type: multipart/form-data; boundary=---------------------------14737809831466499882746641449"

  # Create the multipart form data body
  var formData = "-----------------------------14737809831466499882746641449\r\n"
  var (_, name, ext) = splitFile(filePath)
  formData &= "Content-Disposition: form-data; name=\"file\"; filename=\"" & name & ext & "\"\r\n"
  formData &= "Content-Type: application/octet-stream\r\n\r\n"
  let body = formData & readFile(filePath) & "\r\n-----------------------------14737809831466499882746641449--\r\n"

  echo "BODY:\n", body

  var err_code = WinHttpSendRequest(connection, headers, headers.len,addr body[0], body.len, body.len, 0)
  echo "SendRequestErrcode: ", err_code
  
  err_code = WinHttpReceiveResponse(connection, nil)
  echo "ReceiveResponse: ", err_code

  var bytesRead:DWORD = 0
  var content: seq[byte]
  while true:
    var buffer = newSeq[byte](4096)
    if not WinHttpReadData(connection, buffer.addr, buffer.len, addr bytesRead):
      break
    if bytesRead == 0:
      break
    content.add(buffer[0..<bytesRead])

  WinHttpCloseHandle(connection)
  WinHttpCloseHandle(session)

  #let responseContent = content.newString(content.len).decode("utf-8")
  var content_str:string

  for i in 0..<len(content):
    content_str &= char(content[i])

  echo "RAW: ", $content
  echo "CONTENT: [", content_str, "]"

  let responseContent = content_str

  if responseContent.contains("success\":true"):
    let jsonResponse = parseJson(responseContent)
    return jsonResponse["link"].str
  else:
    return "Upload failed"

# Example usage
when isMainModule:
  #let uploadedLink = uploadFile("test.txt")
  var (output, exitcode) = execCmdEx("curl -F \"file=:@G:\\Script\\GitHub\\irc-mcgee\\test.txt\" https://file.io")
  echo "Uploaded file link: ", output
