module Data.Patient exposing(..)

import Date
import Json.Decode as Decode exposing (..)
import Json.Encode as Encode
import Json.Decode.Pipeline exposing (decode, optional, optionalAt, required, requiredAt, hardcoded)
--import Date.Extra.Format exposing (isoDateString)
import Http
--import Material
--import DateTimePicker

import Data.Date exposing(addDays)
import Data.Bottle as Bottle
import Constants exposing(constants)
import Util exposing(stringToInt, decodeStringToInt)

type alias Patient =  { id: Int
                      , patient_name: String
                      , patient_age: String
                      , patient_card: String
                      , patient_therapy: String
                      , patient_frequency: String
                      , patient_initial_dose: Int
                      , patient_initial_dose_dt: Date.Date
                      , patient_maintenance_dose: Int
                      , patient_nacl_amount: Int
                      , dose_dt: Date.Date
                      , dose_dt_opened: Date.Date
                      , dose_dt_opened_expiry: Date.Date
                      , dose_weight: Int
                      , dose_amount: Int
                      , dose_remaining_dose: Int
                      , dose_remarks: String
                      , dose_next_appointment_dt: Date.Date
                      , dose_number: Int
                      , dose_number_cycle: Int
                      , heart_text: String
                      , heart_dt: Date.Date
                      , heart_percentage: String
                      , heart_remarks: String 
                      , dose_ago: Int 
                      , expiry_ago: Int 
                      , heart_ago: Int 
                      , user: String
                      , dt_now: Date.Date
                      , therapy_status: TherapyStatus
                      , therapy_dt: Date.Date
                      , therapy_reason: String
                      , therapy_remarks: String
                      , bottles: List Bottle.Bottle
                    }

init = 
                      { id= 0
                      , patient_name= ""
                      , patient_age= ""
                      , patient_card= ""
                      , patient_therapy= (List.head constants.chemotherapy_protocols) |> Maybe.withDefault ""
                      , patient_frequency= (List.head constants.injection_frequency) |> Maybe.withDefault ""
                      , patient_initial_dose= 0
                      , patient_initial_dose_dt= Date.fromTime 0
                      , patient_maintenance_dose= 0
                      , patient_nacl_amount= (List.head constants.nacl_amounts) |> Maybe.withDefault "" |> stringToInt
                      , dose_dt= Date.fromTime 0
                      , dose_dt_opened= Date.fromTime 0
                      , dose_dt_opened_expiry= Date.fromTime 0
                      , dose_weight= 0
                      , dose_amount= 0
                      , dose_remaining_dose= 0
                      , dose_remarks= ""
                      , dose_next_appointment_dt= Date.fromTime 0
                      , dose_number= 1
                      , dose_number_cycle= 1
                      , heart_text= (List.head constants.echocardiography_reports) |> Maybe.withDefault ""
                      , heart_dt= Date.fromTime 0
                      , heart_percentage= ""
                      , heart_remarks= ""
                      , dose_ago= 0
                      , expiry_ago= 0
                      , heart_ago= 0
                      , user= ""
                      , dt_now= Date.fromTime 0
                      , therapy_status= Active
                      , therapy_dt= Date.fromTime 0
                      , therapy_reason= ""
                      , therapy_remarks= ""
                      , bottles = []
                    }

type alias PatientSimple =  { id: Int
                      , patient_name: String
                      , patient_age: String
                      , patient_card: String
                      , dose_dt: Date.Date
                      , dose_dt_opened: Date.Date
                      , dose_dt_opened_expiry: Date.Date
                      , heart_dt: Date.Date
                      , dose_ago: Int 
                      , expiry_ago: Int 
                      , heart_ago: Int 
                      , therapy_status: TherapyStatus
                    }

type alias DoseFrequency =
  { restBetweenDoses : List Int
  , loops: Bool
  , initialMultiplier: Int
  , nextMultiplier: Int
  , finalMultiplier: Int
  }

frequencyToDoseFrequency freq =
  case freq of
    "一周一次" ->                    DoseFrequency [7] True 6 4 4
    "三周一次" ->                    DoseFrequency [21] True 8 6 6
    "一周一次 (三周用药，一周停药)" ->  DoseFrequency [7,7,14] True 6 4 4
    "12周三周一次， 后来一周一次"  ->   DoseFrequency [21,21,21,21,7] False 8 6 4
    "8周两周一次， 后来一周一次" ->     DoseFrequency [14,14,14,14,7] False 6 4 4
    _ -> DoseFrequency [] False 0 0 0

frequencyToShouldBeHidden freq = freq |> frequencyToDoseFrequency |> (\x -> ((not x.loops) || ((List.length x.restBetweenDoses) < 2)))

dfFrequencyToDays df dose_number_cycle dose_number=
  if    df.loops
  then  df.restBetweenDoses |> List.take dose_number_cycle |> List.reverse |> List.head |> Maybe.withDefault 0
  else  
    if (List.length df.restBetweenDoses) >= dose_number
    then df.restBetweenDoses |> List.reverse |> List.head  |> Maybe.withDefault 0
    else df.restBetweenDoses |> List.take dose_number |> List.head |> Maybe.withDefault 0

doseFrequencyToDays freq= frequencyToDoseFrequency freq |> dfFrequencyToDays

dfIncreaseDoseNumberCycle dose_number_cycle df  =
  let
    { restBetweenDoses, loops, initialMultiplier, nextMultiplier, finalMultiplier} = df
  in
    if loops
    then
      if (List.length restBetweenDoses) <= dose_number_cycle
      then 1
      else dose_number_cycle + 1
    else dose_number_cycle

increaseDoseNumberCycle dose_number_cycle freq= 
  freq |> frequencyToDoseFrequency |> (dfIncreaseDoseNumberCycle dose_number_cycle)

doseFrequencyToMultiplier df dose_number_cycle dose_number=
  if df.loops
  then  if   dose_number == 1
        then df.initialMultiplier
        else df.finalMultiplier
  else  if   (List.length df.restBetweenDoses) >= dose_number
        then df.nextMultiplier
        else df.finalMultiplier

type TherapyStatus = Active | TemporaryHalt | Halt | Finished


statusToString st =
  case st of
    Active        -> "治疗中"
    TemporaryHalt -> "暂停治疗"
    Halt          -> "终止"
    Finished      -> "完成所有治疗"


decodeTherapyStatus str =
  case str of
    "暂停治疗"      -> TemporaryHalt
    "终止"         -> Halt
    "完成所有治疗"  -> Finished
    _ -> Active

frequencyToMultiplier frequency =
  case frequency of
    "三周一次" -> constants.multiplier.maintenance.triweekly
    "一周一次" -> constants.multiplier.maintenance.weekly
    "一周一次 (三周用药，一周停药)" -> constants.multiplier.maintenance.weekly
    _ -> 0

decodeAgo dt_now plus invert =
    Data.Date.decoder
    |> Decode.map (\dt -> 
        ((Date.toTime dt_now) - ((Date.toTime dt) + plus))
            |> (\x -> x/ (24*60*60*1000))
            |> floor 
            |> if invert then (\x -> -x) else (\x-> x)
        )

    --|> Decode.map (\dt -> ((dt / (24*60*60*1000)) |> floor))




--expiry_days = (patient.dose_dt_opened + timedelta(days=config.drug_shelf_life) ) - timezone.now()
--dose_ago dt_now= timezone.now() - patient.dose_dt
--heart_ago = timezone.now() - patient.heart_dt

patientDecoder : Date.Date -> Decoder Patient
patientDecoder dt_now =
    decode Patient
        |> optional "id" int 0
        |> required "patient_name" string
        |> required "patient_age" string
        |> required "patient_card" string
        |> required "patient_therapy" string
        |> required "patient_frequency" string
        |> required "patient_initial_dose" decodeStringToInt
        |> required "patient_initial_dose_dt" Data.Date.decoder
        |> required "patient_maintenance_dose" decodeStringToInt
        |> required "patient_nacl_amount" decodeStringToInt
        |> required "dose_dt" Data.Date.decoder
        |> required "dose_dt_opened" Data.Date.decoder
        --|> required "dose_dt_opened" Data.Date.decoder
        |> required "dose_dt_opened" (Data.Date.decoder |> Decode.map (addDays constants.drug_shelf_life_days))
        |> required "dose_weight" decodeStringToInt
        |> required "dose_amount" decodeStringToInt
        |> required "dose_remaining_dose" decodeStringToInt
        |> optional "dose_remarks" string ""
        |> required "dose_next_appointment_dt" Data.Date.decoder
        |> required "dose_number" decodeStringToInt
        |> required "dose_number_cycle" decodeStringToInt
        |> required "heart_text" string 
        |> required "heart_dt" Data.Date.decoder 
        |> required "heart_percentage" string 
        |> optional "heart_remarks" string ""
        |> required "dose_next_appointment_dt" (decodeAgo dt_now 0 True)
        |> required "dose_dt_opened" (decodeAgo dt_now constants.drug_shelf_life_days True)
        |> required "heart_dt" (decodeAgo dt_now constants.heart_report_frequency True)
        |> optional "user" string ""
        |> hardcoded dt_now
        |> optional "therapy_status" (Decode.map decodeTherapyStatus Decode.string) Active
        |> optional "therapy_dt" Data.Date.decoder (Date.fromTime 0)
        |> optional "therapy_reason" string ""
        |> optional "therapy_remarks" string ""
        |> hardcoded []

encode : Patient -> Http.Body
encode patient_  =            
    let
        patient =     { patient_ | patient_initial_dose_dt= Data.Date.dateToString patient_.patient_initial_dose_dt
                      , dose_dt= Data.Date.dateToString patient_.dose_dt
                      , dose_dt_opened= Data.Date.dateToString patient_.dose_dt_opened
                      , dose_dt_opened_expiry= Data.Date.dateToString patient_.dose_dt_opened_expiry
                      , dose_next_appointment_dt= Data.Date.dateToString patient_.dose_next_appointment_dt
                      , heart_dt= Data.Date.dateToString patient_.heart_dt
                      , dt_now= Data.Date.dateToString patient_.dt_now
                      , therapy_status= statusToString patient_.therapy_status
                      , therapy_dt= Data.Date.dateToString patient_.therapy_dt
                      }
    in
        Http.jsonBody <|
            Encode.object
                [ ("patient_name", Encode.string patient.patient_name)
                , ("patient_age", Encode.string patient.patient_age)
                , ("patient_card", Encode.string patient.patient_card)
                , ("patient_therapy", Encode.string patient.patient_therapy)
                , ("patient_frequency", Encode.string patient.patient_frequency)
                , ("patient_initial_dose", Encode.int patient.patient_initial_dose)
                , ("patient_initial_dose_dt", Encode.string patient.patient_initial_dose_dt)
                , ("patient_maintenance_dose", Encode.int patient.patient_maintenance_dose)
                , ("patient_nacl_amount", Encode.int patient.patient_nacl_amount)
                , ("dose_dt", Encode.string patient.dose_dt)
                , ("dose_dt_opened", Encode.string patient.dose_dt_opened)
                , ("dose_weight", Encode.int patient.dose_weight)
                , ("dose_amount", Encode.int patient.dose_amount)
                , ("dose_remaining_dose", Encode.int patient.dose_remaining_dose)
                , ("dose_remarks", Encode.string patient.dose_remarks)
                , ("dose_next_appointment_dt", Encode.string patient.dose_next_appointment_dt)
                , ("dose_number", Encode.int patient.dose_number)
                , ("dose_number_cycle", Encode.int patient.dose_number_cycle)
                , ("heart_text", Encode.string patient.heart_text)
                , ("heart_dt", Encode.string patient.heart_dt)
                , ("heart_percentage", Encode.string patient.heart_percentage)
                , ("heart_remarks", Encode.string patient.heart_remarks)
                , ("therapy_status", Encode.string patient.therapy_status)
                , ("therapy_dt", Encode.string patient.therapy_dt)
                , ("therapy_reason", Encode.string patient.therapy_reason)
                , ("therapy_remarks", Encode.string patient.therapy_remarks)
                , ("bottles", Bottle.encodeList patient.bottles)
                ]

patientSimpleDecoder : Date.Date -> Decoder PatientSimple
patientSimpleDecoder dt_now =
    decode PatientSimple
        |> optional "id" int 0
        |> required "patient_name" string
        |> required "patient_age" string
        |> required "patient_card" string
        |> required "dose_dt" Data.Date.decoder
        |> required "dose_dt_opened" Data.Date.decoder
        |> required "dose_dt_opened" (Data.Date.decoder |> Decode.map (addDays 28))
        |> required "heart_dt" Data.Date.decoder 
        |> required "dose_dt" (decodeAgo dt_now 0 False)
        |> required "dose_dt_opened" (decodeAgo dt_now constants.drug_shelf_life True)
        |> required "heart_dt" (decodeAgo dt_now 0 False)
        |> optional "therapy_status" (Decode.map decodeTherapyStatus Decode.string) Active

