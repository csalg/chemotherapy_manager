module Page.Patients exposing (..)

import Debug
import Date
import Http
import Html exposing(..)
import Html.Attributes exposing (..)
import Html.Events as Events exposing (..)
import Time exposing (Time)
import Task
import String exposing(uncons, left, right, length)

import Material
import Material.Table as Table
import Material.Toggles as Toggles
import Material.Options as Options exposing(css)
import Material.Elevation as Elevation
import Material.Grid as Grid exposing (grid, cell, size, Device(..))

import Bootstrap.Form as Form
import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup

import Util exposing ((=>))
import Request.Patients as RequestHandler
import Request.Patient as PatientRequestHandler
import Request.External
import Styles exposing(..)
import Data.Patients exposing (Patients, patientsDecoder)
import Data.Patient as Patient exposing (Patient, statusToString, TherapyStatus(..))
import Data.Date exposing(dateToString)
import Views.ExpressForm as ExpressForm
import Navigation
import Route

type alias Model =     
    { dt_now: Date.Date
    , error: Maybe String
    , patients : Maybe Patients
    , query: String
    , show_filter_options: Bool
    , filterByActive: Bool
    , filterByTemporaryHalt: Bool
    , filterByHalt: Bool
    , filterByFinished: Bool
    , orderBy: (Field, Table.Order)
    , pid: Int
    , patient: Maybe Patient
    , form: Maybe (ExpressForm.Model)
    }

type Field = 
            Id
          | PatientName
          | PatientAge
          | PatientCard
          | DoseAgo
          | DoseDT
          | HeartDt
          | HeartAgo
          | ExpiryAgo
          | TherapyStatus

type Msg = 
      Blank 
    | UpdateNow Time 
    | Fetched (Result Http.Error Patients) 
    | FetchedPatient (Result Http.Error Patient)
    | GetPatients Time
    | GetPatientsWithExpress Int Time
    | SetQuery String
    | ToggleShowFilters
    | ChangePage Route.Route
    | FilterBy TherapyStatus
    | Reorder Field
    | CloseModal
    | ExpressMsg (ExpressForm.Msg)

update msg model =

    case msg of
        GetPatients t -> 
            let dt_now = Date.fromTime t
            in
                {model | dt_now= dt_now} 
                => Http.send Fetched ( RequestHandler.get dt_now )

        GetPatientsWithExpress pid t -> 
            let dt_now = Date.fromTime t
            in
                {model | dt_now= dt_now
                , pid=pid
                }
                => Cmd.batch  
                    [ Http.send Fetched ( RequestHandler.get dt_now )
                    , Http.send FetchedPatient ( PatientRequestHandler.get pid dt_now )
                    ]

        Fetched (Err err) ->
            {model | error = Just (toString err)} => Cmd.none

        Fetched (Ok patients) ->
            {model | patients = Just patients} => Cmd.none

        FetchedPatient (Err err) ->
            {model | error = Just (toString err)} => Cmd.none

        FetchedPatient (Ok patient) ->
              {model | form = Just (ExpressForm.initWithValues model.pid patient model.dt_now (Route.PatientsWithExpress model.pid))
              , patient = Just patient
              } 
              => Cmd.none

        SetQuery new_query ->
          let deb = Debug.log(left 1 new_query)
          in
            if (((left 1 new_query) == "!" && (right 1 new_query) == "!") || ((left 1 new_query) == "！" && (right 1 new_query) == "！")) && (length new_query) > 2
            then 
              case new_query |> (String.slice 1 -1) |> String.toInt of
                Err err -> {model | query=new_query, error= Just (new_query |> (String.slice -1 -1))} => Cmd.none
                Ok pid    -> {model | query=new_query |> String.slice 0 -1 } => Task.perform (GetPatientsWithExpress pid) Time.now
            else {model | query=new_query} => Cmd.none

        ToggleShowFilters -> 
          {model | show_filter_options = not model.show_filter_options} => Cmd.none
        
        FilterBy status -> 
          case status of
            Active         -> {model | filterByActive= not model.filterByActive} => Cmd.none
            TemporaryHalt  -> {model | filterByTemporaryHalt= not model.filterByTemporaryHalt} => Cmd.none
            Halt           -> {model | filterByHalt= not model.filterByHalt} => Cmd.none
            Finished       -> {model | filterByFinished= not model.filterByFinished} => Cmd.none

        ChangePage route -> model => Route.newUrl route

        Reorder field ->
          if (Tuple.first model.orderBy == field) then
            case model.orderBy of
              (_, Table.Ascending) -> {model | orderBy= (field, Table.Descending)} => Cmd.none
              (_, Table.Descending) -> {model | orderBy= (field, Table.Ascending)} => Cmd.none
          else {model | orderBy= (field, Table.Descending)} => Cmd.none

        CloseModal -> {model | form = Nothing} => Cmd.none

        ExpressMsg subMsg ->
          case model.form of
            Nothing -> model => Cmd.none
            Just subModel -> 
              let
                (new_model, new_msg) = ExpressForm.update subMsg subModel
              in
                { model | form = Just new_model } => Cmd.map ExpressMsg new_msg

        _ -> model => Cmd.none

init = Model (Date.fromTime 0) Nothing Nothing "" False True True False False (PatientAge, Table.Descending) 0 Nothing Nothing

initTask = Task.perform GetPatients Time.now
initTaskWithExpress pid = 
  Task.perform (GetPatientsWithExpress pid) Time.now

    --Time.now
    --    |> Task.andThen
    --        (\t ->
    --          Task.map2 FetchedWithPatient
    --            (RequestHandler.get (Date.fromTime t) 
    --              |> Http.toTask) 
    --            (PatientRequestHandler.get pid (Date.fromTime t) 
    --              |> Http.toTask) 
                  
    --        )
    --    |> Task.attempt Fetched


    --Http.get (apiUrl ++ "?from=" ++ toString time) eventsListDecoder
    --    |> Http.toTask


  --Task.perform GetPatients Time.now


viewTable model = 

    let 
        sortOrder field_ =
          let
            (field,sort) = model.orderBy
          in
            if field == field_
            then case sort of
              Table.Ascending  -> [Table.ascending]
              Table.Descending -> [Table.descending]
            else []
        sortFields: Patients -> Patients
        sortFields lst =
          let
            (field,sort) = model.orderBy
            sortedList =
              case field of
                Id          -> List.sortBy .id lst
                PatientName -> List.sortBy .patient_name lst
                PatientAge  -> List.sortBy (.patient_age  >> String.toInt >> Result.withDefault 0 )lst
                PatientCard -> List.sortBy .patient_card lst
                DoseAgo     -> List.sortBy .dose_ago lst
                DoseDT      -> List.sortBy (.dose_dt >> Date.toTime) lst
                HeartDt     -> List.sortBy (.heart_dt >> Date.toTime) lst
                HeartAgo    -> List.sortBy .heart_ago lst
                ExpiryAgo    -> List.sortBy .expiry_ago lst
                TherapyStatus -> List.sortBy (.therapy_status >> Patient.statusToString) lst
              in
                case sort of
                  Table.Ascending -> sortedList
                  Table.Descending -> List.reverse sortedList

              --TherapyStatus -> .therapy_status

        fields =
            [ (.id >> toString, "id", ([Table.numeric, Options.onClick (Reorder Id)]++(sortOrder Id)), [])
            , (.patient_name, "姓名", ([Options.onClick (Reorder PatientName)]++(sortOrder PatientName)), [])
            , (.patient_age, "年龄", ([Table.numeric, Options.onClick (Reorder PatientAge)]++(sortOrder PatientAge)), [Table.numeric])
            , (.patient_card, "磁卡号", ([Table.numeric, Options.onClick (Reorder PatientCard)]++(sortOrder PatientCard)), [])
            --, (.patient_frequency, "用药频率", [])
            , (.dose_ago >> toString, "几天前用药", ([Table.numeric, Options.onClick (Reorder DoseAgo)]++(sortOrder DoseAgo)), [])
            , ((dateToString << .dose_dt), "用药日期", ([Options.onClick (Reorder DoseDT)]++(sortOrder DoseDT)), [])
            , (.heart_dt >> dateToString, "心超日期", ([Options.onClick (Reorder HeartDt)]++(sortOrder HeartDt)), [])
            , (.heart_ago >> toString, "几天前心超", ([Table.numeric, Options.onClick (Reorder HeartAgo)]++(sortOrder HeartAgo)), [])
            , (.expiry_ago >> toString, "几天本药到期", ([Table.numeric, Options.onClick (Reorder ExpiryAgo)]++(sortOrder ExpiryAgo)), [])
            , (.therapy_status >> statusToString, "治疗状态", ([Options.onClick (Reorder TherapyStatus)]++(sortOrder TherapyStatus)), [])
            ]
        patients = case model.patients of
                Nothing -> []
                Just ps -> 
                  ps
                  |> sortFields
                  |> List.filter (\patient -> 
                  (
                    (if model.filterByActive then patient.therapy_status == Active else False)
                    || (if model.filterByTemporaryHalt then patient.therapy_status == TemporaryHalt else False)
                    || (if model.filterByHalt then patient.therapy_status == Halt else False)
                    || (if model.filterByFinished then patient.therapy_status == Finished else False)
                  ) &&
                  ( case (uncons model.query)of
                      Nothing -> True
                      Just (hd,tl) ->
                        if hd == '!' || hd == '！'  then String.contains tl (toString patient.id)
                        else
                          ((String.contains model.query (.patient_name patient))
                          || String.contains model.query (toString patient.id)
                          || String.contains model.query (toString patient.patient_card))
                    )
                  )

    in
        Table.table [css "width" "100%", Elevation.e2]
          [ Table.thead []
            [ Table.tr []
              --[ Table.th [Table.ascending]
              --  [ text "someFieldName"]
              --]

                ( fields
                    |> List.map (\(accessor, field_name, th_attr, td_attr)
                             -> Table.th th_attr [ text field_name ])
                    )
            ]
          , Table.tbody []
                (patients
                    |> List.map (\patient ->
                         Table.tr [Options.onClick (GetPatientsWithExpress patient.id (Date.toTime model.dt_now))
                          --(ChangePage (Route.Patient patient.id))
                          ]
                            ( fields
                                |> List.map (\(accessor, field_name, th_attr, td_attr)
                                    -> Table.td td_attr [ text (accessor patient) ])
                            )
                           --[ Table.td [] [ text patient.patient_name ]
                           --, Table.td [ Table.numeric ] [ text patient.patient_age ]
                           --, Table.td [ Table.numeric ] [ text patient.patient_age ]
                           --]
                       ))
          ]

viewSearchArea model =
  let filterOptions =
        div [ class "container"
            , style [ ("padding", "10px")
                    , ("display", "flex")
                    , ("justify-content", "center")
                    ] ] 
          [ div [class "row"] 
            [ span [ style [("padding", "5px")]] [text "按照治疗状态筛选: "]
            , ButtonGroup.checkboxButtonGroup []
                [ ButtonGroup.checkboxButton
                    model.filterByActive
                    [ Button.outlineSecondary, Button.onClick (FilterBy Active) ]
                    [ text "治疗中" ]
                , ButtonGroup.checkboxButton
                    model.filterByTemporaryHalt
                    [ Button.outlineSecondary, Button.onClick (FilterBy TemporaryHalt) ]
                    [ text "暂停治疗" ]
                , ButtonGroup.checkboxButton
                    model.filterByHalt
                    [ Button.outlineSecondary, Button.onClick (FilterBy Halt) ]
                    [ text "终止" ]                
                , ButtonGroup.checkboxButton
                    model.filterByFinished
                    [ Button.outlineSecondary, Button.onClick (FilterBy Finished) ]
                    [ text "完成所有治疗" ]
                    ]
                --, span [ style [("padding", "5px")]] [text "杂项选择: "]
                --,  ButtonGroup.checkboxButtonGroup []
                --  [ ButtonGroup.checkboxButton
                --      model.filterByHalt
                --      [ Button.outlineSecondary, Button.onClick (FilterBy Active) ]
                --      [ text "色码字段" ]
                --  , ButtonGroup.checkboxButton
                --      model.filterByHalt
                --      [ Button.outlineSecondary, Button.onClick (FilterBy Active) ]
                --      [ text "仅显示异常值" ]
                --  , ButtonGroup.checkboxButton
                --      model.filterByHalt
                --      [ Button.outlineSecondary, Button.onClick (FilterBy Active) ]
                --      [ text "药物将在下次预约前到期" ]
                --  ]
                ]
              ]
              
  in
      div [ class "mdl-shadow--2dp"
      , style [("display", "flex")
              , ("justify-content", "center")
              , ("background-color", "white")
              , ("align-items", "center")
              , ("margin-bottom", "10px")
              ] 
      ]
        [ div [class "container search_bar"]

        [ div [ style [("display", "flex"), ("width", "100%"), ("justify-content", "center")] ]
            [ div [ class "input-group mb-3", style[("width", "50%")] ]
                [ div [ class "input-group-prepend" ]
                    [ span [ class "input-group-text", id "basic-addon1" ]
                        [ i [ class "fas fa-filter" ] [] ]
                    ]
                , input [ attribute "aria-describedby" "basic-addon1"
                        , attribute "aria-label" "输入筛选查询"
                        , class "form-control"
                        , placeholder "输入筛选查询"
                        , type_ "text"
                        , style searchBarCustom
                        , onInput SetQuery ]
                    []
                ]
                --[ input [ class "form-control", name "search_term", placeholder "", type_ "text" ]
                --    []
                --]
            , div [ class "" ]
                [ button [ class "btn btn-default "
                        , id "search_button"
                        , type_ "submit"
                        , onClick ToggleShowFilters ]
                    [ i [ class "fas fa-sliders-h"  ]
                        []
                    , text (if model.show_filter_options then " 隐藏筛选项" else " 显示筛选项")
                    ]
                , a [ class "btn btn-default btn-inline"
                , id "newPatientButton"
                , type_ "button"
                , Route.href Route.NewPatient
                --, href Request.External.newPatient
                ] 
                    [ i [ class "fas fa-user-plus" ]
                        []
                    , text " 新建患者"
                    ]
                ]
            ]
          , (if model.show_filter_options then filterOptions else (text ""))

  --未来的五天要用药
  --治疗逾期
  --心超逾期



        ]
        ]

view model =
  let
     modal =
      case model.form of
        Nothing -> text ""
        Just subModel -> (ExpressForm.viewAsModal CloseModal ExpressMsg subModel)

      
  in
      
  div [style [("padding", "50px"), ("padding-top", "20px")]]
  [ viewSearchArea model
  --,text (toString model)
  , viewTable model
  , modal
  ]
  
