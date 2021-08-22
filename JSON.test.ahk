#Include "json.ahk"
#Include <Saul/Saul>


; test custon null implementation
Assert(JSON.Null == JSON.Null, 'Strict compare (``==``) of null')
Assert(JSON.Null = JSON.Null, 'Compare (``=``) of null')
Assert(JSON.Null != {}, 'Comparing with newly instanciated object fails')


; test parser
a := JSON.Parse('{}')
b := Map()
AssertEquals(a, b, 'Parse empty JSON object')

a := JSON.Parse('{"a": "foo", "b": 42, "c": 13.37}')
b := Map(
    'a', 'foo',
    'b', 42,
    'c', 13.37,
)
AssertEquals(a, b, 'Parse simple object with strings, integers, and floats')

a := JSON.Parse('[]')
b := Array()
AssertEquals(a, b, 'Parse empty array')

a := JSON.Parse('null')
b := JSON.Null
AssertEquals(a, b, 'Parse only null')

a := JSON.Parse('[null, null, null]')
b := Array(JSON.Null, JSON.Null, JSON.Null)
AssertEquals(a, b, 'Parse null in array')

a := JSON.Parse('{"foo": null, "bar": {"a": null, "b": null}}')
b := Map(
    'foo', JSON.Null,
    'bar', Map(
        'a', JSON.Null,
        'b', JSON.Null
    )
)
AssertEquals(a, b, 'Parse null in nested object')

a := JSON.Parse('["foo", 42, 13.37]')
b := Array('foo', 42, 13.37)
AssertEquals(a, b, 'Parse simple array with strings, integers, and floats')

a := JSON.Parse('[]')
b := JSON.Parse('   [    ]       ')
AssertEquals(a, b, 'Parse empty array, whitespace does not modify behaviour')

a := JSON.Parse('[[[[[]]]]]')
b := Array(Array(Array(Array(Array()))))
AssertEquals(a, b, 'Parse nested arrays')

a := JSON.Parse('"\\"')
b := '\'
AssertEquals(a, b)


; test stringify
a := JSON.Stringify(Map('a', 'foo', 'b', 42, 'c', 13.37, 'd', 10))
b := '{"a":"foo","b":42,"c":13.37,"d":10}'
AssertEquals(a, b, '')

temp_obj := JSON.Parse('{"a": "foo", "b": null, "c": 13.37, "d": {"a": [1, 2, 3]}}')
temp_str := JSON.Stringify(temp_obj)
temp_obj2 := JSON.Parse(temp_str)
temp_str2 := JSON.Stringify(temp_obj2)

AssertEquals(temp_obj, temp_obj2)
AssertEquals(temp_str, temp_str2)

a := JSON.Stringify(['\', '"', '\u0000'])
b := '["\\","\"","\u0000"]'
AssertEquals(a, b, 'Stringify escapes quotation marks (") and blackslash (\, reverse solidus)')
