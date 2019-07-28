
module Data.Date exposing (..)

import Date
import Date.Format
import Date.Extra.Format as DE exposing (isoTimeFormat)
import Date.Extra.Config.Config_es_es exposing (config)
import Debug
import String.Extra exposing (unquote, unsurround)
import Time

import Json.Decode as Decode exposing (..)
import Json.Decode.Pipeline exposing (decode, optional, optionalAt, required, requiredAt, hardcoded)

-- Serialization

decoder = 
  Decode.string
  |> Decode.map Date.fromString
  |> Decode.map (Result.withDefault (Date.fromTime 0))

stringToDate dtString =
    case Date.fromString(dtString) of
          Ok dt -> dt
          Err _ -> Date.fromTime(0)

--Formatters

dateToString dt = 
    (((DE.format config DE.isoDateFormat) dt) ++ " " ++ ((DE.format config DE.isoTimeFormat) dt))
        |> unquote
        |> unsurround "\""

--dateToStringJS dt = 
--    (((DE.format config DE.isoDateFormat) dt) ++ "T" ++ ((DE.format config DE.isoTimeFormat) dt))
--        |> unquote
--        |> unsurround "\""

dateToStringJS = Date.Format.format "%Y-%m-%dT%H:%M"


stringToDateToString dt = dt |> stringToDate |> dateToString

--Methods

addDays: number -> Date.Date -> Date.Date
addDays days dt = dt
                |> Date.toTime
                |> (\d -> d + days*24*60*60*1000)
                |> Date.fromTime

addDaysFromString days dtString = dtString
                                    |> stringToDate
                                    |> (addDays days)

isExpired dt dt_now  =
  let
    toTime = Date.toTime
    --d = Debug.log(dt)
  in  
    ( toTime dt ) < ( toTime dt_now )

--isExpiredDebug dt dt_now  =
--  let
--    toTime = Date.toTime
--    d = Debug.log(dt)
--  in  
--    "Dt_now: " ++ toString ( toTime dt_now ) ++ " / dt: " ++ toString ( toTime dt )