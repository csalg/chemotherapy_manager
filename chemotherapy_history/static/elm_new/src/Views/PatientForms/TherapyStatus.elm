module Views.PatientForms.TherapyStatus exposing (..)

import Dict
import Html exposing(..)
import Html.Attributes exposing(..)
import Html.Events exposing(..)
import Http

import Constants exposing (constants)
import Data.DjangoResponse as DjangoResponse
import Data.Patient exposing (statusToString)
import Data.TherapyStatus as TherapyStatus exposing(TherapyStatus)
import Request.TherapyStatus exposing(post)
import Route
import Util exposing((=>), onChange, debug)
import Views.PatientForms.Base as Base exposing (..)



type alias Model  = 
  { id: Maybe Int
  , model: TherapyStatus
  , fc: Dict.Dict String (FormControl Msg)
  , error: String
  , notifications: String
  , endRoute: Route.Route
  }

type Msg = 
    Nope
  | Submit
  | SubmitHttp (Result Http.Error DjangoResponse.DjangoResponse)
  | FormControlMsg Base.Msg
  | TherapyStatusChanged String
  | TherapyDTChanged String
  | TherapyReasonChanged String
  | TherapyRemarksChanged String

init = 
    Model Nothing
      TherapyStatus.init 
      (Dict.fromList [ 
            ("therapy_status", {formControlDefault | fieldName="therapy_status", labelText="治疗状态", inputType=OptionsInput, options=constants.therapy_states, width=12, order=1})
          , ("therapy_reason", {formControlDefault | fieldName="therapy_reason", labelText="原因: ", inputType=OptionsInput, options=constants.drug_stop_reasons, order=2, width=12, hidden=True})
          , ("therapy_remarks", {formControlDefault | fieldName="therapy_remarks", labelText="备注: ", width=12, order=3, required=False})
          , ("therapy_dt", {formControlDefault | fieldName="therapy_dt"
                , labelText="纪录日期"
                , inputType=DateInput
                , order=4
                , width=12
                , displayOnly=True
                , disabled=True
                , allowOverride=True
                , actions = manualInputAction "therapy_dt" FormControlMsg
                })
          ])
      "" "" Route.Patients

initWithValues id therapy_dt endRoute  =
  let
    getModel = init.model
  in 
    {init | id = Just id, model = {getModel | therapy_dt=therapy_dt }, endRoute = endRoute  }

initWithValuesTemporaryHalt id therapy_dt endRoute  =
  let
    getModel = init.model
  in 
    {init | id = Just id, model = {getModel | therapy_dt=therapy_dt, therapy_status=(Data.Patient.TemporaryHalt |> statusToString), therapy_reason = (constants.drug_stop_reasons |> List.head |> Maybe.withDefault "") }, endRoute = endRoute  }
      |> makeDisplayOnly "therapy_status" True
      |> toggleHidden "therapy_reason" False




view model = Base.view model.fc

viewAsForm: Model -> Html Msg
viewAsForm model = 
    let
        model_with_vals = model
            |> appendInputArgs "therapy_status" [value model.model.therapy_status, onInput TherapyStatusChanged]
            |> appendInputArgs "therapy_dt" [value model.model.therapy_dt, onInput TherapyDTChanged]
            |> appendInputArgs "therapy_reason" [value model.model.therapy_reason, onInput TherapyReasonChanged]
            |> appendInputArgs "therapy_remarks" [value model.model.therapy_remarks, onInput TherapyRemarksChanged]

        notifications = 
          [ Notification ((String.length model.notifications)>0) model.notifications
          , Notification ((String.length model.error)>0) model.error
          ]
    in      
      div [] [Base.viewAsForm model_with_vals.fc notifications Submit, debug (toString model.model)]

buttons =  Base.buttons Submit

update msg model =
    let
      getStatus = model.model
    in
      case msg of
          FormControlMsg subMsg -> Base.update subMsg model => Cmd.none
          TherapyStatusChanged val -> 
            if val == "治疗中" || val == "完成所有治疗"
            then
              {model | model = {getStatus | therapy_status = val, therapy_reason = ""}}
                |> toggleHidden "therapy_reason" True
              => Cmd.none
            else
              {model | model = {getStatus | therapy_status = val, therapy_reason = constants.drug_stop_reasons |> List.head |> Maybe.withDefault "" }} 
                |> toggleHidden "therapy_reason" False
              => Cmd.none

          TherapyDTChanged val -> {model | model = {getStatus | therapy_dt = val }} => Cmd.none
          TherapyReasonChanged val -> {model | model = {getStatus | therapy_reason = val }} => Cmd.none
          TherapyRemarksChanged val -> {model | model = {getStatus | therapy_remarks = val }} => Cmd.none

          Submit -> model => (post (Maybe.withDefault 0 model.id) model.model SubmitHttp)
          SubmitHttp (Err err) -> {model | error = toString err} => Cmd.none
          SubmitHttp (Ok serverMsg) -> 
            case serverMsg of 
              DjangoResponse.Err     serverTxt -> {model | notifications = serverTxt} => Cmd.none
              DjangoResponse.Success serverTxt -> model => Route.modifyUrl model.endRoute
          _ -> model => Cmd.none