module Data.HeartReport exposing (..)
import Json.Encode exposing(string,int)
import Http
import Debug

import Constants exposing(constants)

type alias HeartReport = 
    { heart_text : String
    , heart_dt : String
    , heart_percentage : String
    , heart_remarks : String
    }

init: HeartReport
init = HeartReport (Maybe.withDefault "" (List.head constants.echocardiography_reports)) "" "" ""

encode : HeartReport -> Http.Body
encode heart =            
        Http.jsonBody <|
            Json.Encode.object
                [ ("heart_text", string heart.heart_text)
                , ("heart_dt", string heart.heart_dt)
                , ("heart_percentage", string heart.heart_percentage)
                , ("heart_remarks", string heart.heart_remarks)
                ]




