module Views.PatientForms.PersonalInfo exposing (..)

import Dict
import Http
import Html exposing(..)
import Html.Attributes exposing(..)
import Html.Events exposing(..)
import HttpBuilder

import Bootstrap.Button as Button

import Data.Date
import Util exposing((=>),debug)
import Views.PatientForms.Base as Base exposing (..)
import Constants exposing (constants)
import Data.PersonalInfo exposing(PersonalInfo)
import Data.DjangoResponse as DjangoResponse
import Request.PersonalInfo exposing(post)
import Route

type alias Model  = 
    { model: PersonalInfo
    , fc: Dict.Dict String (FormControl Msg)
    , id: Maybe Int
    , submitted: Bool
    , notifications: String
    , error: String
    , endRoute: Route.Route

    }

type Msg = 
      Nope 
    | FormControlMsg Base.Msg 
    | Submit 
    | SubmitHttp (Result Http.Error DjangoResponse.DjangoResponse)

    | PatientNameChanged String
    | PatientAgeChanged String
    | PatientCardChanged String
    | PatientTherapyChanged String
    | PatientFrequencyChanged String
    | PatientInitialDoseChanged String
    | PatientInitialDoseDTChanged String
    | PatientMaintenanceDoseChanged String
    | PatientNaclChanged String

fcs =
  Dict.fromList [ ("patient_name", {formControlDefault | fieldName="patient_name", labelText="姓名：", order=1})
        , ("patient_age", {formControlDefault | fieldName="patient_age", labelText="年龄： ", max=120, inputType = Inpt "number", order=2})
        , ("patient_card", {formControlDefault | fieldName="patient_card", labelText="磁卡号：", order=3})
        , ("patient_therapy", {formControlDefault | fieldName="patient_therapy", labelText="化疗方案：", inputType = OptionsInput, order=4, options=constants.chemotherapy_protocols})
        , ("patient_frequency", {formControlDefault | fieldName="patient_frequency", labelText="剂量频率：", inputType = OptionsInput, order=5, options=constants.injection_frequency})
        , ("patient_nacl_amount", {formControlDefault | fieldName="patient_nacl_amount", labelText="氯化钠注射液(ml)", inputType = OptionsInput, options=constants.nacl_amounts,  order=6, width=3})
        , ("patient_initial_dose_dt", {formControlDefault | fieldName="patient_initial_dose_dt", labelText="首次剂量时期", inputType = DateInput, order=8, width=4})
        , ("dose_weight", {formControlDefault | fieldName="dose_weight"
                          , labelText="体重(kg)： "
                          , min=30
                          , max=130
                          , inputType = Inpt "number"
                          , order=7
                          , width=2
            })
        , ("patient_initial_dose", {formControlDefault | fieldName="patient_initial_dose", labelText="首次剂量", inputType = Inpt "number", order=9, width=3})
        , ("patient_maintenance_dose", {formControlDefault | fieldName="patient_maintenance_dose", labelText="维持剂量", inputType = Inpt "number", order=10, width=3})
      --, inputArgs=[(onInput (\val-> FormControlMsg (WeightChange val)))]
        ]
init: Model
init = Model Data.PersonalInfo.init fcs Nothing False "" "" Route.Patients

initWithValues patient id endRoute=
    let new_fcs = 
        init
            |> appendActions "patient_therapy" (manualInputAction "patient_therapy" FormControlMsg)
            |> makeDisplayOnly "patient_therapy" True
            |> appendActions "patient_frequency" (manualInputAction "patient_frequency" FormControlMsg)
            |> makeDisplayOnly "patient_frequency" True
            |> appendActions "patient_initial_dose_dt" (manualInputAction "patient_initial_dose_dt" FormControlMsg)
            |> makeDisplayOnly "patient_initial_dose_dt" True
            |> removeField "dose_weight"

        pInfo = 
            { patient_name = patient.patient_name
            , patient_age = patient.patient_age
            , patient_card = patient.patient_card
            , patient_therapy = patient.patient_therapy
            , patient_frequency = patient.patient_frequency
            , patient_initial_dose_dt = (Data.Date.dateToString patient.patient_initial_dose_dt)
            , patient_initial_dose = toString patient.patient_initial_dose
            , patient_maintenance_dose = toString patient.patient_maintenance_dose
            , patient_nacl_amount = toString patient.patient_nacl_amount
            }
    in
        Model pInfo new_fcs.fc (Just id) False "" "" endRoute

initNewPatient =
    init
    --|>

view model = Base.view model.fc

viewAsForm model = 
    let
        model_with_vals = model
            |> appendInputArgs "patient_name" [value model.model.patient_name, onInput PatientNameChanged]
            |> appendInputArgs "patient_age" [value model.model.patient_age, onInput PatientAgeChanged]
            |> appendInputArgs "patient_card" [value model.model.patient_card, onInput PatientCardChanged]
            |> appendInputArgs "patient_therapy" [value model.model.patient_therapy, onInput PatientTherapyChanged]
            |> appendInputArgs "patient_frequency" [value model.model.patient_frequency, onInput PatientFrequencyChanged]
            |> appendInputArgs "patient_initial_dose_dt" [value model.model.patient_initial_dose_dt, onInput PatientInitialDoseDTChanged]
            |> appendInputArgs "patient_initial_dose" [value model.model.patient_initial_dose, onInput PatientInitialDoseChanged]
            |> appendInputArgs "patient_maintenance_dose" [value model.model.patient_maintenance_dose, onInput PatientMaintenanceDoseChanged]
            |> appendInputArgs "patient_nacl_amount" [value model.model.patient_nacl_amount, onInput PatientNaclChanged]
    in      
        --div []
        --[ Base.view fcs
        --, text (model |> toString)
        --]
        Html.form [method "post", onSubmit Submit]
            [ Base.view model_with_vals.fc
            , div [] [text model.error]
            , div [] [p [] [text model.notifications]]
            , hr [] []
            , debug (model_with_vals |> toString)
            ]

buttons =  Base.buttons Submit

update msg model =
    let
        getPersonalInfo = model.model
            
    in
            
    case msg of
        FormControlMsg subMsg -> Base.update subMsg model => Cmd.none
        Submit -> model => (post (Maybe.withDefault 0 model.id) model.model SubmitHttp)
        SubmitHttp (Err err) -> {model | error = toString err} => Cmd.none
        SubmitHttp (Ok serverMsg) -> {model | notifications = DjangoResponse.toString serverMsg, submitted=True} => Route.modifyUrl model.endRoute

        PatientNameChanged val -> { model | model = {getPersonalInfo | patient_name=val } } => Cmd.none
        PatientAgeChanged val -> { model | model = {getPersonalInfo | patient_age=val } } => Cmd.none
        PatientCardChanged val -> { model | model = {getPersonalInfo | patient_card=val } } => Cmd.none
        PatientTherapyChanged val -> { model | model = {getPersonalInfo | patient_therapy=val } } => Cmd.none
        PatientFrequencyChanged val -> { model | model = {getPersonalInfo | patient_frequency=val } } => Cmd.none
        PatientInitialDoseChanged val -> { model | model = {getPersonalInfo | patient_initial_dose=val } } => Cmd.none
        PatientInitialDoseDTChanged val -> { model | model = {getPersonalInfo | patient_initial_dose_dt=val } } => Cmd.none
        PatientMaintenanceDoseChanged val -> { model | model = {getPersonalInfo | patient_maintenance_dose=val } } => Cmd.none
        PatientNaclChanged val -> { model | model = {getPersonalInfo | patient_nacl_amount=val } } => Cmd.none
        --PatientNameChanged pname -> { model | model = {getPersonalInfo | patient_name=pname } } => Cmd.none
        --PatientNameChanged pname -> { model | model = {getPersonalInfo | patient_name=pname } } => Cmd.none
        --PatientNameChanged pname -> { model | model = {getPersonalInfo | patient_name=pname } } => Cmd.none
        _ -> model => Cmd.none