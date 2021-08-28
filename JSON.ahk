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
    static Stringify(variable, format_ := false) {
        json := this.Internal.Format(variable, format_)

        return json
    }

    /**
     * Custom null implementation
     *
     * @returns Object Read-only static variable
     */
    static Null {
        get {
            static null := {base: {__class: 'Null'}}
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

            MunchString(&str, length := 1) {
                character := SubStr(str, 1, length)
                str := SubStr(str, length + 1)

                return character
            }

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

                while ((character := MunchString(&str)) != '') {

                    ; check if the character code point is a "control character"
                    ; "[…] characters that MUST be escaped: […] the control characters (U+0000 through U+001F)" — RFC 8259 (https://datatracker.ietf.org/doc/html/rfc8259)
                    characterCodePoint := Ord(character)
                    if (characterCodePoint < 0x20) {
                        throw Error('Found un-escaped control character')
                    }

                    if (character == '\') {
                        c := MunchString(&str)
                        switch (c) {
                            case '\', '/', '"':
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
                                hex := MunchString(&str, 4)
                                if (RegExMatch(hex, '^[0-9a-fA-F]{4}$') == 0) {
                                    throw Error('Invalid \u sequence `'\u' hex '`'')
                                }

                                character := '\u' hex
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
                numbers := '0123456789-+eE.'
                jsonNumber := ''

                while ((character := MunchString(&str)) !== '') {
                    ; InStr does not work with null-bytes
                    if (character == Chr(0) || !InStr(numbers, character)) {
                        ; we munched a character that is not part of a number. put it back
                        str := character str
                        break
                    }

                    ; append character to a possible json number (does not guarantee it's a valid json number)
                    jsonNumber := jsonNumber character
                }

                ; check if valid number
                if (RegExMatch(jsonNumber, '^(-?(?:0|[1-9]\d*))(\.\d+)?([eE][+-]?\d+)?$') == 0) {
                    ; we have munched some characters. return those characters with the rest of the string
                    ; possibly we could optimize by not returning the rest of the string, as it's guaranteed to be invalid json
                    ; not going to do that since i would call it pre-mature optimization
                    return [None, jsonNumber str]
                }

                return [Number(jsonNumber), str]
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

                ; check for valid characters. not using `InStr(…)` because it does not handle null-bytes (which is invalid json)
                firstCharacter := SubStr(data, 1, 1)
                switch firstCharacter {
                    ; is whitespace
                    case ' ', '`t', '`n', '`r':
                        data := SubStr(data, 2)
                        continue
                    ; is json syntax
                    case '{', '}', '(', ')', '[', ']', ':', ',':
                        tokens.Push(firstCharacter)
                        data := SubStr(data, 2)
                        continue
                }

                ; is unexpected character
                throw Error('Unexpected character: `'' firstCharacter '`' (' Ord(firstCharacter) ')', -3)
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
            ParseArray(tokens, depth) {
                json_array := []

                token := tokens[1]
                tokenKind := ParseTokenKind(token)

                if (tokenKind == END_ARRAY) {
                    return [json_array, SubArr(tokens, 2)]
                }

                while (true) {
                    foo := ParseRecursive(tokens, depth)
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
            ParseObject(tokens, depth) {
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

                    foo := ParseRecursive(SubArr(tokens, 2), depth)
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
            ParseRecursive(tokens, depth) {

                if (depth > 128) {
                    throw Error('Maximum recursion depth limit reached')
                }

                token := tokens[1]
                tokenKind := ParseTokenKind(token)

                switch (tokenKind) {
                    case BEGIN_ARRAY:
                        return ParseArray(SubArr(tokens, 2), depth + 1)
                    case BEGIN_OBJECT:
                        return ParseObject(SubArr(tokens, 2), depth + 1)
                    case BOOLEAN, NUMBER_, STRING_, NULL:
                        return [token, SubArr(tokens, 2)]
                    default:
                        throw Error('Unexpected token ' token)
                }
            }

            if (tokens.length == 0) {
                throw Error('Invalid JSON. No data provided.')
            }

            result := ParseRecursive(tokens, 0)

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
        static Format(any_, format_) {

            Indent(level) {
                out := ''
                loop (level) {
                    out := out '    '
                }

                return out
            }

            FormatArray(arr, format_, level) {
                output := ''
                for (index, value in arr) {

                    if (format_) {
                        output := output '`n' Indent(level + 1)
                    }

                    output := output FormatRec(value, format_, level + 1)

                    if (index !== arr.length) {
                        output := output ','
                    }
                }

                if (output && format_) {
                    output := output '`n' Indent(level)
                }

                return '[' output ']'
            }

            FormatMap(obj, format_, level) {
                output := ''

                i := 1
                for (key, value in obj) {

                    if (format_) {
                        output := output '`n' Indent(level + 1)
                    }

                    output := output '"' key '"' ':' (format_ ? ' ' : '') FormatRec(value, format_, level + 1)

                    if (i !== obj.count) {
                        output := output ','
                    }

                    i++
                }

                if (output && format_) {
                    output := output '`n' Indent(level)
                }

                return '{' output '}'
            }

            FormatRec(s, format_, level) {

                if (Type(s) == 'String' && (s !== 'true' && s !== 'false')) {

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
                    s := FormatArray(s, format_, level)
                }

                if (Type(s) == 'Map') {
                    s := FormatMap(s, format_, level)
                }

                if (s == JSON.null) {
                    s := 'null'
                }

                return s
            }

            return FormatRec(any_, format_, 0)
        }
    }
}
