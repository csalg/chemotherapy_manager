module Data.Patients exposing(..)

import Date
import Json.Decode as Decode exposing (..)
import Json.Decode.Pipeline exposing (decode, optional, optionalAt, required, requiredAt, hardcoded)
--import Date.Extra.Format exposing (isoDateString)
import Http
--import Material
--import DateTimePicker

import Data.Date
import Data.Patient exposing(PatientSimple,patientSimpleDecoder)
import Constants exposing(constants)


type alias Patients =  List PatientSimple

patientsDecoder : Date.Date -> Decoder Patients
patientsDecoder dt_now =
  (Decode.list (patientSimpleDecoder dt_now))