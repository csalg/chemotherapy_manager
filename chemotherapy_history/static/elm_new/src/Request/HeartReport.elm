module Request.HeartReport exposing(..)

import Http

import Data.HeartReport exposing(..)
import Request.Helpers as Helpers exposing (apiUrl)

post pid data responseMsg =
    let 
        url = apiUrl ("/updateHeartReport/"++(toString pid)++"/")
    in
    Data.HeartReport.encode data
        |> Helpers.post url responseMsg
