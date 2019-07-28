module Data.PersonalInfo exposing (..)
import Json.Encode exposing(string,int)
import Http
import Debug

import Constants exposing (constants)

type alias PersonalInfo = 
    { patient_name: String
    , patient_age: String
    , patient_card: String
    , patient_therapy: String
    , patient_frequency: String
    , patient_initial_dose_dt: String
    , patient_initial_dose: String
    , patient_maintenance_dose: String
    , patient_nacl_amount: String
}

init = PersonalInfo "" "0" "0" "" "" "" "0" "0" "0"

encode : PersonalInfo -> Http.Body
encode pInfo =
    let
        d = Debug.log (toString pInfo)
            
    in
            
    Http.jsonBody <|
        Json.Encode.object
            [ ("patient_name", string pInfo.patient_name)
            , ("patient_age", string pInfo.patient_age)
            , ("patient_card", string pInfo.patient_card)
            , ("patient_therapy", string pInfo.patient_therapy)
            , ("patient_frequency", string pInfo.patient_frequency)
            , ("patient_initial_dose_dt", string pInfo.patient_initial_dose_dt)
            , ("patient_initial_dose", string pInfo.patient_initial_dose)
            , ("patient_maintenance_dose", string pInfo.patient_maintenance_dose)
            , ("patient_nacl_amount", string pInfo.patient_nacl_amount)
            ]




