module Request.Patient exposing(..)

import Data.Patient exposing (Patient, patientDecoder)
import Http
import Debug
import Json.Decode as Decode
import Json.Encode as Encode

import Request.Helpers as Helpers exposing (apiUrl)
import Util exposing ((=>))

apiEndpoint p = apiUrl ("/patient/" ++ (toString p) ++ "/")

get p dt_now =  
   (Http.get (apiEndpoint p) (patientDecoder dt_now))

post patient responseMsg =
    let 
        url = apiUrl ("/newpatient/")
    in
    Data.Patient.encode patient
        |> Helpers.post url responseMsg
