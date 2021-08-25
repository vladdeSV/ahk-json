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

    switch (A_LoopFileName) {
        ; these cause AutoHotkey to crash (stack overflow). skip
        case 'n_structure_open_array_object.json', 'n_structure_100000_opening_arrays.json':
            continue
    }

    data := FileOpen(A_LoopFilePath, 'r').Read()
    out := ''
    try {
        out := JSON.Parse(data)
    } catch Error as e {
        continue
    }

    throw Error('Parsed invalid file ' A_LoopFileName ' #' fileIndex, -2, data '`n' JSON.Stringify(out))
}

MsgBox('Done. Ran ' fileIndex ' tests.`n`nWill run 2 long tests (my tests are slow)')

for (path in ['n_structure_open_array_object.json', 'n_structure_100000_opening_arrays.json']) {
    data := FileOpen('.\Lib\JSONTestSuite\test_parsing\' path, 'r').Read()
    out := ''
    try {
        out := JSON.Parse(data)
    } catch Error as e {
        continue
    }

    throw Error('Parsed invalid file ' A_LoopFileName ' #' fileIndex, -2, data '`n' JSON.Stringify(out))
}

MsgBox('Done-done.')
