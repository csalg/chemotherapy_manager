module Views.PatientForms.Heart exposing (..)

import Dict
import Html exposing(..)
import Html.Attributes exposing(..)
import Html.Events exposing(..)
import Http

import Constants exposing (constants)
import Data.DjangoResponse as DjangoResponse
import Data.HeartReport as HeartReport exposing(HeartReport)
import Request.HeartReport exposing(post)
import Route
import Util exposing((=>), onChange)
import Views.PatientForms.Base as Base exposing (..)



type alias Model  = 
  { id: Maybe Int
  , model: HeartReport
  , fc: Dict.Dict String (FormControl Msg)
  , days_exceeded: Int
  , error: String
  , notifications: String
  , endRoute: Route.Route
  }

type Msg = 
    Nope
  | Submit
  | SubmitHttp (Result Http.Error DjangoResponse.DjangoResponse)
  | FormControlMsg Base.Msg
  | HeartTextChanged String
  | HeartDTChanged String
  | HeartPercentageChanged String
  | HeartRemarksChanged String

fc = (Dict.fromList [ 
            ("heart_text", {formControlDefault | fieldName="heart_text", labelText="心超报告：", inputType=OptionsInput, options=constants.echocardiography_reports, width=12, order=1})
          , ("heart_dt", {formControlDefault | fieldName="heart_dt"
                , labelText="心超日期："
                , inputType=DateInput
                , order=2
                , width=6
                , displayOnly=False
                , disabled=False
                , allowOverride=True
                , required = True
                })
          , ("heart_percentage", {formControlDefault | fieldName="heart_percentage", labelText="左心射血分数(%)：", inputType=Inpt "number", required=True, order=3, width=6})
          , ("heart_remarks", {formControlDefault | fieldName="heart_remarks", labelText="备注：", width=12, order=4, required=False})
          ])
init = 
    Model Nothing HeartReport.init fc 0 "" "" Route.Patients
        |> appendActions "heart_dt" (manualInputAction "heart_dt" FormControlMsg)
        |> makeDisplayOnly "heart_dt" True

initWithValues id days_ago dt_now endRoute =
  let

    getHeart = init.model
    days_exceeded = 0 - days_ago 
    new_model =
      {init 
        | id = Just id
        , days_exceeded = days_exceeded
        , model = { getHeart | heart_dt = dt_now }
        , endRoute = endRoute
      }
  in 
    new_model

view model = Base.view model.fc

viewAsForm: Model -> Html Msg
viewAsForm model = 
    let
        model_with_vals = model
            |> appendInputArgs "heart_text" [ onInput HeartTextChanged, value model.model.heart_text ]
            |> appendInputArgs "heart_dt" [ onInput HeartDTChanged, value model.model.heart_dt]
            |> appendInputArgs "heart_percentage" [onInput HeartPercentageChanged, value model.model.heart_percentage]
            |> appendInputArgs "heart_remarks" [onInput HeartRemarksChanged, value model.model.heart_remarks]
            |> makeDisplayOnly "heart_text" (model.days_exceeded>0)

        notifications = 
          [ Notification (model.days_exceeded > 0) ("超过 "++(toString model.days_exceeded)++" 天。必须选：“遵医嘱”。请填备注。")
          , Notification ((String.length model.notifications)>0) model.notifications
          , Notification ((String.length model.error)>0) model.error
          ]
    in      
      Base.viewAsForm model_with_vals.fc notifications Submit

buttons =  Base.buttons Submit


update msg model =
    let
      getHeart = model.model
    in
      case msg of
          FormControlMsg subMsg -> Base.update subMsg model => Cmd.none
          HeartTextChanged val -> {model | model = {getHeart | heart_text = val }} => Cmd.none
          HeartDTChanged val -> {model | model = {getHeart | heart_dt = val }} => Cmd.none
          HeartPercentageChanged val -> {model | model = {getHeart | heart_percentage = val }} => Cmd.none
          HeartRemarksChanged val -> {model | model = {getHeart | heart_remarks = val }} => Cmd.none

          Submit -> model => (post (Maybe.withDefault 0 model.id) model.model SubmitHttp)
          SubmitHttp (Err err) -> {model | error = toString err} => Cmd.none
          SubmitHttp (Ok serverMsg) -> {model | notifications = DjangoResponse.toString serverMsg} => Route.modifyUrl model.endRoute
          _ -> model => Cmd.none