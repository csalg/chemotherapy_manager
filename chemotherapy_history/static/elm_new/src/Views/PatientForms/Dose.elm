module Views.PatientForms.Dose exposing (..)

import Date
import Dict
import Http
import Html exposing(..)
import Html.Attributes exposing(..)
import Html.Events exposing(..)
import HttpBuilder
import Round
import Task

import Bootstrap.Button as Button

import Constants exposing (constants)
import Data.DjangoResponse as DjangoResponse
import Data.Dose exposing(Dose, getValueJS, getValue)
import Data.Bottle as Bottle
import Data.Date exposing(stringToDate, addDays, dateToString)
import Data.Patient as Patient exposing(increaseDoseNumberCycle)
import Request.Dose exposing(post)
import Route
import Views.PatientForms.Base as Base exposing (..)
import Views.Bottle as BottleView
import Util exposing((=>), onChange, debug, stringToInt, withMsg_)

type alias Model  = 
    { model: Dose
    , fc: Dict.Dict String (FormControl Msg)
    , id: Maybe Int
    , submitted: Bool
    , notifications: String
    , error: String
    , previous_remaining: Int
    , patient_maintenance_dose: Int
    , previous_opened_dt: Date.Date
    , multiplier: Int
    , calculate_dose_algo: DoseAlgo
    , calculate_remaining_from_dose: Bool
    , frequency: String
    , dose_number_cycle: Int
    , endRoute: Route.Route
    }

single_bottle_dosage = constants.single_bottle_dosage

type DoseAlgo = FromMaintenance | FromWeight | Manual

type Msg =    
    Nope 
  | FormControlMsg Base.Msg 
  | Placeholder String -- useless
  -- Input change handlers
  | ValChanged String String
  --| DoseDTChanged String
  --| DoseWeightChanged String
  --| DoseAmountChanged String
  --| DoseRemainingDoseChanged String
  --| DoseDTOpenedChanged String
  --| DoseNextAppointmentDTChanged String
  --| DoseWeekChanged String
  -- Action handlers
  --| AccordingToMaintenance Bool
  --| AccordingToWeight Bool
  --| AllowDoseManualInput Bool
  -- API handlers
  | Submit
  | SubmitHttp (Result Http.Error DjangoResponse.DjangoResponse)

fc =
  Dict.fromList [ 
      ("dose_weight", {formControlDefault | fieldName="dose_weight"
          , labelText="体重(kg)： "
          , min=30
          , max=130
          , inputType = Inpt "number"
          , order=1
          , width = 3
          })

    , ("dose_amount", {formControlDefault | 
            fieldName="dose_amount"
          , labelText="剂量(mg)："
          , max=700
          , inputType = Inpt "number"
          , order=2
          , width = 3
          })

    , ("dose_previous_remaining_dose", {formControlDefault | fieldName="dose_previous_remaining_dose"
          , labelText="使用前剩余剂量(mg)："
          , max=440
          , inputType = Inpt "number"
          , order=3
          , width = 3
          })

    , ("dose_remaining_dose", {formControlDefault | fieldName="dose_remaining_dose"
          , labelText="使用后剩余剂量(mg)："
          , max=440
          , inputType = Inpt "number"
          , order=4
          , width = 3
          , displayOnly=True
          })

    , ("dose_dt_opened", {formControlDefault | 
            fieldName="dose_dt_opened", labelText="开封日期："
          , inputType=DateInput
          , order=7
          , width=6
          , disabled=False
          , displayOnly=False
          })

    , ("dose_dt_opened_expiry", {formControlDefault | fieldName="dose_dt_opened_expiry", labelText="药到期：", disabled=True, displayOnly=True, order=8, width=6})
    , ("dose_dt", {formControlDefault | fieldName="dose_dt"
          , inputType=DateInput
          , options=["1","2","3"]
          , labelText="用药日期"
          , width=6
          , order=5
          , displayOnly=False
          , disabled=False
          })
    , ("dose_next_appointment_dt", {formControlDefault | fieldName="dose_next_appointment_dt"
          , inputType=DateInput
          , labelText="下次用药日期:"
          , width=6
          , order=6
          , displayOnly=False
          , disabled=False
          })
    , ("dose_number", {formControlDefault | fieldName="dose_number"
          , inputType = Inpt "number"
          , labelText="第几次用药"
          , width=4
          , order=10
          , displayOnly=False
          , disabled=False
          })
    , ("dose_number_cycle", {formControlDefault | fieldName="dose_number_cycle"
          , inputType=OptionsInput
          , options=["1","2","3"]
          , labelText="周期内第几次用药"
          , width=4
          , order=11
          , displayOnly=False
          , disabled=False
          })
    , ("dose_remarks", {formControlDefault | fieldName="dose_remarks", labelText="备注：", width=12, order=10, required=False})
    ]

fcNewPatient = 
  fc
  |> Dict.remove "dose_weight"
  |> Dict.remove "dose_previous_remaining_dose"

init: Model
init = 
  { model = Data.Dose.init
  , fc=fc
  , id = Nothing
  , submitted = False
  , notifications = ""
  , error = ""
  , previous_remaining    = 0
  , patient_maintenance_dose  = 0
  , previous_opened_dt= Date.fromTime(0)
  , multiplier = 0
  , calculate_dose_algo = Manual
  , calculate_remaining_from_dose = False
  , frequency=""
  , dose_number_cycle = 0
  , endRoute = Route.Patients
  }

initNewPatient =
  init
  |> removeField "dose_weight"
  |> removeField "dose_dt_opened_expiry"
  |> removeField "dose_previous_remaining_dose"
  |> toggleHidden "dose_number_cycle" True
  |> changeWidth "dose_dt_opened" 4 
  |> changeWidth "dose_dt" 4 
  |> changeWidth "dose_next_appointment_dt" 4 

initFromPatient patient endRoute=
  let
    getModel = init.model
    --(dose_dt_opened) = 
    --    if    Data.Date.isExpired (patient.dose_dt_opened |> Data.Date.addDays constants.drug_shelf_life_days) patient.dt_now
    --    then  (single_bottle_dosage, 1, patient.dt_now )
    --    else  (patient.dose_remaining_dose, 0, patient.dose_dt_opened)
    new_model = 
      { init |
        model = {getModel |
                dose_dt = patient.dt_now
              , dose_amount = patient.patient_maintenance_dose
              , dose_weight = patient.dose_weight
              , dose_remaining_dose = patient.dose_remaining_dose + 1
              , dose_number = patient.dose_number + 1 
              , dose_number_cycle = increaseDoseNumberCycle patient.dose_number_cycle patient.patient_frequency 
                }
        , previous_remaining = patient.dose_remaining_dose
        , previous_opened_dt = patient.dose_dt_opened
        , frequency = patient.patient_frequency
        , id = Just patient.id
        , endRoute = endRoute
                } 
        |> calculateNextAppointment
        |> setBottlesFromAlgoUsingDoseDT
        |> setOpenedFromLastBottle
        |> setBottlesFromAlgo
        |> calculateExpiry
        |> setRemaining
  in
    new_model

calculateExpiry model =
  let
    getModel = model.model
  in
    {model | model = {getModel | dose_dt_opened_expiry = Data.Date.addDays constants.drug_shelf_life_days getModel.dose_dt_opened}}

setOpenedFromLastBottle model =
  let
    getModel = model.model
  in 
  { model |
        model = {getModel | dose_dt_opened = (Bottle.lastBottleDate model.model.bottles)}}

setRemaining model =
  let
    getModel = model.model
  in
    {model | model = {getModel | dose_remaining_dose = Bottle.lastBottleRemaining model.model.bottles}}



--dose_dt
--dose_dt_opened
--dose_weight
--dose_amount
--dose_remaining_dose
--dose_remarks
--dose_next_appointment_dt
--dose_number
--dose_number_cycle

--initFromPatient patient endRoute=
--    let  
--        (patient_remaining_dose, bottles_opened_from_init, dose_dt_opened) = 
--            if    Data.Date.isExpired (patient.dose_dt_opened |> Data.Date.addDays constants.drug_shelf_life_days) patient.dt_now
--            then  (single_bottle_dosage, 1, patient.dt_now )
--            else  (patient.dose_remaining_dose, 0, patient.dose_dt_opened)

--        multiplier = (Patient.frequencyToMultiplier patient.patient_frequency)
--        dose_dt = patient.dt_now
--        dose_amount = patient.patient_maintenance_dose
--        --(dose_next_appointment_dt, dose_number_cycle) = calculateNextAppointment patient_frequency dose_number_cycle dt_now
--        prev_model = Data.Dose.init
--        model = { prev_model 
--                    | dose_dt = patient.dose_dt
--                    , dose_weight = patient.dose_weight
--                    , dose_amount = patient.patient_maintenance_dose
--                    , dose_remaining_dose = patient_remaining_dose - patient.patient_maintenance_dose
--                    , dose_dt_opened = patient.dose_dt_opened
--                    , dose_dt_opened_expiry = (dose_dt_opened |> Data.Date.addDays 28) 
--                    }
--    in 
--        { init | model              = model
--        , id                        = Just patient.id
--        , patient_remaining_dose    = patient_remaining_dose
--        , patient_maintenance_dose  = patient.patient_maintenance_dose
--        , bottles_opened_from_init  = bottles_opened_from_init
--        , previous_dose_opened_dt   = model.dose_dt_opened
--        , multiplier = (Patient.frequencyToMultiplier patient.patient_frequency)
--        , calculate_dose_algo       = FromMaintenance
--        , calculate_remaining_from_dose = True
--        , frequency = patient.patient_frequency
--        , endRoute = endRoute
--        }
--        --|> doseAmountChange dose_amount
--        --|> accordingToMaintenance
--        |> toggleHidden "dose_number_cycle" (patient.patient_frequency /= "一周一次 (三周用药，一周停药)")
--        --|> patient_frequency |> Patient.frequencyToDoseFrequency |> Patient.doseFrequencyToDays
--        --  calculateNextAppointment (getNextWeek dose_number_cycle patient_frequency)
--        |> (if (patient.patient_frequency == "一周一次 (三周用药，一周停药)") then (changeWidth "dose_dt" 4 ) else identity)
--        |> (if (patient.patient_frequency == "一周一次 (三周用药，一周停药)") then (changeWidth "dose_next_appointment_dt" 4 ) else identity)
--        --|> appendActions "dose_amount" 
--        --            [ Action "doseAmountExtraOptions" "radio" "使用维持剂量" (\val ->  (AccordingToMaintenance val))
--        --            , Action "doseAmountExtraOptions" "radio" "按照体重算剂量" (\val ->  (AccordingToWeight val))
--        --            --, ("doseAmountExtraOptions", "radio", "使用剩余剂量填写", (\val -> (FormControlMsg (UseRemainingDose val))))
--        --            , Action "doseAmountExtraOptions" "radio" "直接输入" (\val ->  (AllowDoseManualInput val))
--        --            --, ("", "checkbox", "减去上次剂量填写", (\val -> (FormControlMsg (SubtractPreviousDose val))))
--        --            ]
--        --|> appendActions "dose_remaining_dose" (manualInputAction "dose_remaining_dose" FormControlMsg)
--        |> appendActions "dose_next_appointment_dt" (manualInputAction "dose_next_appointment_dt" FormControlMsg)
--        |> appendActions "dose_number_cycle" (manualInputAction "dose_number_cycle" FormControlMsg)
--        |> appendActions "dose_dt" (manualInputAction "dose_dt" FormControlMsg)
--        |> appendActions "dose_dt_opened" (manualInputAction "dose_dt_opened" FormControlMsg)
--        |> makeDisplayOnly "dose_amount" True
--        |> makeDisplayOnly "dose_remaining_dose" True
--        |> makeDisplayOnly "dose_dt_opened" True
--        |> makeDisplayOnly "dose_dt" True
--        |> makeDisplayOnly "dose_next_appointment_dt" True


view model = Base.view model.fc

withMsg = withMsg_ ValChanged

viewAsForm: Model -> Html Msg
viewAsForm model = 
    let
        isNewBottle = Bottle.isNewBottle model.previous_opened_dt model.model.dose_dt_opened model.model.bottles
        valueOf str = 
          case str of
            "dose_previous_remaining_dose" -> model.previous_remaining |> toString
            "dose_dt_opened_expiry" -> getValue model.model str
            _ -> getValueJS model.model str

        fc_with_vals = 
          model.fc
            |> Dict.toList
            |> List.map (\(key, record) -> key => {record | inputArgs = [Html.Attributes.value (valueOf record.fieldName)]})
            |> Dict.fromList
            |> (if isNewBottle then identity else (Dict.remove "dose_dt_opened"))
            |> (if isNewBottle then identity else (Dict.remove "dose_dt_opened_expiry"))
            |> (if (Patient.frequencyToShouldBeHidden model.frequency) then (Dict.remove "dose_number_cycle") else identity)

        --new_model =
        --  model | 
          --|> appendInputArgs "dose_dt" [value (Data.Date.dateToStringJS model.model.dose_dt)]
          --|> appendInputArgs "dose_weight" [value (toString model.model.dose_weight), onInput DoseWeightChanged]
          --|> appendInputArgs "dose_amount" [value (toString model.model.dose_amount), onInput DoseAmountChanged]
          --|> appendInputArgs "dose_remaining_dose" [value (toString model.model.dose_remaining_dose), onInput DoseRemainingDoseChanged]
          --|> appendInputArgs "dose_dt_opened" [value (Data.Date.dateToString model.model.dose_dt_opened), onInput DoseDTOpenedChanged]
          --|> appendInputArgs "dose_dt_opened_expiry" [value (Data.Date.dateToString model.model.dose_dt_opened_expiry)]
          --|> appendInputArgs "dose_next_appointment_dt" [value (Data.Date.dateToString model.model.dose_next_appointment_dt), onInput DoseNextAppointmentDTChanged ]
          --|> appendInputArgs "dose_number_cycle" [value (toString model.model.dose_number_cycle), onInput DoseWeekChanged ]

        notifications = []
          --[ Notification (model.model.bottles_opened_from_init>0) ("药品到期了。需要开 "++(toString model.model.bottles_opened_from_init)++" 支新药。")
          --, Notification (model.model.bottles_opened_from_dose>0) ("为了满足剂量要求需要开 "++(toString model.model.bottles_opened_from_dose)++" 支新药。")
          --, Notification ((model.model.bottles_opened_from_dose>0) && model.model.bottles_opened_from_init>0 )
          --                                            ("总共开 "++(toString (model.model.bottles_opened_from_dose + model.model.bottles_opened_from_init))++" 支新药。")
          --, Notification ((String.length model.notifications)>0) model.notifications
          --, Notification ((String.length model.error)>0) model.error
          --]
    in      
      div []  [ Base.viewAsForm (withMsg fc_with_vals) notifications Submit
              , BottleView.view model.model.bottles
              , model.model |> toString |> debug
              --, fc_with_vals |> toString |> debug
              ]

buttons =  Base.buttons Submit

----------------------- UPDATE ---------------------------------------------
-- Helpers --

--doseAmountChange amount model = 
--    let
--        new_bottles = if model.patient_remaining_dose - amount >= 0 then 0
--                   else (abs(toFloat model.patient_remaining_dose - toFloat amount) / (toFloat constants.single_bottle_dosage)) |> floor |> (+) 1
--        new_remaining = (model.patient_remaining_dose - amount) % constants.single_bottle_dosage
--        new_remaining_text = 
--          "算法：(" ++ (toString model.patient_remaining_dose) ++ " - " ++ (toString amount) ++ ") : " ++ toString constants.single_bottle_dosage ++ " = " ++ (toString new_remaining)

--        (dose_dt_opened, dose_dt_opened_text) = 
--          if (model.model.bottles_opened_from_init + new_bottles) > 0 
--          then (model.model.dose_dt, ("需要开 " ++ toString (new_bottles + model.model.bottles_opened_from_init) ++ " 支新药"))
--          else (model.previous_dose_opened_dt, "")

--        getDose  = model.model

--        bottles: List Bottle
--        bottles = 
--          let
--            first_bottle_dt = if (model.model.bottles_opened_from_init == 0) then (model.previous_dose_opened_dt |> Data.Date.stringToDate) else (model.model.dose_dt |> Data.Date.stringToDate)
--            new_bottles_dt = model.model.dose_dt |> Data.Date.stringToDate
--            dose_amount = amount
--            dose_remaining = model.patient_remaining_dose
--            dt = model.model.dose_dt |> Data.Date.stringToDate
--          in
--            (calculateBottles dose_amount dose_remaining first_bottle_dt new_bottles_dt dt)

--        new_model = {model    | bottles_opened_from_dose = new_bottles
--                              , bottles = bottles 
--                              , model = {getDose  | dose_amount = amount
--                                                  , dose_remaining_dose = new_remaining
--                                                  , dose_dt_opened = dose_dt_opened |> Data.Date.stringToDate |> Data.Date.dateToString
--                                                  , bottles = bottles
--                                                  }}
--    in 
--      if model.calculate_remaining_from_dose
--      then
--        new_model
--          |> updateValue "dose_remaining_dose" new_remaining new_remaining_text
--          |> updateValue "dose_dt_opened" dose_dt_opened dose_dt_opened_text
--          --|> formValidation "dose_remaining_dose" (toString new_remaining)
--          --|> formValidation "dose_amount" (toString amount)
--          --|> updateVal "dose_dt_opened" dose_dt_opened dose_dt_opened_text identity
--          --|> dateChange dose_dt_opened
--      else model


--weightChange: Model -> Model
--weightChange model =
--  let
--      weight                    = model.model.dose_weight
--      multiplier                = model.multiplier
--      patient_maintenance_dose  = model.patient_maintenance_dose
--      weight_dose_amount        = model.model.dose_weight * model.multiplier

--      weight_dose_amount_text = "算法：" ++ (toString weight) ++ " * " ++ (toString multiplier) ++ " = " ++ (toString weight_dose_amount)
--  in 
--    case model.calculate_dose_algo of
--      FromWeight -> model
--              |> updateValue "dose_amount" weight_dose_amount weight_dose_amount_text
--              |> doseAmountChange weight_dose_amount
--              |> makeDisplayOnly "dose_amount" True

--      FromMaintenance ->
--          model
--          |> accordingToMaintenance

--      _ ->
--          model



--accordingToMaintenance model =
--  if model.calculate_dose_algo == FromMaintenance
--  then
--    let
--      multiplier                = model.multiplier
--      patient_maintenance_dose  = model.patient_maintenance_dose
--      weight_dose_amount        = model.model.dose_weight * model.multiplier

--      difference = (patient_maintenance_dose - weight_dose_amount)
--                  |> toFloat
--                  |> abs
--                  |> (\x -> x / (toFloat patient_maintenance_dose))
--                  |> (\x -> 100*x)
--      dose_amount_text = 
--      "算法：维持剂量 ：" ++ (toString patient_maintenance_dose) ++  
--      "， 按照体重剂量：" ++ (toString weight_dose_amount) ++
--      ", 差别：" ++ Round.round 1 difference ++ "%"
--    in
--      model
--      |> updateValue "dose_amount" patient_maintenance_dose dose_amount_text
--      --|> formValidation "dose_amount" (toString model.dose_remaining)
--      |> makeDisplayOnly "dose_amount" True
--      |> doseAmountChange patient_maintenance_dose
--      --|> rangeValidator "dose_amount" (toFloat weight_dose_amount) ((toFloat patient.patient_maintenance_dose)*0.8) ((toFloat patient.patient_maintenance_dose)*1.2)

--  else model

--getNextWeek dose_number_cycle patient_frequency =
--  case (patient_frequency, dose_number_cycle) of
--    ("一周一次 (三周用药，一周停药)", 3) -> 1
--    ("一周一次 (三周用药，一周停药)", _) -> (dose_number_cycle+1)
--    (_,_) -> 0

--calculateNextAppointment patient_frequency dose_number_cycle dose_number model =
--  let
--    getModel = model.model

--    (patient_frequency, dt) = (model.frequency, model.model.dose_dt)
--    dose_next_appointment_dt =



--    case (patient_frequency, dose_number_cycle) of
--      ("三周一次", _) -> dt |> Data.Date.stringToDate |> addDays 21 |> Data.Date.dateToString
--      ("一周一次", _) -> dt |> Data.Date.stringToDate |> addDays 7 |> Data.Date.dateToString
--      ("一周一次 (三周用药，一周停药)", 3) -> dt |> Data.Date.stringToDate |> addDays 14 |> Data.Date.dateToString
--      ("一周一次 (三周用药，一周停药)", _) -> dt |> Data.Date.stringToDate |> addDays 7 |> Data.Date.dateToString
--      (_,_) -> dt
--  in
--    { model | model = { getModel 
--                              | dose_next_appointment_dt = dose_next_appointment_dt
--                              , dose_number_cycle = dose_number_cycle
--                      }
--    }
    

update msg model =
  let getModel = model.model
  in 
    case msg of
      ValChanged key val ->
        let new_model = case key of
          "dose_dt" -> 
            {model | model = {getModel | dose_dt = val |> Data.Date.stringToDate}}
              |> calculateNextAppointment
              |> setBottlesFromAlgoUsingDoseDT
              |> setOpenedFromLastBottle
          
          "dose_previous_remaining_dose" -> 
            {model | previous_remaining = val |> stringToInt}
            |> setBottlesFromAlgoUsingDoseDT
            |> setOpenedFromLastBottle
            |> calculateExpiry
            |> setRemaining

          "dose_dt_opened" -> 
            {model | model = {getModel | dose_dt_opened = val |> Data.Date.stringToDate}}
            |> setBottlesFromAlgo
            |> calculateExpiry
            |> setRemaining
          
          "dose_weight" -> 
            {model | model = {getModel | dose_weight = val |> stringToInt}}
          "dose_amount" -> {model | model = {getModel | dose_amount = val |> stringToInt}}
            |> setBottlesFromAlgoUsingDoseDT
            |> setOpenedFromLastBottle
            |> setRemaining
          
          --"dose_remaining_dose" -> {model | model = {getModel | dose_remaining_dose = val |> stringToInt}}
          "dose_remarks" -> {model | model = {getModel | dose_remarks = val}}
          "dose_next_appointment_dt" -> {model | model = {getModel | dose_next_appointment_dt = val |> Data.Date.stringToDate}}
          
          "dose_number" -> 
            {model | model = {getModel | dose_number = val |> stringToInt}}
            |> calculateNextAppointment
          "dose_number_cycle" -> 
            {model | model = {getModel | dose_number_cycle = val |> stringToInt}}
            |> calculateNextAppointment
          
          _ -> model
        in new_model => Cmd.none

      Submit -> model => (post (Maybe.withDefault 0 model.id) model.model SubmitHttp)
      SubmitHttp (Err err) -> {model | error = toString err} => Cmd.none
      SubmitHttp (Ok serverMsg) -> {model | notifications = DjangoResponse.toString serverMsg, submitted=True} => Route.modifyUrl model.endRoute
      _ -> model => Cmd.none

        --|> calculateNextAppointment
        --|> setBottlesFromAlgo
        --|> setOpenedFromLastBottle
        --|> calculateExpiry
        --|> setRemaining




--updateValue_ fieldName val txt model

setBottlesFromAlgo_ new_opened_dt model =
  let
    model_ = model.model
    bottles = Bottle.calculateBottles model.model.dose_amount model.previous_remaining model.previous_opened_dt new_opened_dt 
  in
    {model | model = { model_ | bottles = bottles}}

setBottlesFromAlgoUsingDoseDT model = setBottlesFromAlgo_ model.model.dose_dt model
setBottlesFromAlgo model = setBottlesFromAlgo_ model.model.dose_dt_opened model

calculateNextAppointment_ frequency model = 
  let
    days              = Patient.doseFrequencyToDays frequency model.model.dose_number_cycle model.model.dose_number
    next_appointment  = Data.Date.addDays days model.model.dose_dt
    getModel = model.model
  in
    {model | model = {getModel  | dose_next_appointment_dt = next_appointment
                    }
      }

calculateNextAppointment model = calculateNextAppointment_ model.frequency model

    --let
    --    getDose  = model.model
    --in
    --    case msg of
    --        FormControlMsg subMsg -> Base.update subMsg model => Cmd.none

    --        ------------------------- Field input handlers ------------------------------------------------------------------
    --        DoseDTChanged val ->  
    --            {model | model = { getDose | dose_dt = val }}
    --              --|> calculateNextAppointment model.model.dose_number_cycle
    --              |> doseAmountChange model.model.dose_amount
    --            => Cmd.none

    --        DoseWeightChanged val -> 
    --            {model | model = { getDose | dose_weight = val |> String.toInt |> Result.withDefault 0}} 
    --              |> weightChange
    --            => Cmd.none

    --        DoseAmountChanged val -> 

    --            doseAmountChange (val |> String.toInt |> Result.withDefault 0) model => Cmd.none

    --        DoseRemainingDoseChanged val -> 
    --            {model | model = { getDose | dose_remaining_dose = val |> String.toInt |> Result.withDefault 0}} => Cmd.none

    --        DoseDTOpenedChanged val -> 
    --            {model | model = { getDose | dose_dt_opened = val, dose_dt_opened_expiry = ((Data.Date.addDaysFromString constants.drug_shelf_life_days val) |> Data.Date.dateToString) }} 
    --            => Cmd.none

    --        DoseNextAppointmentDTChanged val ->
    --            {model | model = { getDose | dose_next_appointment_dt = val }} 
    --            => Cmd.none

    --        DoseWeekChanged val ->
    --            {model | model = { getDose | dose_number_cycle = val |> String.toInt |> Result.withDefault 0 }} 
    --              --|> calculateNextAppointment (val |> String.toInt |> Result.withDefault 0) 
    --            => Cmd.none

    --        --------------------------- Action selected handlers ----------------------------------------------------------------
    --        AccordingToMaintenance _ -> 
    --            {model | calculate_dose_algo = FromMaintenance}
    --              |> makeDisplayOnly "dose_amount" True
    --              |> accordingToMaintenance
    --            => Cmd.none

    --        AccordingToWeight _ -> 
    --            {model | calculate_dose_algo = FromWeight}
    --              |> makeDisplayOnly "dose_amount" True
    --              |> weightChange
    --             => Cmd.none

    --        AllowDoseManualInput _ -> 
    --            {model | calculate_dose_algo = Manual}
    --              |> makeDisplayOnly "dose_amount" False
    --            => Cmd.none
    --        --------------------------- API handlers ----------------------------------------------------------------

    --        Submit -> model => (post (Maybe.withDefault 0 model.id) model.model SubmitHttp)
    --        SubmitHttp (Err err) -> {model | error = toString err} => Cmd.none
    --        SubmitHttp (Ok serverMsg) -> {model | notifications = DjangoResponse.toString serverMsg, submitted=True} => Route.modifyUrl model.endRoute

    --        _ -> model => Cmd.none