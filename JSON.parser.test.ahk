#Include 'JSON.ahk'

loop files '.\Lib\JSONTestSuite\test_parsing\y_*.json' {

    data := FileOpen(A_LoopFilePath, 'r').Read()

    try {
        JSON.Parse(data)
    } catch Error as e {
        throw Error('Could not parse file ' A_LoopFileName, -2, e.Message)
    }
}
