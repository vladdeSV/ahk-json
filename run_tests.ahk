#Include 'JSON.ahk'

loop files '.\Lib\JSONTestSuite\test_parsing\y_*.json' {

    data := FileOpen(A_LoopFilePath, 'r').Read()

    try {
        JSON.Parse(data)
    } catch Error as e {
        throw Error('Could not parse file ' A_LoopFileName, -2, e.Message)
    }
}

loop files '.\Lib\JSONTestSuite\test_parsing\n_*.json' {

    data := FileOpen(A_LoopFilePath, 'r').Read()
    out := ''
    try {
        out := JSON.Parse(data)
    } catch Error as e {
        continue
    }

    throw Error('Parsed invalid file ' A_LoopFileName, -2, data '`n' JSON.Stringify(out))
}
