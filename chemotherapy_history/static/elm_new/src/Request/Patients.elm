module Request.Patients exposing(..)

import Data.Patients as Patients exposing (patientsDecoder)
import Http
import Debug
import Json.Decode as Decode
import Json.Encode as Encode

import Request.Helpers exposing (apiUrl)
import Util exposing ((=>))

apiEndpoint = apiUrl "/patients/"

get dt_now=  
    let d = (Debug.log apiEndpoint)
    in
    (Http.get apiEndpoint (patientsDecoder dt_now))