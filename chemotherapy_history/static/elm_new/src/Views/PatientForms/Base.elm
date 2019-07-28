module Views.PatientForms.Base exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Extra exposing (innerHtml)
import Html.Events exposing (..)
import Http

import Material.Card as Card
import Material
import Material.Options as Options exposing (css)
import Material.Color as Color
import Material.List as Lists
import Material.Button as Button
import Material.Typography as Typo
import Material.Icon as Icon
import Material.Menu as Menu
import Material.Grid exposing (grid, cell, size, stretch, align, Align(..), Device(..))

import Bootstrap.Modal as Modal
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Button as Button
import Bootstrap.Form.Input as Input

import Dict
import Date
import Date.Extra.Format exposing (isoDateString)

--import FormControl.Types exposing (..)
--import Types exposing (..)
import Util exposing (onChange)
import Data.Date exposing (..)
import Styles exposing (..)

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

--type DoseAlgo = FromMaintenance | FromWeight | FromLastRemainingDose | Manual

--type OpenDateState = Manual_ | Now | DoseDT

type InputType =  Inpt String
                | DateInput 
                | OptionsInput 
                | Checkbox


--formControlDefault: FormControl Types.Msg
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

manualInputAction fieldName msgWrapper = [Action "" "checkbox" "直接输入"  (\val -> (msgWrapper (AllowManualInput fieldName val)))]

type Msg = AllowManualInput String Bool

update msg model =
  case msg of
    AllowManualInput fieldName checked -> 
      model
        |> makeDisplayOnly fieldName (not checked)











--Helpers

--displayOnly: FormControl Types.Msg -> FormControl Types.Msg
displayOnly fc =
 {fc | disabled = True, validationState=Empty, displayOnly=True }


view fcDict = 
 div
  [ class "panel-body" ]

  [ div
      [ class "row" ]
      (fcDict
       |> Dict.values
       |> List.sortBy .order
       |> List.map render
       )

  ]

type alias Notification =
  { condition: Bool
  , txt: String
  }
--viewAsForm: Model -> Html Msg
viewAsForm fcs notifications submitMsg = 
    let
      notifications_html =
        let 
          toLi x = li [] [text x]
          perhaps {condition, txt} = if condition then [b] else []
        in
          notifications
            |> List.filter (\x -> x.condition)
            |> List.map (\x -> x.txt)
            |> List.map toLi
    in      
        Html.form [method "post", onSubmit submitMsg]
            [ view fcs
            , if notifications_html == [] then (text "") else (hr [] [])
            , if notifications_html == [] then (text "") else (div [ class "panel-body"] 
                [ h6 [][i [class "fas fa-exclamation-circle"] [], text " 提醒"]
                , ul [] notifications_html
                , br [] []
                ])
            ]

buttons msg =  [ Button.button
                [ Button.outlinePrimary
                , Button.onClick msg
                ]
                [ text "提交" ]
              ]

--FormControl renderer
render: FormControl msg -> Html msg
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
                  [ class "control-label", for fc.fieldName, style formControlLabel ]
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
            (attrs++fc.inputArgs++[ name fc.fieldName
              , class (if fc.inputType == Checkbox then "" else "form-control")
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
            ([ name fc.fieldName, required fc.required, class "form-control" ]++fc.inputArgs)
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
                  ]
             
    in 
      if fc.hidden then text ""
      else
        case fc.inputType of
          Inpt typeValue -> wrapper (inpt ([(type_ typeValue)]++fc.inputArgs))
          DateInput -> wrapper inputDT
          OptionsInput -> wrapper inputSelect
          _ -> wrapper (inpt fc.inputArgs)


-- Functions for working with FormControl dictionaries --

getFieldName fieldName model = Dict.get fieldName model.fc

modifyFormControls: String -> { b | fc : Dict.Dict String (FormControl m) } -> ((FormControl m) -> (FormControl m)) -> { b | fc : Dict.Dict String (FormControl m) }
modifyFormControls fieldName model recordModifier=
  -- This is basically a boilerplate handler xD
  case (getFieldName fieldName model) of
    Just record -> {model | fc = (Dict.insert fieldName (record |> recordModifier) model.fc)}
    Nothing -> model

setDisabled fieldName val model =
    (\record -> {record | disabled = val})
      |> (modifyFormControls fieldName model)

removeActions fieldName model =
    (\record -> {record | actions = []})
      |> (modifyFormControls fieldName model)

appendActions fieldName newActions model  =
  let
    entry = Dict.get fieldName model.fc
  in
    case entry of
      Nothing -> model
      Just previous_entry -> 
        (\record -> {record | actions = previous_entry.actions++newActions})
          |> (modifyFormControls fieldName model)


appendInputArgs fieldName newArgs model  =
  let
    entry = Dict.get fieldName model.fc
  in
    case entry of
      Nothing -> model
      Just previous_entry -> 
        (\record -> {record | inputArgs = previous_entry.inputArgs++newArgs})
          |> (modifyFormControls fieldName model)

makeDisplayOnly fieldName allowInput model = 
    (\record -> {record | displayOnly = allowInput, disabled=allowInput})
      |> (modifyFormControls fieldName model )

toggleHidden fieldName val model = 
    (\record -> {record | hidden = val})
      |> (modifyFormControls fieldName model )

changeWidth fieldName val model = 
    (\record -> {record | width = val})
      |> (modifyFormControls fieldName model )

updateVal fieldName val txt formatter model = 
    (\record -> 
      {record | value = val |> formatter
              , helpText = txt})
        |> (modifyFormControls fieldName model)

updateValue_ fieldName val txt model = 
    (\record -> 
      {record | value = val
              , helpText = txt})
        |> (modifyFormControls fieldName model)


updateValue fieldName val txt model = 
    updateVal fieldName val txt toString model

removeField: String -> {a| fc: Dict.Dict String (FormControl msg)} -> {a| fc: Dict.Dict String (FormControl msg)}
removeField fieldName model =
  { model | fc = (Dict.remove fieldName model.fc) }



modifyFC recordModifierFunction fieldName model  =
  let
    entry = Dict.get fieldName model.fc
  in
    case entry of
        Just record -> {model | fc = (Dict.insert fieldName (record |> recordModifierFunction) model.fc)}
        Nothing -> model