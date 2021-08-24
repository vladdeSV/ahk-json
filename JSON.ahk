#Requires AutoHotkey v2.0-beta.1

class JSON {
    /**
     * @param string data JSON data
     * 
     * @return Map|Array
     */
    static Parse(data) {
        tokens := this.Internal.Lex(data)
        json := this.Internal.Parse(tokens)

        return json
    }

    /**
     * @param Map|Array variable
     * 
     * @return string
     */
    static Stringify(variable) {
        json := this.Internal.Format(variable)

        return json
    }

    /**
     * Custom null implementation
     *
     * @returns Object Read-only static variable
     */
    static Null {
        get {
            static null := {}
            return null
        }
    }

    /**
     * Contains internal logic for parsing and printing JSON
     *
     * @see https://notes.eatonphil.com/writing-a-simple-json-parser.html
     */
    class Internal {

        /**
        * @return Array JSON tokens
        */
        static Lex(data) {
            ; placeholder value when lexing part does not match
            static None := {}

            LexString(str) {
                jsonString := ''

                if (SubStr(str, 1, 1) != '"') {
                    return [None, str]
                }

                ; we are now inside a string. continue until we hit a " that is not escaped

                ; remove first character (the quote)
                MunchString(&str, 1)

                while ((character := MunchString(&str))) != '' {
                    if (character == '\') {
                        c := MunchString(&str)
                        switch (c) {
                            case '\':
                            case '/':
                            case '"':
                                character := c
                            case 'b':
                                character := Ord(8) ; backspace
                            case 'f':
                                character := Ord(12) ; formfeed
                            case 'n':
                                character := '`n'
                            case 't':
                                character := '`t'
                            case 'r':
                                character := '`r'
                            case 'u':
                                ; we got ourselves a big one

                                foo := MunchString(&str, 4)
                                if(StrLen(foo) != 4) {
                                    throw Error('Invalid \u sequence `'' foo)
                                }
                                ; todo check all characters are hex

                                character := '\u' foo
                            default:
                                throw Error('Unrecognized escaped character ' c)
                        }
                    } else if (character == '"') {
                        return [jsonString, str]
                    }

                    jsonString := jsonString . character
                }

                throw Error('Expected end-of-string quote', -1)
            }

            LexBoolean(str) {
                if (SubStr(str, 1, 4) == 'true') {
                    return ['true', SubStr(str, 5)]
                }


                if (SubStr(str, 1, 5) == 'false') {
                    return ['false', SubStr(str, 6)]
                }

                return [None, str]
            }

            LexNull(str) {
                if (SubStr(str, 1, 4) == 'null') {
                    return [JSON.Null, SubStr(str, 5)]
                }

                return [None, str]
            }

            LexNumber(str) {
                jsonNumber := ''

                numbers := '0123456789-+eE.'

                for (character in StrSplit(str)){
                    if (!InStr(numbers, character)) {
                        break
                    }

                    jsonNumber := jsonNumber character
                }

                rest := SubStr(str, StrLen(jsonNumber) + 1)

                if (StrLen(jsonNumber) == 0) {
                    return [None, str]
                }

                if (InStr(jsonNumber, '.') || InStr(jsonNumber, 'e')) {
                    jsonNumber := Float(jsonNumber)
                } else {
                    jsonNumber := Integer(jsonNumber)
                }

                return [jsonNumber, rest]
            }

            tokens := []

            while (StrLen(data)) {
                ; is a string
                jsonString := LexString(data)
                if (jsonString[1] != None) {
                    tokens.Push(jsonString[1])
                    data := jsonString[2]
                    continue
                }

                ; is a boolean
                jsonBoolean := LexBoolean(data)
                if (jsonBoolean[1] != None) {
                    tokens.Push(jsonBoolean[1])
                    data := jsonBoolean[2]
                    continue
                }

                ; is null
                jsonNull := LexNull(data)
                if (jsonNull[1] != None) {
                    tokens.Push(jsonNull[1])
                    data := jsonNull[2]
                    continue
                }

                ; is number
                jsonNumber := LexNumber(data)
                if (jsonNumber[1] != None) {
                    tokens.Push(jsonNumber[1])
                    data := jsonNumber[2]
                    continue
                }

                ; is whitespace
                if (InStr(' `t`n`r', SubStr(data, 1, 1))) {
                    data := SubStr(data, 2)
                    continue
                }

                ; is json syntax characters
                if (InStr('{}()[]:,', SubStr(data, 1, 1))) {
                    tokens.Push(SubStr(data, 1, 1))
                    data := SubStr(data, 2)
                    continue
                }

                throw Error('Unexpected character: ' SubStr(data, 1, 1), -3)
            }

            return tokens
        }

        /**
         * @return Any
         */
        static Parse(tokens) {
            BEGIN_OBJECT := 'BEGIN_OBJECT'
            END_OBJECT := 'END_OBJECT'
            BEGIN_ARRAY := 'BEGIN_ARRAY'
            END_ARRAY := 'END_ARRAY'
            COLON := 'COLON'
            COMMA := 'COMMA'
            STRING_ := 'STRING'
            NUMBER_ := 'NUMBER'
            NULL := 'NULL'
            BOOLEAN := 'BOOLEAN'

            /**
            * @return string
            */
            ParseTokenKind(token) {
                switch token {
                    case '{':
                        return BEGIN_OBJECT
                    case '}':
                        return END_OBJECT
                    case '[':
                        return BEGIN_ARRAY
                    case ']':
                        return END_ARRAY
                    case ':':
                        return COLON
                    case ',':
                        return COMMA
                    case 'true', 'false':
                        return BOOLEAN
                    default:
                        if (token == JSON.Null) {
                            return NULL
                        }

                        if (Type(token) == 'Integer' || Type(token) == 'Float') {
                            return NUMBER_
                        }

                        return STRING_
                }
            }

            /**
            * @return Array
            */
            SubArr(arr, from, length := 0) {
                ret := arr.Clone()
                ret.RemoveAt(1, from - 1)

                if (length > 0) {
                    ret.RemoveAt(length + 1, ret.length - length)
                }

                return ret
            }

            /**
            * @return [Array, Array]
            */
            ParseArray(tokens) {
                json_array := []

                token := tokens[1]
                tokenKind := ParseTokenKind(token)

                if (tokenKind == END_ARRAY) {
                    return [json_array, SubArr(tokens, 2)]
                }

                while (true) {
                    foo := ParseRecursive(tokens)
                    json_ := foo[1]
                    tokens := foo[2]

                    if (tokens.length == 0) {
                        break
                    }

                    json_array.Push(json_)

                    token := tokens[1]
                    tokenKind := ParseTokenKind(token)

                    if (tokenKind == END_ARRAY) {
                        return [json_array, SubArr(tokens, 2)]
                    } else if (tokenKind !== COMMA) {
                        throw Error('Expected comma after value in array', -3)
                    } else {
                        tokens := SubArr(tokens, 2)
                    }
                }

                throw Error('Expected end-of-array')
            }

            /**
            * @return [Map, Array]
            */
            ParseObject(tokens) {
                json_object := Map()

                token := tokens[1]
                tokenKind := ParseTokenKind(token)

                if (tokenKind == END_OBJECT) {
                    return [json_object, SubArr(tokens, 2)]
                }

                while (true) {
                    json_key := tokens[1]
                    tokenKind := ParseTokenKind(json_key)

                    if (tokenKind == STRING_) {
                        tokens := SubArr(tokens, 2)
                    } else {
                        throw Error('Expected string key, got ' tokenKind, -3)
                    }

                    if (ParseTokenKind(tokens[1]) !== COLON) {
                        throw Error('Expected colon after key in object, got ' tokenKind, -3)
                    }

                    foo := ParseRecursive(SubArr(tokens, 2))
                    json_value := foo[1]
                    tokens := foo[2]

                    if (tokens.length == 0) {
                        break
                    }

                    json_object[json_key] := json_value

                    token := tokens[1]
                    tokenKind := ParseTokenKind(token)

                    if (tokenKind == END_OBJECT) {
                        return [json_object, SubArr(tokens, 2)]
                    } else if (tokenKind !== COMMA) {
                        throw Error()
                    }

                    tokens := SubArr(tokens, 2)
                }

                throw Error('Expected end-of-object')
            }

            /**
            * @return [Any, Array]
            */
            ParseRecursive(tokens) {
                token := tokens[1]
                tokenKind := ParseTokenKind(token)

                switch (tokenKind) {
                    case BEGIN_ARRAY:
                        return ParseArray(SubArr(tokens, 2))
                    case BEGIN_OBJECT:
                        return ParseObject(SubArr(tokens, 2))
                    case BOOLEAN, NUMBER_, STRING_, NULL:
                        return [token, SubArr(tokens, 2)]
                    default:
                        throw Error('Unexpected token ' token)
                }
            }

            if (tokens.length == 0) {
                throw Error('Invalid JSON. No data provided.')
            }

            result := ParseRecursive(tokens)

            if (result[2].length !== 0) {
                throw Error('Invalid JSON. Expected one top level value, found multiple tokens.')
            }

            return result[1]
        }

        /**
         * @param any Any
         *
         * @return string
         */
        static Format(any_) {

            FormatArray(arr) {
                output := ''
                for (index, value in arr) {
                    if (index !== 1) {
                        output := output ','
                    }

                    output := output FormatRec(value)
                }

                return '[' output ']'
            }

            FormatMap(obj) {
                output := ''

                first := true
                for (key, value in obj) {
                    if (!first) {
                        output := output ','
                    }

                    first := false 

                    output := output '"' key '"' ':' FormatRec(value)
                }

                return '{' output '}'
            }

            FormatRec(s) {

                if(s == 'true' || s == 'false') {

                } else if (Type(s) == 'String') {

                    regex := '(\\(?!u)|")'
                    replace := '\$1'
                    s := RegExReplace(s, regex, replace)

                    s := '"' s '"'
                }

                if (Type(s) == 'Float') {
                    s := Round(s, 14)

                    while (StrLen(s) > 1 && SubStr(s, StrLen(s), 1) == '0') {
                        s := SubStr(s, 1, StrLen(s) - 1)
                    }
                }

                if (Type(s) == 'Array') {
                    s := FormatArray(s)
                }

                if (Type(s) == 'Map') {
                    s := FormatMap(s)
                }

                if (s == JSON.null) {
                    s := 'null'
                }

                return s
            }

            return FormatRec(any_)
        }
    }
}

MunchString(&str, length := 1) {
    character := SubStr(str, 1, length)
    str := SubStr(str, length + 1)

    return character
}
