🛑 Unsuitable for production until v1.0 is released.

# ahk-json
[![ahk version](https://img.shields.io/badge/AHK-2.0--beta.1-428B42)][ahk2.0-beta.1]
[![json rfc](https://img.shields.io/badge/RFC-8259-white)][rfc8259]

JSON handler for AutoHotkey, [RFC 8259][rfc8259] compliant.

## Example

Parsing JSON
```ahk
input := '{"a": "foo", "b": null, "c": 13.37, "d": {"a": [1, 2, 3]}}'
data := JSON.Parse(input)

; these are equal
data['a'] == 'foo'
data['b'] == JSON.Null
data['c'] == 13.37
data['d']['a'][3] == 3
```

Outputting JSON
```ahk
; using `data` from above example
output := JSON.Stringify(data)
output == '{"a":"foo","b":null,"c":13.37,"d":{"a":[1,2,3]}}'

```

## License
MIT © [Vladimirs Nordholm](https://github.com/vladdeSV)

[ahk2.0-beta.1]: https://www.autohotkey.com/download/2.0/
[rfc8259]: https://datatracker.ietf.org/doc/html/rfc8259 "RFC 2859"
