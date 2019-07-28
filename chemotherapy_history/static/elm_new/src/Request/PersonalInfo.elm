module Request.PersonalInfo exposing(..)

import Http

import Data.PersonalInfo exposing(..)
import Request.Helpers as Helpers exposing (apiUrl)

post pid pInfo responseMsg =
    let 
        url = apiUrl ("/updatePersonalInfo/"++(toString pid)++"/")
    in
    Data.PersonalInfo.encode pInfo
        |> Helpers.post url responseMsg
