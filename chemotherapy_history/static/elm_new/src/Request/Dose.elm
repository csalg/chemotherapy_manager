module Request.Dose exposing(..)

import Http

import Data.Dose exposing(..)
import Request.Helpers as Helpers exposing (apiUrl)

post pid dose responseMsg =
    let url = apiUrl ("/updateDoseReport/"++(toString pid)++"/")
    in
    encode dose
        |> Helpers.post url responseMsg

get pid dt_now =  
    let url = apiUrl ("/patient/"++(toString pid)++"/doseHistory/5")
    in
        (Http.get url (decodeList dt_now))