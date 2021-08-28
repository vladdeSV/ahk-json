#Include "json.ahk"
#Include <Saul/Saul>


; test custon null implementation
Assert(JSON.Null == JSON.Null, 'Strict compare (``==``) of null')
Assert(JSON.Null = JSON.Null, 'Compare (``=``) of null')
Assert(JSON.Null != {}, 'Comparing with newly instanciated object fails')

; test basic parsing

/**
 * @return [string, Any, string][]
 */
provider := [
    [
        '{}',
        Map(),
        'Parse empty JSON object'
    ],
    [
        '{"a": "foo", "b": 42, "c": 13.37}',
        Map('a', 'foo', 'b', 42, 'c', 13.37),
        'Parse simple object with strings, integers, and floats'
    ],
    [
        '[]',
        Array(),
        ''
    ],
    [
        'null',
        JSON.Null,
        'Parse only null'
    ],
    [
        '[null, null, null]',
        Array(JSON.Null, JSON.Null, JSON.Null),
        'Parse null in array'
    ],
    [
        '{"foo": null, "bar": {"a": null, "b": null}}',
        Map('foo', JSON.Null, 'bar', Map('a', JSON.Null, 'b', JSON.Null)),
        'Parse null in nested object'
    ],
    [
        '["foo", 42, 13.37]',
        Array('foo', 42, 13.37),
        'Parse simple array with strings, integers, and floats'
    ],
    [
        '[[[[[]]]]]',
        Array(Array(Array(Array(Array())))),
        'Parse nested arrays'
    ],
    [
        '"\\"',
        '\',
        'Parse escaped reverse solidus in string'
    ],
]

for data in provider {
    a := JSON.Parse(data[1])
    b := data[2]
    AssertEquals(a, b, data[3])
}

; test parsing with whitespace
a := JSON.Parse('[]')
b := JSON.Parse('   [    ]       ')
AssertEquals(a, b, 'Parse empty array, whitespace does not modify behaviour')


; test stringify
a := JSON.Stringify(Map('a', 'foo', 'b', 42, 'c', 13.37, 'd', 10))
b := '{"a":"foo","b":42,"c":13.37,"d":10}'
AssertEquals(a, b, '')

a := JSON.Stringify(['\', '"', '\u0000'])
b := '["\\","\"","\u0000"]'
AssertEquals(a, b, 'Stringify escapes quotation marks (") and blackslash (\, reverse solidus)')


; test misc
temp_obj := JSON.Parse('{"a": "foo", "b": null, "c": 13.37, "d": {"a": [1, 2, 3]}}')
temp_str := JSON.Stringify(temp_obj)
temp_obj2 := JSON.Parse(temp_str)
temp_str2 := JSON.Stringify(temp_obj2)

AssertEquals(temp_obj, temp_obj2)
AssertEquals(temp_str, temp_str2)


; test stringify formatted and unformatted (pretty, unpretty)
minifiedJsonString := '{"a":"foo","b":null,"c":13.37,"d":{"a":[1,2,3]}}'
obj := JSON.Parse(minifiedJsonString)
AssertEquals(JSON.Stringify(obj), minifiedJsonString, 'Ensure JSON is minifed')
AssertEquals(JSON.Stringify(obj, true), '
(
{
    "a": "foo",
    "b": null,
    "c": 13.37,
    "d": {
        "a": [
            1,
            2,
            3
        ]
    }
}
)', 'Ensure pretty JSON string')
