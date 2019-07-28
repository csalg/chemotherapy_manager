module Request.Helpers exposing (apiUrl, post)

import Http
import Data.DjangoResponse as DjangoResponse exposing(..)
import HttpBuilder exposing(..)


apiUrl : String -> String
apiUrl str =
    --"http://202.120.38.3:8080/api" ++ str
    "http://127.0.0.1:8000/api" ++ str

post url responseMsg body =
    let
        expect = DjangoResponse.decode_ 
                    |> Http.expectJson
    in
        url
            |> HttpBuilder.post
            |> withHeader "Content-Type" "application/json"
            |> withBody body
            |> withExpect expect
            |> HttpBuilder.send responseMsg