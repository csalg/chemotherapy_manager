module Page.NewPatient exposing (..)

import Date
import Dict
import Html exposing(..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Task
import Time

import Material.Options as Options
import Material.Toggles as Toggles
import Material

import Styles exposing (..)
import Util exposing ((=>), debug, stringToInt, onChange, withMsg_)
import Request.External
import Data.Patient as Patient
import Data.Bottle as Bottle
import Data.Date
import Constants exposing (constants)
import Views.PatientForms.Base as BaseForm exposing (..)
import Views.PatientForms.Dose as DoseForm exposing(setBottlesFromAlgo, calculateNextAppointment_, calculateExpiry, setRemaining)
import Views.PatientForms.Heart as HeartForm
import Views.PatientForms.PersonalInfo as PersonalInfoForm
import Views.PatientForms.TherapyStatus as TherapyStatusForm
import Views.Bottle as BottleView
import Data.DjangoResponse as DjangoResponse
import Request.Patient exposing(post)
import Route

-- MODEL --

type alias Model = 
    { mdl : Material.Model
    , personal: Dict.Dict String (BaseForm.FormControl Msg)
    , dose: Dict.Dict String (BaseForm.FormControl Msg)
    , heart: Dict.Dict String (BaseForm.FormControl Msg)
    --, frequency: String
    , weight: Int
    , initial_dose: Int
    , maintenance_dose: Int
    , dose_amount: Int
    --, bottles: List Bottle.Bottle
    , firstTime: Bool
    , allowAuto: Bool
    , dt_now: Date.Date
    , dose_dt_opened: Date.Date
    , dose_dt_opened_expiry: Date.Date
    , model: Patient.Patient
    , error: String
    , previous_remaining: Int
    , previous_opened_dt: Date.Date
    , error: String
    , notifications: String
    }

init = 
    let
        pfc = PersonalInfoForm.fcs
        dfc = DoseForm.fcNewPatient
        hfc = HeartForm.fc 
    in
        (Model Material.model pfc dfc hfc  0 0 0 0 True True (Date.fromTime 0) (Date.fromTime 0) (Date.fromTime 0) Patient.init "" 440 (Date.fromTime 0) "" "")

initTask = Task.perform SetDTNow Time.now

firstTimeFC =
      Dict.fromList 
          [ ("previous_remaining", {formControlDefault | fieldName="previous_remaining"
              , labelText="上次剩余剂量"
              , min=00
              , max=440
              , inputType = Inpt "number"
              , order=-2
              })
          , ("previous_opened_dt", {formControlDefault | fieldName="previous_opened_dt"
              , labelText="上次药开封日期"
              , inputType=DateInput
              , order=-1
              })
          , ("dose_number", {formControlDefault | fieldName="dose_number"
              , labelText="第几次用药"
              , inputType = Inpt "number"
              , order=-3
              })
          ]

modifyPersonal recordModifierFunction fieldName model  =
  let
    entry = Dict.get fieldName model.personal
  in
    case entry of
        Just record -> {model | personal = (Dict.insert fieldName (record |> recordModifierFunction) model.personal)}
        Nothing -> model

modifyDose recordModifierFunction fieldName model  =
  let
    entry = Dict.get fieldName model.dose
  in
    case entry of
        Just record -> {model | dose = (Dict.insert fieldName (record |> recordModifierFunction) model.dose)}
        Nothing -> model

modifyHeart recordModifierFunction fieldName model  =
  let
    entry = Dict.get fieldName model.heart
  in
    case entry of
        Just record -> {model | heart = (Dict.insert fieldName (record |> recordModifierFunction) model.heart)}
        Nothing -> model

inputArgs args record = {record | inputArgs = args}
value_ args record = 
    {record | inputArgs = (record.inputArgs++[value args])}

hidden args record = 
    {record | hidden = args}

actions args record = 
    {record | actions = args}
displayOnly args record = 
    {record | displayOnly = args}
toggleDisplayOnly record = 
    {record | displayOnly = not record.displayOnly}
changeActions args record = {record | actions = args}
manualInputAction fieldName msg = [Action "" "checkbox" "直接输入"  (\val -> msg fieldName val)]

initialFromWeight weight frequency =
    (Patient.frequencyToDoseFrequency frequency).initialMultiplier * weight

maintenanceFromWeight weight frequency =
    (Patient.frequencyToDoseFrequency frequency).nextMultiplier * weight

-- UPDATE --

type Msg = Nothing_ 
    | DoseAmountChanged String
    | DoseDTOpenedChanged String
    | FirstTimeChanged
    | Mdl (Material.Msg Msg)
    | SetDTNow Time.Time
    --| BaseFormMsg (BaseForm.Msg)
    | AllowManualInputDose String Bool
    | AllowManualInputHeart String Bool
    | AllowManualInputPersonal String Bool

    | ValChanged String String
    | Submit
    | SubmitHttp (Result Http.Error DjangoResponse.DjangoResponse)




update msg model =
  let getModel = model.model
  in
    case msg of
        --Manual input controllers
        AllowManualInputDose fieldName checked -> 
            model
                |> modifyDose (displayOnly (not checked)) fieldName
            => Cmd.none

        AllowManualInputHeart fieldName checked -> 
            model
                |> modifyHeart (displayOnly (not checked)) fieldName
            => Cmd.none

        AllowManualInputPersonal fieldName checked -> 
            model
                |> modifyPersonal (displayOnly (not checked)) fieldName
            => Cmd.none

        --Mdl boilerplate
        Mdl msg_ -> 
          Material.update Mdl msg_ model

        --PersonalInfo
        ValChanged key val -> 
          let new_model =
            case key of
              "patient_name" -> {model | model = {getModel | patient_name = val}}
              "patient_age" -> {model | model = {getModel | patient_age = val}}
              "patient_card" -> {model | model = {getModel | patient_card = val}}
              "patient_therapy" -> {model | model = {getModel | patient_therapy = val}}
              "patient_frequency" -> 
                {model | model = {getModel | patient_frequency = val}}
                  |> calculateNextAppointment
                  |> calculateDosesAccordingToWeight
                  |> inheritDoseAmount
                  |> calculateExpiry
                  |> setBottlesFromAlgo
                  |> setRemaining

              "patient_initial_dose" -> 
                {model | model = {getModel | patient_initial_dose = val |> stringToInt}}
                  |> inheritDoseAmount
                  |> setBottlesFromAlgo
              
              "patient_initial_dose_dt" -> 
                let val_ = val |> Data.Date.stringToDate
                in
                  {model | model = {getModel | patient_initial_dose_dt = val_
                                    , dose_dt = val_ 
                                    , heart_dt = val_ 
                                    }
                          , previous_opened_dt = val_
                        }
                    |> firstTimeChangedFromDate

              "patient_maintenance_dose" -> 
                {model | model = {getModel | patient_maintenance_dose = val |> stringToInt}}
                  |> inheritDoseAmount
                  |> setBottlesFromAlgo
              
              "patient_nacl_amount" -> {model | model = {getModel | patient_nacl_amount = val |> stringToInt}}
              "dose_dt" -> 
                {model | model = {getModel | dose_dt = val |> Data.Date.stringToDate}}
                  |> setBottlesFromAlgo
                  |> calculateNextAppointment
                  |> setOpenedDTFromDoseDT

              "dose_dt_opened" -> 
                {model | model = {getModel | dose_dt_opened = val |> Data.Date.stringToDate}}
                  |> calculateExpiry

              "dose_weight" -> 
                {model | model = {getModel | dose_weight = val |> stringToInt}}
                  |> calculateDosesAccordingToWeight
                  |> inheritDoseAmount
                  |> setBottlesFromAlgo
                  |> setRemaining
              
              "dose_amount" -> {model | model = {getModel | dose_amount = val |> stringToInt}}
                |> calculateDosesAccordingToWeight
                |> setBottlesFromAlgo
                |> setRemaining

              "dose_remaining_dose" -> {model | model = {getModel | dose_remaining_dose = val |> stringToInt}}
              "dose_remarks" -> {model | model = {getModel | dose_remarks = val}}
              "dose_next_appointment_dt" -> {model | model = {getModel | dose_next_appointment_dt = val |> Data.Date.stringToDate}}
              "dose_number" -> {model | model = {getModel | dose_number = val |> stringToInt}}
              "dose_number_cycle" -> {model | model = {getModel | dose_number_cycle = val |> stringToInt}}
              "heart_text" -> {model | model = {getModel | heart_text = val}}
              "heart_dt" -> {model | model = {getModel | heart_dt = val |> Data.Date.stringToDate}}
              "heart_percentage" -> {model | model = {getModel | heart_percentage = val }}
              "heart_remarks" -> {model | model = {getModel | heart_remarks = val}}
              "therapy_dt" -> {model | model = {getModel | therapy_dt = val |> Data.Date.stringToDate}}
              "therapy_reason" -> {model | model = {getModel | therapy_reason = val}}
              "therapy_remarks" -> {model | model = {getModel | therapy_remarks = val}}
              "previous_remaining" -> 
                {model | previous_remaining = val |> stringToInt}
                  |> setBottlesFromAlgo
                  |> setRemaining
              
              "previous_opened_dt" -> 
                {model | previous_opened_dt = val |> Data.Date.stringToDate}
                  |> setBottlesFromAlgo
                  |> setRemaining
              
              _ -> {model | error = (key++" not Found for. val is "++val)}
          in new_model => Cmd.none

        FirstTimeChanged ->
            model |> firstTimeChanged (not model.firstTime) |> inheritDoseAmount
             => Cmd.none

        DoseAmountChanged val -> 
            {model | dose_amount=stringToInt val} 
                --|> modifyDose (value_ val) "dose_amount"
            => Cmd.none

        DoseDTOpenedChanged dt_ ->
            model
                --|> doseDTChanged dt_
            => Cmd.none
        
        SetDTNow t ->
            {model | dt_now=Date.fromTime t 
                    , previous_opened_dt = Date.fromTime t 
                    , model = {getModel | patient_initial_dose_dt= Date.fromTime t
                                , dose_dt = Date.fromTime t
                                , dose_dt_opened = Date.fromTime t
                                , dose_dt_opened_expiry = Date.fromTime t
                                , heart_dt = Date.fromTime t 
                                , therapy_dt = Date.fromTime t 
                      }
            }
                  |> calculateDosesAccordingToWeight
                  |> calculateNextAppointment
                  |> inheritDoseAmount
                  |> calculateExpiry
                  |> setBottlesFromAlgo
                  |> setRemaining

              --|> modifyDose (value_ (model.dt_now |> Data.Date.dateToString)) "dose_dt"
              --|> modifyDose (value_ (model.dt_now |> Data.Date.dateToString)) "dose_dt_opened"
              --|> modifyHeart (value_ (model.dt_now |> Data.Date.dateToString)) "heart_dt"

              --|> firstTimeChangedFromDate
            => Cmd.none

        --DoseDTOpenedChanged val -> 
        --    {model | dose_dt_opened = val, dose_dt_opened_expiry = ((Data.Date.addDaysFromString constants.drug_shelf_life_days val) |> Data.Date.dateToString) }} 
        --    => Cmd.none

        Submit -> model => (post model.model SubmitHttp)
        SubmitHttp (Err err) -> {model | error = toString err} => Cmd.none
        SubmitHttp (Ok serverMsg) ->
          case serverMsg of
          DjangoResponse.Err val     -> {model | notifications = val} => Cmd.none
          DjangoResponse.Success val -> {model | notifications = val} => Route.modifyUrl Route.Patients
        _ -> model => Cmd.none



calculateDosesAccordingToWeight model =
  let
    frequencyAsRF     = model.model.patient_frequency |> Patient.frequencyToDoseFrequency
    initial_dose      = frequencyAsRF.initialMultiplier * model.model.dose_weight
    maintenance_dose  = frequencyAsRF.nextMultiplier * model.model.dose_weight
    getModel = model.model
  in
    if not model.allowAuto then model else
    {model | model = {getModel  | patient_initial_dose = initial_dose
                                , patient_maintenance_dose = maintenance_dose
                    }
      }
inheritDoseAmount model =
  let getModel = model.model
  in
    if not model.allowAuto then model else
    {model | model = {getModel  | dose_amount = if model.firstTime then getModel.patient_initial_dose else getModel.patient_maintenance_dose}}

getModel model = model.model

calculateNextAppointment model =  calculateNextAppointment_ model.model.patient_frequency model
--calculateNextAppointment_  model = 
--  let
--    frequencyAsRF     = frequency |> Patient.frequencyToDoseFrequency
--    days              = Patient.doseFrequencyToDays frequencyAsRF 1 1 
--    next_appointment  = Data.Date.addDays days model.model.dose_dt
--    getModel = model.model
--  in
--    if not model.allowAuto then model else
--    {model | model = {getModel  | dose_next_appointment_dt = next_appointment
--                    }
--      }

setOpenedDTFromDoseDT model =
  let
    getModel = model.model
  in
    {model | model = {getModel | dose_dt_opened = getModel.dose_dt}}


--setBottlesFromAlgo model =
--  let
--    bottles = Bottle.calculateBottles model.model.dose_amount model.previous_remaining model.previous_opened_dt model.model.dose_dt 
--  in
--    {model | bottles = bottles}

firstTimeChangedFromDate model =
    firstTimeChanged ((((Date.toTime model.dt_now) - (Date.toTime model.model.patient_initial_dose_dt))) < 24*60*60*1000) model

firstTimeChanged val model =
    if val
    then {model |  dose_amount = model.initial_dose, firstTime=val}

    else {model |  dose_amount = model.maintenance_dose, firstTime=val} 
        |> modifyDose (value_ (model.maintenance_dose |> toString)) "dose_amount"

accordingToWeight weight_ model =
    let
         (new_maintenance, new_initial) =
            (maintenanceFromWeight  weight_ model.model.patient_frequency)
            => (initialFromWeight  weight_ model.model.patient_frequency)     
     in  
        {model | weight=(weight_), initial_dose = new_initial, maintenance_dose = new_maintenance} 
            |> modifyPersonal (value_ (new_maintenance |> toString)) "patient_maintenance_dose"
            |> modifyPersonal (value_ (new_initial |> toString)) "patient_initial_dose"
            |> modifyDose (value_ (new_maintenance |> toString)) "dose_amount"

doseDTChanged dt_ model=
            {model | dose_dt_opened = Data.Date.stringToDate dt_, dose_dt_opened_expiry = Data.Date.addDaysFromString constants.drug_shelf_life_days dt_}

    --case msg of
        --PersonalInfoFormMsg subMsg -> 
            --let ( newModel, newCmd ) = PersonalInfoForm.update subMsg model.personal
            --in {model | personal = newModel} => Cmd.map PersonalInfoFormMsg newCmd
        --DoseFormMsg subMsg -> 
            --let ( newModel, newCmd ) = DoseForm.update subMsg model.dose
            --in {model | dose = newModel} => Cmd.map DoseFormMsg newCmd
        --HeartFormMsg subMsg ->
        --    let ( newModel, newCmd ) = HeartForm.update subMsg model.heart
        --    in {model | heart = newModel} => Cmd.map HeartFormMsg newCmd
-- VIEW --
withMsg = withMsg_ ValChanged

view model_ = 
  let 
    model = {model_ | personal = (withMsg model_.personal), heart = (withMsg model_.heart), dose = (withMsg model_.dose)}
            |>  modifyPersonal (value_ (model_.model.patient_initial_dose_dt |> Data.Date.dateToStringJS)) "patient_initial_dose_dt"
            |>  modifyPersonal (value_ (model_.model.patient_initial_dose |> toString)) "patient_initial_dose"
            |>  modifyPersonal (value_ (model_.model.patient_maintenance_dose |> toString)) "patient_maintenance_dose"
            |>  modifyDose (value_ (toString model_.model.dose_amount)) "dose_amount"
            |>  modifyDose (value_ (model_.model.dose_next_appointment_dt |> Data.Date.dateToStringJS)) "dose_next_appointment_dt"
            |>  modifyDose (value_ (model_.model.dose_dt |> Data.Date.dateToStringJS)) "dose_dt"
            |>  modifyDose (value_ (model_.model.dose_remaining_dose |> toString)) "dose_remaining_dose"
            |>  modifyDose (value_ (model_.model.dose_dt_opened |> Data.Date.dateToStringJS)) "dose_dt_opened"
            |>  modifyDose (value_ (model_.model.dose_dt_opened_expiry |> Data.Date.dateToString)) "dose_dt_opened_expiry"
            |>  modifyDose (hidden (Patient.frequencyToShouldBeHidden model_.model.patient_frequency)) "dose_number_cycle"
            |>  modifyHeart (value_ (model_.model.heart_dt |> Data.Date.dateToStringJS)) "heart_dt"
  in
    div [class "container", style (newPatientContainer++padding40) ] 
      [ h4 [style newPatientBigHeader] [ i [class "fas fa-user-plus", style newPatientBigHeaderIcon] [], text "新建患者"]
      , Html.form [method "post", onSubmit Submit]
          --[ div []
          --    [ Toggles.switch Mdl [0] model.mdl
          --          [ Options.onToggle FirstTimeChanged
          --          , Options.css     "color" "hsl(200,10%,41%)"
          --          , Options.css     "font-weight" "450"
          --          , Toggles.ripple
          --          , Toggles.value model.allowAuto
          --          ]
          --          [ text "允许系统自动算值" ]
          --    ]
          [ h5 [style newPatientHeader] [ i [class "far fa-address-card", style newPatientHeaderIcon] [], span [style newPatientHeaderText] [text " 基本信息"]]
          --, PersonalInfoForm.view model.personal
          , BaseForm.view model.personal
          , h5 [style newPatientHeader] [i [ class"fas fa-medkit", style newPatientHeaderIcon ] [], span [style newPatientHeaderText] [text " 用药信息"]]
          , div []
              [ Toggles.switch Mdl [1] model.mdl
                    [ Options.onToggle FirstTimeChanged
                    , Options.css     "color" "hsl(200,10%,41%)"
                    , Options.css     "font-weight" "450"
                    , Toggles.ripple
                    , Toggles.value model.firstTime
                    ]
                    [ text "是否第一次用药" ]
              ]
          ,   if model.firstTime 
              then text ""
              else BaseForm.view (withMsg firstTimeFC)
          , BaseForm.view model.dose
          , BottleView.view model.model.bottles
          , h5 [style newPatientHeader] [i [ class"fas fa-heartbeat", style newPatientHeaderIcon ] [], span [style newPatientHeaderText] [text " 使用前检查信息"]]
          , BaseForm.view model.heart
          , input [type_ "hidden", name "patient_maintenance_dose", value (model.maintenance_dose |> toString)] []
          , input [type_ "hidden", name "patient_initial_dose", value (model.initial_dose |> toString)] []
          , input [type_ "hidden", name "dose_amount", value (model.dose_amount |> toString)] []
          , span [] [text model.notifications]
          , span [] [text model.error]
          , div [style newPatientFooter]
              [ button [action "submit", class "btn btn-primary new-patient-button "] [i [class "fas fa-paper-plane new-patient-footer-icon "][], text " 提交"]
              ]
          , debug (toString model)
          ]
      ]
