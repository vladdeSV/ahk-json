#Include 'JSON.ahk'

fileIndex := 0

loop files '.\Lib\JSONTestSuite\test_parsing\y_*.json' {
    fileIndex := fileIndex + 1

    data := FileOpen(A_LoopFilePath, 'r').Read()

    try {
        JSON.Parse(data)
    } catch Error as e {
        throw Error('Could not parse file ' A_LoopFileName ' #' fileIndex, -2, e.Message)
    }
}

loop files '.\Lib\JSONTestSuite\test_parsing\n_*.json' {
    fileIndex := fileIndex + 1

    data := FileOpen(A_LoopFilePath, 'r').Read()
    out := ''
    try {
        out := JSON.Parse(data)
    } catch Error as e {
        continue
    }

    throw Error('Parsed invalid file ' A_LoopFileName ' #' fileIndex, -2, data '`n' JSON.Stringify(out))
}

MsgBox('Done')
