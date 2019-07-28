module Views.PatientForms.Base exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
--import DateTimePicker
--import DateTimePicker.Config exposing (Config, CssConfig, DatePickerConfig, TimePickerConfig, defaultDatePickerConfig, defaultDateTimeI18n, defaultDateTimePickerConfig, defaultTimePickerConfig)

import Dict
import Date
import Date.Extra.Format exposing (isoDateString)
import Bootstrap.Form.Input as Input
import Html.Attributes.Extra exposing (innerHtml)

import FormControl.Types exposing (..)
import Types exposing (..)
import Helpers exposing (onChange)
import Data.Date exposing (..)


type alias FormControl msg = 
  { fieldName: String
  , value: String
  , order: Int
  , labelText: String
  , width: Int
  , inputType: InputType
  , placeholder: String
  , helpText: String
  , options: List String
  , disabled: Bool
  , required: Bool
  , allowOverride: Bool
  , validationState: FormControlValidationState
  , displayOnly: Bool
  , min: Int
  , max: Int
  , hidden: Bool
  , inputArgs: List (Html.Attribute msg)
  , actions: List (Action msg)
  }


type alias Action msg =
        { actionName: String
        , typ: String
        , txt: String
        , onchk: Bool -> msg
        }

type FormControlValidationState = Empty | Invalid | Valid

type DoseAlgo = FromMaintenance | FromWeight | FromLastRemainingDose | Manual

type OpenDateState = Manual_ | Now | DoseDT

type InputType =  Inpt String
                | DateInput 
                | OpenedDate 
                | OptionsInput 
                | NumberInput 
                | TextInput  
                | NewBottle
                | Weight
                | DoseAmount
                | DateTimePicker DateTimePicker.State (Maybe Date.Date)

type alias Model msg=  { fc: Dict.Dict String (FormControl msg)
                    , previous_remaining_dose: Int
                    , multiplier: Int
                    , single_bottle_dosage: Int
                    , dose_dt: Date.Date
                    , dose_weight: Int
                    , dose_amount: Int
                    , dose_remaining: Int
                    , calculate_dose_algo: DoseAlgo
                    , calculate_remaining_from_dose: Bool
                    }


formControlDefault: FormControl Types.Msg
formControlDefault = 
       { fieldName= ""
       , value=""
       , order = 0
       , labelText= ""
       , width=4
       , inputType= Inpt "text"
       , placeholder=""
       , helpText=""
       , options=[]
       , disabled=False
       , required=True
       , allowOverride=False
       , validationState=Empty
       , displayOnly=False
       , max= 9999999999999999
       , min= 0
       , hidden = False
       , inputArgs = [] -- Like onInput, etc.
       , actions = [] -- Usually checkboxes or radios that appear under the input
       }


--Helpers

displayOnly: FormControl Types.Msg -> FormControl Types.Msg
displayOnly fc =
 {fc | disabled = True, validationState=Empty, displayOnly=True }


--View renderers
asView: Dict.Dict String (FormControl Types.Msg) -> Patient -> Html Types.Msg
asView formControls patient = 
 div
                    [ class "panel-body" ]

                    [ div
                        [ class "row" ]
                        (formControls
                         |> Dict.values
                         |> List.sortBy .order
                         |> List.map (populateValues patient)
                         |> List.map displayOnly 
                         |> List.map render
                         )
                        ]


asEditable formControls = 
 div
  [ class "panel-body" ]

  [ div
      [ class "row" ]
      (formControls
       |> Dict.values
       |> List.sortBy .order
       |> List.map render
       )

  ]


--FormControl renderer
render: FormControl Types.Msg -> Html Types.Msg
render fc =
    let 
-------------------------------
      wrapper inpt=
        let
          extraDivArgs = (if fc.hidden then [style [("display", "none")]] else  [])
          hasWhat = case fc.validationState of
            Empty -> ""
            Invalid -> " has-error"
            Valid -> " has-success"
        in
          div
              [ id fc.fieldName, class ("form-group col-sm-" ++ (toString(fc.width)) ++ hasWhat) ]
              [  ifNotHidden (label
                  [ class "control-label", for fc.fieldName ]
                  [ text fc.labelText])
              , inpt
              , ifNotHidden (span [class hasWhat] [(text fc.helpText)])
              , ifNotHidden actions]
-------------------------------
      labl = label
                  [ class "control-label", for fc.fieldName ]
                  [ text fc.labelText]
-------------------------------

      actions = div [] (List.map viewAction fc.actions)

-------------------------------

      ifNotHidden what = if fc.hidden then text "" else what

      inpt extra = 
        let
          attrs = 
            if fc.hidden 
            then [type_ "hidden"]
            else 
              if fc.displayOnly 
              then [type_ "text", value fc.value] 
              else extra
        in
          div[]
          [input
            (attrs++[ name fc.fieldName
              , class (if fc.inputType == NewBottle then "" else "form-control")
              , disabled (fc.disabled || fc.displayOnly)
              , required fc.required
              ])
            []
            , hiddenVal
            ]

      viewOption optionValue = option
                            [ Html.Attributes.value optionValue ]
                            [ text optionValue]
      inputSelect = 
        if fc.displayOnly then inpt [] else
          select
            [ name fc.fieldName, required fc.required, class "form-control", onInput (\val-> (FormControlMsg (FormControlValidationCheck fc.fieldName val))) ]
            (List.map viewOption fc.options) 

-------------------------------
      hiddenVal = 
        if fc.displayOnly 
        then input [name fc.fieldName, type_ "hidden", attribute "value" fc.value] []
        else text ""

      inputDT = 
        if (fc.hidden || fc.displayOnly)
        then inpt [(type_ "text")]
        else
          div [] 
          [(Input.datetimeLocal
            [ Input.small
            , Input.attrs ([(name fc.fieldName), disabled fc.disabled, required fc.required]++fc.inputArgs)
            ])
          , hiddenVal
          ]

      viewAction {actionName, typ, txt, onchk} = div [class "radio"] 
                  [ input [ type_ typ, name actionName, onCheck onchk ] []
                  , label [] [text txt]
             
  in 
    case fc.inputType of
      Inpt typeValue -> wrapper (inpt ([(type_ typeValue)]++fc.inputArgs))
      DateInput -> wrapper inputDT
      OptionsInput -> wrapper inputSelect
      _ -> wrapper (inpt fc.inputArgs)

