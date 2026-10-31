/// Pure response-shape checks; no provider, API key, or model call.
Class RouteGuard.Test.AIParser Extends %RegisteredObject
{

ClassMethod Run() As %Integer
{
    Set failures = 0
    Try {
        Set sc = $ClassMethod("RouteGuard.AI.ResponseParser","Parse","{""route"":""CONTACT"",""reason"":""Ask carrier for ETA.""}",.route,.reason)
    } Catch ex {
        Write "FAIL response parser is missing",!
        Set failures=failures+1
    }
    If failures > 0 Quit failures
    If $System.Status.IsError(sc) { Write "FAIL valid JSON",! Set failures=failures+1 }
    If route '= "CONTACT" { Write "FAIL valid route",! Set failures=failures+1 }
    If reason '= "Ask carrier for ETA." { Write "FAIL valid reason",! Set failures=failures+1 }

    Set sc = $ClassMethod("RouteGuard.AI.ResponseParser","Parse","```json"_$Char(10)_"{""route"":""CONTACT"",""reason"":""ok""}"_$Char(10)_"```",.route,.reason)
    If $System.Status.IsOK(sc) { Write "FAIL fenced output accepted",! Set failures=failures+1 }

    Set sc = $ClassMethod("RouteGuard.AI.ResponseParser","Parse","[{""route"":""CONTACT"",""reason"":""ok""}]",.route,.reason)
    If $System.Status.IsOK(sc) { Write "FAIL array accepted",! Set failures=failures+1 }

    Set sc = $ClassMethod("RouteGuard.AI.ResponseParser","Parse","{""route"":""CONTACT""}",.route,.reason)
    If $System.Status.IsOK(sc) { Write "FAIL missing reason accepted",! Set failures=failures+1 }

    Set sc = $ClassMethod("RouteGuard.AI.ResponseParser","Parse","{""route"":7,""reason"":""ok""}",.route,.reason)
    If $System.Status.IsOK(sc) { Write "FAIL numeric route accepted",! Set failures=failures+1 }

    Set longReason = $Translate($Justify("",501)," ","x")
    Set longJson = "{""route"":""CONTACT"",""reason"":"_$Char(34)_longReason_$Char(34)_"}"
    Set sc = $ClassMethod("RouteGuard.AI.ResponseParser","Parse",longJson,.route,.reason)
    If $System.Status.IsOK(sc) { Write "FAIL oversized reason accepted",! Set failures=failures+1 }

    Write "AI_PARSER_FAILURES=",failures,!
    Quit failures
}

}
