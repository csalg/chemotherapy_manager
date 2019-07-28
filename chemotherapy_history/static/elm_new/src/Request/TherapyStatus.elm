module Request.TherapyStatus exposing(..)

import Http

import Data.TherapyStatus exposing(..)
import Request.Helpers as Helpers exposing (apiUrl)

post pid data responseMsg =
    let 
        url = apiUrl ("/updateTherapyStatus/"++(toString pid)++"/")
    in
    Data.TherapyStatus.encode data
        |> Helpers.post url responseMsg
