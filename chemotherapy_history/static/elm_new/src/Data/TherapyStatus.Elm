module Data.TherapyStatus exposing (..)
import Json.Encode exposing(string,int)
import Http
import Debug

import Constants exposing(constants)

type alias TherapyStatus = 
    { therapy_status: String
    , therapy_dt: String
    , therapy_reason: String
    , therapy_remarks: String
    }

init: TherapyStatus
init = TherapyStatus (constants.therapy_states |> List.head |> Maybe.withDefault "") "" "" ""

encode : TherapyStatus -> Http.Body
encode status =            
        Http.jsonBody <|
            Json.Encode.object
                [ ("therapy_status", string status.therapy_status)
                , ("therapy_dt", string status.therapy_dt)
                , ("therapy_reason", string status.therapy_reason)
                , ("therapy_remarks", string status.therapy_remarks)
                ]





