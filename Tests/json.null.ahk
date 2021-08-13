#Include "..\json.ahk"
#Include "simpleunit.ahk"

; test custon null implementation

Assert(JSON.Null == JSON.Null, 'Strict compare (``==``) of null')
Assert(JSON.Null = JSON.Null, 'Compare (``=``) of null')
Assert(JSON.Null != {}, 'Comparing with newly instanciated object fails')
