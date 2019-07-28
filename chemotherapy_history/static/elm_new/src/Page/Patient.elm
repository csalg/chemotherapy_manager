module Page.Patient exposing (..)

import Date
import Http
import Html exposing(..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Navigation
import Time exposing (Time)
import Task

import Material
import Material.Color as Color
import Material.Grid exposing (grid, cell, size, stretch, align, Align(..), Device(..))
import Material.Options as Options
import Material.Menu as Menu

import Bootstrap.Button as Button
import Bootstrap.Grid as Grid
import Bootstrap.Modal as Modal

import Util exposing ((=>), debug, stringToInt)
import Route
import Data.Patient exposing (Patient, TherapyStatus(..), patientDecoder, frequencyToShouldBeHidden)
import Data.Dose as Dose
import Data.Date
import Data.Bottle as Bottle
import Request.Patient as RequestHandler
import Request.Dose as DoseRequestHandler
import Request.External
import Views.PatientInfoCard as Card exposing (..)
import Views.ExpressForm as ExpressForm
import Views.Modal as ModalView
import Views.Bottle as BottleView
import Views.DoseTable as DoseTable
import Views.PatientForms.Dose as DoseForm
import Views.PatientForms.Heart as HeartForm
import Views.PatientForms.PersonalInfo as PersonalInfoForm
import Views.PatientForms.TherapyStatus as TherapyStatusForm
import Constants exposing(constants)



type alias Model = 
    { id        : Int
    , dt_now    : Date.Date
    , error     : Maybe String
    , patient   : Maybe Patient
    , modal     : Modals
    , postTo    : String
    , mdl       : Material.Model
    , doses     : List Dose.Dose
    }

type Modals = 
        Hidden 
      | PersonalInfo PersonalInfoForm.Model
      | Dose DoseForm.Model
      | Heart HeartForm.Model
      | TherapyStatus TherapyStatusForm.Model
      | Express ExpressForm.Model

type Msg = 
      Blank 
    | UpdateNow Time 
    | GetPatient Time
    | Fetched (Result Http.Error Patient) 
    | FetchedExpress (Result Http.Error Patient) 
    | FetchedDose (Result Http.Error (List Dose.Dose)) 
    | CloseModal
    | ShowModal Modals
    | GetPatientExpress Time
    | PersonalInfoMsg PersonalInfoForm.Msg
    | DoseMsg DoseForm.Msg
    | HeartMsg HeartForm.Msg
    | TherapyStatusMsg TherapyStatusForm.Msg
    | ExpressMsg ExpressForm.Msg
    | External String
    | Pass
    | Mdl (Material.Msg Msg)
    | ChangePage Route.Route


--model = {}

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let
          toModal toModel toMsg subUpdate subMsg subModel =
            let
                ( newModel, newCmd ) =
                    subUpdate subMsg subModel
            in
            ( { model | modal = toModel newModel }, Cmd.map toMsg newCmd )
  in
    case (msg, model.modal) of
        (GetPatient t, _) -> 
            let dt_now = Date.fromTime t
            in
                {model | dt_now= dt_now} 
                => ([ Http.send Fetched ( RequestHandler.get model.id dt_now )
                   , Http.send FetchedDose ( DoseRequestHandler.get model.id dt_now )
                   ]
                  |> Cmd.batch)

        (Fetched (Err err), _) ->
            {model | error = Just (toString err)} => Cmd.none

        (Fetched (Ok new_patient), _) ->
            {model | patient = Just new_patient} => Cmd.none

        (FetchedDose (Err err), _) ->
            {model | error = Just (toString err)} => Cmd.none

        (FetchedDose (Ok new_doses), _) ->
            {model | doses = new_doses} => Cmd.none

        (GetPatientExpress t, _) -> 
            let dt_now = Date.fromTime t
            in
                {model | dt_now= dt_now} 
                => Http.send FetchedExpress ( RequestHandler.get model.id dt_now )

        (FetchedExpress (Err err), _) ->
            {model | error = Just (toString err)} => Cmd.none

        (FetchedExpress (Ok new_patient), _) ->
            {model | patient = Just new_patient, modal = Express (ExpressForm.initWithValues model.id new_patient model.dt_now (Route.PatientWithExpress model.id))} => Cmd.none

        (CloseModal, _) -> 
          {model | modal = Hidden} => Cmd.none

        (ShowModal  modal, _) -> 
          ({model | modal = modal}) => Cmd.none
          --Dose -> ({model | modal = modal, postTo= constants.postTo.updateDose}) => Cmd.none
          --Heart -> ({model | modal = modal, postTo= constants.postTo.updateHeart}) => Cmd.none
          --Stop -> ({model | modal = modal, postTo= constants.postTo.updateStop}) => Cmd.none
          --Hidden -> ({model | modal = modal, postTo= ""}) => Cmd.none
      
        (PersonalInfoMsg subMsg, PersonalInfo subModel) ->
          toModal PersonalInfo PersonalInfoMsg PersonalInfoForm.update subMsg subModel

        (DoseMsg subMsg, Dose subModel) ->
          toModal Dose DoseMsg DoseForm.update subMsg subModel

        (HeartMsg subMsg, Heart subModel) ->
          toModal Heart HeartMsg HeartForm.update subMsg subModel

        (TherapyStatusMsg subMsg, TherapyStatus subModel) ->
          toModal TherapyStatus TherapyStatusMsg TherapyStatusForm.update subMsg subModel

        (ExpressMsg subMsg, Express subModel) ->
          toModal Express ExpressMsg ExpressForm.update subMsg subModel

        (Mdl message_, _) -> Material.update Mdl message_ model

        (External lnk, _) -> model => Navigation.load lnk

        (ChangePage route, _) -> model => Route.newUrl route

        _ -> model => Cmd.none

init: Int -> Model
init pid = Model pid (Date.fromTime 0) Nothing Nothing Hidden "" Material.model []

--initWithExpressModal pid dt_now = 
--  let
--    init_ = init pid
--  in
--    {init_ | modal = Express (ExpressForm.initWithValues init_.id init_.patient dt_now)}

initTask = Task.perform GetPatient Time.now
initTaskExpressModal = Task.perform GetPatientExpress Time.now
--initTask = Task.perform GetPatient Time.now

--initTaskExpressModal = Task.andThen (Task.perform GetPatient Time.now) (Task.attempt ShowExpressFromPatient)

colorRanger: Int -> Int -> Int -> List (Options.Property c m)
colorRanger lower upper val  = 
    let
        lt = (if lower < upper then (<) else (>) )
        gt = (if lower < upper then (>) else (<) )
    in

      if      (lt val lower)                 then 
        [Color.background (Color.color Color.LightBlue Color.S50)]
      else if (gt val lower && lt val upper ||val == lower) then 
        [Color.background (Color.color Color.Amber Color.S300)]
      else                                       
        [Color.background (Color.color Color.DeepOrange Color.S300)]


view model =
    case model.patient of
        Nothing -> text "本患者不存在或者你不能看到她的消息"
        Just patient ->                   
            let
                menuRenderFunction model idx = Menu.render Mdl [idx] model.mdl

                ifIsActive x = if patient.therapy_status == Active then x else []

                doseAgoColorRanger =  if patient.patient_frequency == "三周一次"
                                      then (colorRanger 14 18)
                                      else (colorRanger 4 6)

                pInfoList = [ (CardBodyCell "姓名" patient.patient_name "" 4 [Color.background Color.white])
                            , (CardBodyCell "年龄" patient.patient_age "岁" 4 [Color.background Color.white])
                            , (CardBodyCell "磁卡号" patient.patient_card "" 4 [Color.background Color.white])
                            , (CardBodyCell "化疗方案" patient.patient_therapy "" 4 [Color.background Color.white])
                            , (CardBodyCell "剂量频率" patient.patient_frequency "" 8 [Color.background Color.white])
                            , (CardBodyCell "首次剂量" (toString patient.patient_initial_dose) "" 4 [Color.background Color.white])
                            , (CardBodyCell "维持剂量" (toString patient.patient_maintenance_dose) "" 4 [Color.background Color.white])
                            , (CardBodyCell "氯化钠注射液" (toString patient.patient_nacl_amount) "ml" 4 [Color.background Color.white])
                            , (CardBodyCell "首次剂量时期" (Data.Date.dateToString patient.patient_initial_dose_dt) "" 6 [Color.background Color.white])
                            ]

                dInfoList =  [ (CardBodyCell "距离下次用药" (toString patient.dose_ago) "天" 6 (if patient.dose_ago >= 0 then [Color.background (Color.color Color.LightBlue Color.S50)] else [Color.background (Color.color Color.DeepOrange Color.S300)]))
                              , (CardBodyCell "距离本药到期" (toString patient.expiry_ago) "天" 6 (if patient.expiry_ago >= 0 then [Color.background (Color.color Color.LightBlue Color.S50)] else [Color.background (Color.color Color.DeepOrange Color.S300)]))
                              , (CardBodyCell "最新用药日期" (Data.Date.dateToString patient.dose_dt) "" 6 [Color.background Color.white])
                              , (CardBodyCell "下次用药日期" (Data.Date.dateToString patient.dose_next_appointment_dt) "" 6 [Color.background Color.white])
                              , (CardBodyCell "本药开封日期" (Data.Date.dateToString patient.dose_dt_opened) "" 6 [Color.background Color.white])
                              , (CardBodyCell "本药到期日期" (Data.Date.dateToString patient.dose_dt_opened_expiry) "" 6 [Color.background Color.white])
                              , (CardBodyCell "体重" (toString patient.dose_weight) "公斤" 4 [Color.background Color.white])
                              , (CardBodyCell "剂量" (toString patient.dose_amount) "毫克" 4 [Color.background Color.white])
                              , (CardBodyCell "使用后剩余量" (toString patient.dose_remaining_dose) "毫克" 4 [Color.background Color.white])
                              , (CardBodyCell "第几次用药" (toString patient.dose_number) "" 4 [Color.background Color.white])
                              ]++ (if (frequencyToShouldBeHidden patient.patient_frequency) then [] else 
                                [ (CardBodyCell "周期内第几次用药" (toString patient.dose_number_cycle) "" 4 [Color.background Color.white])])
                              ++ (if patient.dose_remarks == "" then [] else 
                                [ (CardBodyCell "备注" patient.dose_remarks "" 12 [Color.background Color.white])])

                hInfoList = [ (CardBodyCell "距离下次心超" (toString patient.heart_ago) "天" 6 (colorRanger (Tuple.first constants.heart_report_range) (Tuple.second constants.heart_report_range) patient.heart_ago))
                            , (CardBodyCell "心超报告" patient.heart_text "" 6 [Color.background Color.white])
                            , (CardBodyCell "心超日期" (Data.Date.dateToString patient.heart_dt) "" 6 [Color.background Color.white])
                            , (CardBodyCell "左心射血分数" patient.heart_percentage "%" 6 [Color.background Color.white])
                            ]++ (if patient.heart_remarks == "" then [] else 
                            [ (CardBodyCell "备注" patient.heart_remarks "" 12 [Color.background Color.white])])


                tInfoList = [ (CardBodyCell "治疗状态" (Data.Patient.statusToString patient.therapy_status) "" 6 [Color.background Color.white])
                            , (CardBodyCell "最新纪录日期" (Data.Date.dateToString patient.therapy_dt) "" 6 [Color.background Color.white])
                            ]++ (if patient.therapy_reason == "" then [] else 
                            [ (CardBodyCell "原因" patient.therapy_reason "" 12 [Color.background Color.white])])
                            ++ (if patient.therapy_remarks == "" then [] else 
                            [ (CardBodyCell "备注" patient.therapy_remarks "" 12 [Color.background Color.white])])

                pMenuList = [ MenuBtn "history" "查看历史" (External (Request.External.personalHistory patient.id))
                            --, MenuBtn "print" "打印标签" (External constants.links.namePDF)
                            ]
                            ++ (ifIsActive
                              (
                                  [MenuBtn "add_circle_outline" "记录新的消息" (ShowModal (PersonalInfo (PersonalInfoForm.initWithValues patient patient.id (Route.Patient model.id))))
                                  ])
                              )

                dMenuList = [ MenuBtn "history" "查看历史" (External (Request.External.doseHistory patient.id))
                            , MenuBtn "print" "打印标签"  (External (Request.External.print patient.id))]
                            ++ (ifIsActive
                              (
                                  let
                                    init = DoseForm.initFromPatient patient (Route.Patient model.id)

                                  in
                                  [MenuBtn "add_circle_outline" "记录新的剂量" (ShowModal (Dose init))]
                              )
                              )

                hMenuList = [ ((MenuBtn) "history" "查看历史" (External (Request.External.heartHistory patient.id)))]
                            ++ (ifIsActive
                              (case model.patient of
                                Nothing -> []
                                Just patient ->
                                  [MenuBtn "add_circle_outline" "记录新的报告" (ShowModal (Heart (HeartForm.initWithValues patient.id patient.heart_ago (Data.Date.dateToString model.dt_now) (Route.Patient model.id))))]
                              )
                              )

                tMenuList = [ ((MenuBtn) "history" "查看历史" (External constants.links.therapyHistory))]
                            ++ 
                              (case model.patient of
                                Nothing -> []
                                Just patient ->
                                  [MenuBtn "add_circle_outline" "改变状态" (ShowModal (TherapyStatus (TherapyStatusForm.initWithValues patient.id (Data.Date.dateToString model.dt_now) (Route.Patient model.id))))]
                              )
                         
                renderModal = 
                  let 
                      renderer =
                        ModalView.view identity CloseModal

                      --renderer title subView msgWrapper =
                      --  div []
                      --    [ text ""

                      --    , (Modal.config CloseModal
                      --        |> Modal.large
                      --        |> Modal.h5 [] [ text title ]
                      --        |> Modal.body []
                      --              [ Grid.containerFluid []
                      --                [ subView |> Html.map msgWrapper]
                      --              ]
                                    --]]
                              --|> Modal.footer []
                              --    [ Button.button
                              --        [ Button.outlinePrimary
                              --        , Button.attrs [ type "submit" ]
                              --        ]
                              --        [ text "Close" ]
                          --    --    ]
                          --    |> Modal.view Modal.shown)
                          --]
                  in 
                    case model.modal of
                      PersonalInfo subModel ->  renderer "fa fa-user" "记录新的基本消息" (PersonalInfoForm.viewAsForm subModel) PersonalInfoForm.buttons PersonalInfoMsg
                      Dose subModel -> renderer "fas fa-vial" "记录新的剂量" (DoseForm.viewAsForm subModel) DoseForm.buttons DoseMsg
                      Heart subModel -> renderer "fas fa-heartbeat" "记录新的报告" (HeartForm.viewAsForm subModel) HeartForm.buttons HeartMsg
                      TherapyStatus subModel -> renderer "far fa-play-circle" "改变状态" (TherapyStatusForm.viewAsForm subModel) TherapyStatusForm.buttons TherapyStatusMsg



                      --renderer "记录新的基本消息" (PersonalInfoForm.viewAsForm subModel) PersonalInfoMsg
                      --Dose subModel -> renderer "记录新的剂量" (DoseForm.viewAsForm subModel) DoseMsg
                      --Heart subModel -> renderer "记录新的报告" (HeartForm.viewAsForm subModel) HeartMsg
                      --TherapyStatus subModel -> renderer "改变状态" (TherapyStatusForm.viewAsForm subModel) TherapyStatusForm.buttons  TherapyStatusMsg
                      ----Express subModel -> (ExpressForm.viewAsModal CloseModal ExpressMsg subModel)
                      ----Express subModel -> renderer "快速检查" (ExpressForm.view subModel) "" ExpressMsg
                      _ -> text ""
            in      
                Grid.container []
                    [ div [ style [("width", "100%"), ("display", "flex"), ("justify-content", "center")]]
                    [ grid []
                      [ cell [Material.Grid.size All 6, stretch, Material.Grid.align Middle] 
                            [ Card.view (PatientInfoCard "person" "基本信息" 1 pMenuList pInfoList) model menuRenderFunction
                            , div [style [("margin-top", "15px")]] [Card.view (PatientInfoCard "favorite" "心超报告" 2 hMenuList hInfoList) model menuRenderFunction]
                            ]

                      , cell [Material.Grid.size All 6, stretch, Material.Grid.align Middle]
                          [ Card.view (PatientInfoCard "assignment" "用药信息" 3 dMenuList dInfoList) model menuRenderFunction
                          , div [style [("margin-top", "15px")]] [Card.view (PatientInfoCard "autorenew" "治疗状态" 4 tMenuList tInfoList) model menuRenderFunction]
                          ]
                      , cell [Material.Grid.size All 12, stretch, Material.Grid.align Middle]
                          [ div [style [("width", "100%"), ("display", "flex"),("justify-content", "center")]]
                            [ Button.button
                                [ Button.primary
                                , Button.onClick (ChangePage (Route.Patients))
                                --, Button.attrs [ type_ "submit" ]
                                , Button.attrs [style [("margin", "0 20px 0 20px")]]
                                ]
                                [ i [class "fas fa-users"] [], text " 回到患者单" ]
                            , Button.button
                                [ Button.primary
                                , Button.onClick (ShowModal (Express (ExpressForm.initWithValues model.id patient model.dt_now (Route.PatientWithExpress model.id))))
                                --, Button.attrs [ type_ "submit" ]
                                , Button.attrs [style [("margin", "0 20px 0 20px")]]
                                ]
                                [ i [class "fas fa-rocket"] [], text " 快速检查" ]
                            ]
                          ]
                        ]
                      ]
                      , renderModal
                      , debug (toString model)
                      , br [] []
                      , br [] []
                      , br [] []
                      , br [] []
                    ]

view2 model =

  case model.patient of
    Nothing -> text "本患者不存在或者你不能看到她的消息"
    Just patient ->   
      let
        -- Only interested in the importantItems
        (infoItems, importantItems , footerButtons) =
          ExpressForm.decisionTree patient True Route.Patients

        importantInfo = {profileSectionInit | 
            --header = Header "快速检查" "fas fa-user-tie" ""
           contentRows = [(List.map viewImportantItem importantItems)]
        }

        personalInfo = {profileSectionInit | 
          header = Just (Header "基本信息" "fas fa-user-tie" "")
          , contentRows = 
            [ [ InfoItem (Just 6) [] "fas fa-female" [] (patient.patient_name++", "++patient.patient_age++" 岁")  []
              , InfoItem (Just 6) [] "far fa-id-card"  [] patient.patient_card  []
              ] 
              , [ InfoItem (Just 6) [] "fas fa-medkit" [] patient.patient_therapy  []
              , InfoItem (Just 6) [] "far fa-calendar-alt"  [] patient.patient_frequency  []
              ] 
            ] |> List.map (List.map viewProfileInfoItem)
          }

        --history = 
        --  {profileSectionInit | header = Just(Header "最新用药信息" "fas fa-pills" "")
        --      }

        heart = 
          {profileSectionInit | header = Just(Header "心超报告" "fas fa-heartbeat" "")
          , contentRows = 
            ([ [ InfoItem (Just 9) [] "fas fa-female" [] patient.heart_text  []
              , InfoItem (Just 3) [] "far fa-id-card"  [] patient.heart_percentage  []
              ] ] |> List.map (List.map viewProfileInfoItem))
              }


        dose = 
          {profileSectionInit | header = Just(Header "最新用药信息" "fas fa-pills" "")
          , contentRows = 
            ([ [ InfoItem (Just 4) [] "fas fa-female" [] (patient.dose_weight |> toString)  []
              , InfoItem (Just 4) [] "far fa-id-card"  [] (patient.dose_amount |> toString)  []
              , InfoItem (Just 4) [] "far fa-id-card"  [] (patient.dose_remaining_dose |> toString)  []
              ] 
            , [ InfoItem (Just 6) [] "fas fa-female" [] (patient.dose_dt_opened |> Data.Date.dateToString)  []
              , InfoItem (Just 6) [] "fas fa-female" [] (patient.dose_dt_opened_expiry |> Data.Date.dateToString)  []
              ]
              ]  |> List.map (List.map viewProfileInfoItem))
              }

        doses = 
          {profileSectionInit | header = Just(Header "最近用药历史" "fas fa-pills" "")
              , contentRows = [[DoseTable.view model.doses]]
              }


                --tInfoList = [ (CardBodyCell "治疗状态" (Data.Patient.statusToString patient.therapy_status) "" 6 [Color.background Color.white])
                --            , (CardBodyCell "最新纪录日期" (Data.Date.dateToString patient.therapy_dt) "" 6 [Color.background Color.white])
                --            ]++ (if patient.therapy_reason == "" then [] else 
                --            [ (CardBodyCell "原因" patient.therapy_reason "" 12 [Color.background Color.white])])
                --            ++ (if patient.therapy_remarks == "" then [] else 
                --            [ (CardBodyCell "备注" patient.therapy_remarks "" 12 [Color.background Color.white])])


      in
        
      div [ class "container" ]
          [ div [ class "line profile-wrapper" ]
              --[ div [ class "x12" ] [(viewProfileSection importantInfo)]
              [ div [ class "x6" ]
                  [ viewProfileSection personalInfo]
              , div [ class "x6" ] 
                  [ viewProfileSection dose ]
              , div [class "x12" ] 
                  [viewProfileSection doses ]
              , div [class "x6" ] 
                  [viewProfileSection heart ]
                  --[ div [ class "profile-section border box-shadow-small" ]
                  --    [ h5 [ class "info-header" ]
                  --        [ i [ class "fas fa-pills info-header-icon" ]
                  --            []
                  --        , span [ class "info-header-text" ]
                  --            [ text "用药信息" ]
                  --        ]
                  --    ]
                  ]
              , debug (toString model)
              ]
