import random

proc alphaNumeric*(length:int):string =
    result = ""
    randomize()
    while len(result) < length:
        var chooser = rand(0..2)
        case chooser:
        of 0:
            result &= char(rand(0x41..0x5A)) #Upper
        of 1:
            result &= char(rand(0x61..0x7A)) #Lower
        else:
            result &= char(rand(0x30..0x39)) #Number