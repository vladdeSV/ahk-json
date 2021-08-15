#Include "..\json.ahk"
#Include "simpleunit.ahk"

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

a := JSON.Parse('["foo", 42, 13.37]')
b := Array('foo', 42, 13.37)
AssertEquals(a, b, 'Parse simple array with strings, integers, and floats')

a := JSON.Parse('[]')
b := JSON.Parse('   [    ]       ')
AssertEquals(a, b, 'Parse empty array, whitespace does not modify behaviour')

a := JSON.Parse('[[[[[]]]]]')
b := Array(Array(Array(Array(Array()))))
AssertEquals(a, b, 'Parse nested arrays')

a := JSON.Stringify(Map('a', 'foo', 'b', 42, 'c', 13.37, 'd': 10))
b := '{"a":"foo","b":42,"c":13.37}'
AssertEquals(a, b, '')

temp_obj := JSON.Parse('{"a": "foo", "b": 42, "c": 13.37}')
temp_str := JSON.Stringify(temp_obj)
temp_obj2 := JSON.Parse(temp_str)
temp_str2 := JSON.Stringify(temp_obj2)

AssertEquals(temp_obj, temp_obj2)
AssertEquals(temp_str, temp_str2)
