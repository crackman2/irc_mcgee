import os, strutils, random, base64, re
proc main() =
    randomize()
    let
        inputFile = paramStr(1)
        nameInt = rand(100..999)
        outputFile = "./files/output_file" & $nameInt & ".bin"

    if not fileExists(inputFile):
        echo "Input file does not exist."
        quit(1)

    var
        inputFileContents = readFile(inputFile)
        cleanedContents:string
        noWhitespaceContents:string
    #cleanedContents = re.replace(inputFileContents, re"\[\d{2}:\d{2}:\d{2}\]", " ")
    cleanedContents = re.replace(inputFileContents, re"<.{16}>", " ")
    noWhitespaceContents = strutils.replace(cleanedContents," ","")
    noWhitespaceContents = strutils.replace(noWhitespaceContents,"\n","")
    noWhitespaceContents = strutils.replace(noWhitespaceContents,"\r","")



    if noWhitespaceContents.len == 0:
        echo "No content left after cleaning."
        quit(2)

    let
        decodedData = decode(noWhitespaceContents)
        outFile = open(outputFile, fmWrite)
  
    outFile.write(decodedData)
    outFile.close()

    echo "File saved as: ", outputFile

when isMainModule:
    main()
