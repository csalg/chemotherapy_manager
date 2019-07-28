module Data.Dose exposing (..)

import Date
import Json.Encode exposing(string,int)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline exposing (optional, optionalAt, required, requiredAt, hardcoded)

import Http
import Debug

import Data.Bottle as Bottle
import Data.Date exposing(addDays)
import Constants exposing(constants)
import Util exposing(stringToInt, decodeStringToInt)

type alias Dose = 
    { dose_dt: Date.Date
    , dose_weight: Int
    , dose_amount: Int
    , dose_remaining_dose: Int
    , dose_dt_opened: Date.Date
    , dose_dt_opened_expiry: Date.Date
    , dose_remarks: String
    , dose_next_appointment_dt: Date.Date
    , dose_number: Int
    , dose_number_cycle: Int
    , csrf: String
    , bottles: List Bottle.Bottle
    }

init: Dose
init = Dose (Date.fromTime 0) 0 0 0 (Date.fromTime 0) (Date.fromTime 0)  "" (Date.fromTime 0) 1 1 "" []

--valueOf dose_ =
--        dose =  { dose_ | dose_weight = dose_.dose_weight |> toString
--                        , dose_amount = dose_.dose_amount |> toString
--                        , dose_remaining_dose = dose_.dose_remaining_dose |> toString
--                        , dose_next_appointment_dt = dose_.dose_next_appointment_dt |> Data.Date.dateToString
--                        , dose_dt_opened = dose_.dose_dt_opened |> Data.Date.dateToString
--                        , dose_dt = dose_.dose_dt |> Data.Date.dateToString
--                        , dose_dt_opened_expiry = dose_.dose_dt_opened_expiry |> Data.Date.dateToString
--                }
--    "dose_dt"
--    "dose_weight"
--    "dose_amount"
--    "dose_remaining_dose"
--    "dose_dt_opened"
--    "dose_dt_opened_expiry"
--    "dose_remarks"
--    "dose_next_appointment_dt"
--    "dose_number"
--    "dose_number_cycle"
--    "dose_remarks"
--    "bottles"

--encode : Dose -> Http.Body

getValue dose_ str =            
    let
        dose =  { dose_ | dose_weight = dose_.dose_weight |> toString
                        , dose_amount = dose_.dose_amount |> toString
                        , dose_remaining_dose = dose_.dose_remaining_dose |> toString
                        , dose_next_appointment_dt = dose_.dose_next_appointment_dt |> Data.Date.dateToString
                        , dose_dt_opened = dose_.dose_dt_opened |> Data.Date.dateToString
                        , dose_dt = dose_.dose_dt |> Data.Date.dateToString
                        , dose_dt_opened_expiry = dose_.dose_dt_opened_expiry |> Data.Date.dateToString
                        , dose_number = dose_.dose_number |> toString
                        , dose_number_cycle = dose_.dose_number_cycle |> toString
                }
    in
        case str of
            "dose_dt" -> dose.dose_dt
            "dose_weight" -> dose.dose_weight
            "dose_amount" -> dose.dose_amount
            "dose_remaining_dose" -> dose.dose_remaining_dose
            "dose_dt_opened" -> dose.dose_dt_opened
            "dose_dt_opened_expiry" -> dose.dose_dt_opened_expiry
            "dose_remarks" -> dose.dose_remarks
            "dose_next_appointment_dt" -> dose.dose_next_appointment_dt
            "dose_number" -> dose.dose_number
            "dose_number_cycle" -> dose.dose_number_cycle
            _ -> ""

toChinese str =
    case str of
        "dose_amount" -> "剂量"
        "dose_weight" -> "体重"
        "dose_open_new" -> "是否开封新药"
        "dose_dt_opened" -> "开封新药日期"
        "dose_initial_dose" -> "首次用药时间"
        "patient_maintenance_dose" -> "维持使用"
        "dose_remaining_dose" -> "剩余剂量"
        "dose_dt_created" -> "记录日期"
        "dose_dt" -> "用药日期"
        "dose_remarks" -> "备注"
        "dose_number" -> "第几次用药"
        _ -> str

getValueJS dose_ str =  
    case str of
        "dose_next_appointment_dt" -> dose_.dose_next_appointment_dt |> Data.Date.dateToStringJS
        "dose_dt_opened" -> dose_.dose_dt_opened |> Data.Date.dateToStringJS
        "dose_dt" -> dose_.dose_dt |> Data.Date.dateToStringJS
        "dose_dt_opened_expiry" -> dose_.dose_dt_opened_expiry |> Data.Date.dateToStringJS
        _ -> getValue dose_ str

fieldsAsStr =
    [ "dose_dt"
    , "dose_weight"
    , "dose_amount"
    , "dose_remaining_dose"
    , "dose_dt_opened"
    , "dose_dt_opened_expiry"
    , "dose_remarks"
    , "dose_next_appointment_dt"
    , "dose_number"
    , "dose_remarks"
    , "dose_number_cycle"
    ]

encode_ dose_ =            
        Json.Encode.object
            ((List.map (\str -> (str, string (getValue dose_ str) )) fieldsAsStr)
            ++ [("bottles", Bottle.encodeList dose_.bottles)])

encode dose = (encode_ dose) |> Http.jsonBody

decode : Date.Date -> Decode.Decoder Dose
decode dt_now =
    Pipeline.decode Dose
        |> required "dose_dt" Data.Date.decoder
        |> required "dose_weight" decodeStringToInt
        |> required "dose_amount" decodeStringToInt
        |> required "dose_remaining_dose" decodeStringToInt
        |> required "dose_dt_opened" Data.Date.decoder
        |> required "dose_dt_opened" (Data.Date.decoder |> Decode.map (addDays constants.drug_shelf_life))
        |> required "dose_remarks" Decode.string
        |> required "dose_next_appointment_dt" Data.Date.decoder
        |> required "dose_number" decodeStringToInt
        |> required "dose_number_cycle" decodeStringToInt
        |> hardcoded ""
        |> hardcoded []


decodeList : Date.Date -> Decode.Decoder (List Dose)
decodeList dt_now =
  (Decode.list (decode dt_now))