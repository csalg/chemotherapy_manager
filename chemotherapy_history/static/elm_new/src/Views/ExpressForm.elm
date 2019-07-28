module Views.ExpressForm exposing(..)

import Date
import Html exposing (..)
import Html.Attributes exposing (style, class)
--import Style exposing(..)

import Bootstrap.Grid as Grid
import Bootstrap.Button as Button
import Bootstrap.Modal as Modal

import Material
import Material.Color as Color
import Material.Grid exposing (grid, cell, size, stretch, align, Align(..), Device(..))

import Styles exposing(..)
import Route
import Request.External as External
import Util exposing((=>))
import Constants exposing(constants)
import Data.Patient exposing(Patient, TherapyStatus(..))
import Data.Date
import Views.PatientInfoCard as Card exposing (CardBodyCell)
import Views.PatientInfoCard as Card exposing (..)
import Views.Modal as ModalView
import Views.PatientForms.Dose as DoseForm
import Views.PatientForms.Heart as HeartForm
import Views.PatientForms.PersonalInfo as PersonalInfoForm
import Views.PatientForms.TherapyStatus as TherapyStatusForm
--import Views.PatientProfileComponents exposing(..)
--import Views.ModalAlternative as ModalAlternative

type alias Model= 
    { id: Int
    , patient: Maybe Patient
    , form: Maybe PatientForm
    , heartReportReminder: Bool
    , endRoute: Route.Route
    }


type Msg = 
      SetForm PatientForm
    | PersonalInfoMsg PersonalInfoForm.Msg
    | DoseMsg DoseForm.Msg
    | HeartMsg HeartForm.Msg
    | TherapyStatusMsg TherapyStatusForm.Msg
    | ChangePage Route.Route

type PatientForm = 
        PersonalInfo PersonalInfoForm.Model
      | Dose DoseForm.Model
      | Heart HeartForm.Model
      | TherapyStatus TherapyStatusForm.Model


decisionTree patient heartReminded endRoute =
  let
    -- Info Items --
    infoItems = 
      [ (InfoItem (Just 4) [] "fas fa-female" iconGray (patient.patient_name++", "++(patient.patient_age)++" 岁") iconTxtGray)
      , (InfoItem (Just 3) [] "fas fa-medkit" iconGray patient.patient_therapy iconTxtGray)
      , (InfoItem (Just 5) [] "far fa-calendar-alt" iconGray patient.patient_frequency iconTxtGray)
      ]
      -- Footer Buttons --
    patientProfileButton = 
      Button.button [ Button.outlinePrimary, Button.onClick (ChangePage (Route.Patient patient.id)) ] 
        [ i [class "fas fa-user"] [], text " 查看患者材料" ]
    
    printButton = 
      a [ Html.Attributes.href (External.print patient.id)
        , class "btn btn-outline-primary"
        , style [("display", "flex"), ("align-items", "center")]
        ]
        [ i [class "material-icons", style [("padding-right", "2px"), ("font-size", "18px")]] [text "print"], text " 打印标签" ]
    
    newDoseButton = 
      let
        --init = DoseForm.initWithValues patient.id patient.patient_frequency patient.patient_maintenance_dose (Data.Date.dateToString patient.dt_now) patient.dose_weight patient.dose_remaining_dose (Data.Date.dateToString patient.dose_dt_opened) patient.dose_week endRoute
        init = DoseForm.initFromPatient patient endRoute
      in
        Button.button [ Button.success, Button.onClick (SetForm (Dose init)) ] 
          [ i [class "fas fa-vial "] [], text " 记录用药" ]

    newHeartExpiredButton = 
      Button.button [ Button.danger, Button.onClick (SetForm (Heart (HeartForm.initWithValues patient.id patient.heart_ago (Data.Date.dateToString patient.dt_now) endRoute))) ] 
        [ i [class "fas fa-heart "] [], text " 记录心超迟到的原因" ]
    newHeartButton = 
      Button.button [ Button.warning, Button.onClick (SetForm (Heart (HeartForm.initWithValues patient.id patient.heart_ago (Data.Date.dateToString patient.dt_now) endRoute))) ] 
        [ i [class "fas fa-heart "] [], text " 记录心超报告" ]
    changeTherapyStatusButton = 
      Button.button [ Button.primary, Button.onClick (SetForm (TherapyStatus (TherapyStatusForm.initWithValues patient.id (Data.Date.dateToString patient.dt_now) endRoute))) ] 
        [ i [class "fas fa-play-circle "] [], text " 改治疗状态" ]
    changeTemporaryHaltButton = 
      Button.button [ Button.danger
      , Button.onClick (SetForm (TherapyStatus (TherapyStatusForm.initWithValuesTemporaryHalt patient.id (Data.Date.dateToString patient.dt_now) endRoute)))
        ] 
        [ i [class "fas fa-play-pause "] [], text " 记录暂停用药原因" ]


      -- Heart and Dose logic --
    (doseItem, doseButton, doseOverrideOtherButtons) =
        (if patient.dose_ago < (0 - constants.take_dose_buffer)
        then (  if (((abs ((Date.toTime patient.therapy_dt) - (Date.toTime patient.dt_now))) > 24*60*60*1000) && patient.therapy_status == Active) || (((abs ((Date.toTime patient.therapy_dt) - (Date.toTime patient.dt_now))) < 24*60*60*1000) && patient.therapy_status /= Active)
                then 
                  ( (ImportantItem (Just 6) "fas fa-vial" colorDanger (span [] [ text "该患者", span [ style (colorDanger++horPadding1px)] [ text "超过预约" ], text "用药时间"]) "")
                  , [changeTemporaryHaltButton] 
                  , True)
                else 
                  ( (ImportantItem (Just 6) "fas fa-vial" colorWarning (span [] [ text "该患者", span [ style (colorDanger++horPadding1px)] [ text "超过预约" ], text "用药时间"]) "")
                  , [newDoseButton] 
                  , False)

             )
        else if patient.dose_ago > constants.take_dose_buffer
        then  ( (ImportantItem (Just 6) "fas fa-vial" colorPrimary (span [] [ text "还有 ", span [ style (colorPrimary++horPadding1px)] [ text ((toString (patient.dose_ago - constants.take_dose_buffer))++" 天") ], text " 患者能接受预约"]) "")
              , [printButton]
              , False
              )
        else ( (ImportantItem (Just 6) "fas fa-vial" colorSuccess (span [] [ text "该患者", span [ style (colorSuccess++horPadding1px)] [ text "能接受预约" ]]) "")
              , [newDoseButton]
              , False
              ))

    (heartItem, heartButton, heartOverrideOtherButtons) =
        (if patient.heart_ago < (Tuple.second constants.heart_report_range)
          then  ( ( ImportantItem (Just 6) "fas fa-heartbeat" colorDanger (span [] [ text "本次心超报告", span [ style (colorDanger++horPadding1px)] [ text "超过时间" ]]) "")
                , [newHeartExpiredButton]
                , True
                )
          else if patient.heart_ago > (Tuple.first constants.heart_report_range)
          then  ( (ImportantItem (Just 6) "fas fa-heartbeat" colorPrimary (span [] [ text "还有 ", span [ style (colorPrimary++horPadding1px)] [ text ((toString patient.heart_ago) ++" 天") ], text " 本次心超到期"]) "")
                , []
                , False
                )
          else  ( (ImportantItem (Just 6) "fas fa-heartbeat" colorWarning (span [] [ text "只有 ", span [ style (boldText++horPadding1px)] [ text ((toString patient.heart_ago) ++" 天本次心超到期") ]]) "alarm")
                , [newHeartButton]
                , False
                )
          )

    (importantItems , footerButtons ) =
      case patient.therapy_status of
        TemporaryHalt ->
          [ (ImportantItem (Just 6) "fas fa-pause" colorPrimary (span [] [ text "该患者", span [style (boldText++horPadding1px)] [ text "暂停治疗了" ]]) "")
          , (ImportantItem (Just 6) "fab fa-readme" colorPrimary (span [] [ text "原因： ", span [style (boldText++horPadding1px)] [ text patient.therapy_reason ]]) "")
          ]
          =>
          [patientProfileButton, changeTherapyStatusButton]
        Halt ->
          [ (ImportantItem (Just 6) "fas fa-stop" colorPrimary (span [] [ text "该患者", span [ style (boldText++horPadding1px)] [ text "终止治疗了" ]]) "")
          , (ImportantItem (Just 6) "fab fa-readme" colorPrimary (span [] [ text "原因： ", span [ style (boldText++horPadding1px)] [ text patient.therapy_reason ]]) "")
          ]
          =>
          [patientProfileButton, changeTherapyStatusButton]
        Finished ->
          [ (ImportantItem (Just 12) "fas fa-child" colorPrimary (span [] [ text "该患者已", span [style (boldText++horPadding1px)] [ text "完成所有治疗" ]]) "")
          ] 
          =>
          [patientProfileButton]
        Active -> 
          let
            buttons =
              if doseOverrideOtherButtons
              then ([patientProfileButton]++doseButton)
              else if heartOverrideOtherButtons
              then ([patientProfileButton]++heartButton)
              else ([patientProfileButton]++heartButton++doseButton)
          in
            [doseItem,heartItem] => buttons
  in
    (infoItems, importantItems , footerButtons)


initWithValues id patient dt_now endRoute = 
  let 
    shouldRemindHeartExam = patient.heart_ago < (Tuple.first constants.heart_report_range) && (patient.heart_ago > (Tuple.second constants.heart_report_range)) 
  in
    Model id (Just patient) Nothing shouldRemindHeartExam endRoute


--view model = 
--    case model.patient of 
--        Nothing -> text ""
--        Just patient ->
--            let
--                summary = 
--                    [ (CardBodyCell "姓名" patient.patient_name "" 4 [Color.background Color.white])
--                    , (CardBodyCell "年龄" patient.patient_age "岁" 4 [Color.background Color.white])
--                    , (CardBodyCell "维持剂量" (toString patient.patient_maintenance_dose) "毫克" 4 [Color.background Color.white])
--                    , (CardBodyCell "化疗方案" patient.patient_therapy "" 4 [Color.background Color.white])
--                    , (CardBodyCell "剂量频率" patient.patient_frequency "" 8 [Color.background Color.white])
--                    , (CardBodyCell "距离下次用药" (toString patient.dose_ago) "天" 4 (if patient.dose_ago >= 0 then [Color.background (Color.color Color.LightBlue Color.S50)] else [Color.background (Color.color Color.DeepOrange Color.S300)]))
--                    , (CardBodyCell "距离本药到期" (toString patient.expiry_ago) "天" 4 (if patient.expiry_ago >= 0 then [Color.background (Color.color Color.LightBlue Color.S50)] else [Color.background (Color.color Color.DeepOrange Color.S300)]))
--                    , (CardBodyCell "距离下次心超" (toString patient.heart_ago) "天" 4 (Card.colorRanger (Tuple.first constants.heart_report_range) (Tuple.second constants.heart_report_range) patient.heart_ago))
--                    ]
--                form = case model.form of
--                          Nothing -> text ""
--                          Just someForm ->
--                            case someForm of
--                              PersonalInfo subModel -> (PersonalInfoForm.viewAsForm subModel) |> Html.map PersonalInfoMsg
--                              Dose subModel -> (DoseForm.viewAsForm subModel) |> Html.map DoseMsg
--                              Heart subModel -> (HeartForm.viewAsForm subModel) |> Html.map HeartMsg
--                              TherapyStatus subModel -> (TherapyStatusForm.viewAsForm subModel) |> Html.map TherapyStatusMsg
--            in
--                Grid.container []
--                    [ grid []
--                      [ cell [Material.Grid.size All 12, Material.Grid.stretch, Material.Grid.align Middle] 
--                        [ Card.gridRender summary
--                        ]
--                      , cell [Material.Grid.size All 12, Material.Grid.stretch, Material.Grid.align Middle] 
--                        [text model.infoText]
--                      , cell [Material.Grid.size All 12, Material.Grid.stretch, Material.Grid.align Middle] 
--                        [form]
--                      ]
--                    ]

viewAsModal closeMsg msgWrapper model = 
  case model.patient of 
    Nothing -> text ""
    Just patient ->
      let 
        (infoItems , importantItems , footerButtons ) =
          decisionTree patient model.heartReportReminder model.endRoute

        renderer =
          ModalView.view msgWrapper closeMsg

        renderBody = 
              div [class "container"]
                [ div [class "container"]
                  [ div [class "mdl-cell--middle mdl-cell--stretch mdl-cell--12-col mdl-cell"]
                    [div [class "mdl-grid", style spaceBetween]
                        (List.map viewInfoItem infoItems)
                    ]
                  ]
                , hr [] []
                , div [class "container"]
                  [ div [class "mdl-cell--middle mdl-cell--stretch mdl-cell--12-col mdl-cell"]
                    [ div [class "mdl-grid", style spaceBetween]
                        (List.map viewImportantItem importantItems)
                    ]
                  ]
                ]
      in 
        case model.form of 
          Nothing -> renderer "fas fa-rocket" "快速检查" renderBody footerButtons (\x -> x)
          Just someForm ->
            case someForm of
              PersonalInfo subModel -> renderer "fa fa-user" "记录新的基本消息" (PersonalInfoForm.viewAsForm subModel) PersonalInfoForm.buttons PersonalInfoMsg
              Dose subModel -> renderer "fas fa-vial" "记录新的剂量" (DoseForm.viewAsForm subModel) DoseForm.buttons DoseMsg
              Heart subModel -> renderer "fas fa-heartbeat" "记录新的报告" (HeartForm.viewAsForm subModel) HeartForm.buttons HeartMsg
              TherapyStatus subModel -> renderer "far fa-play-circle" "改变状态" (TherapyStatusForm.viewAsForm subModel) TherapyStatusForm.buttons TherapyStatusMsg


update msg model =
  let
    toModal toModel toMsg subUpdate subMsg subModel =
      let
          ( newModel, newCmd ) =
              subUpdate subMsg subModel
      in
      ( { model | form = Just (toModel newModel) }, Cmd.map toMsg newCmd )
      
  in  
    case (msg, model.form) of
          (PersonalInfoMsg subMsg, Just (PersonalInfo subModel)) ->
            toModal PersonalInfo PersonalInfoMsg PersonalInfoForm.update subMsg subModel

          (DoseMsg subMsg, Just (Dose subModel)) ->
            toModal Dose DoseMsg DoseForm.update subMsg subModel

          (HeartMsg subMsg, Just (Heart subModel)) ->
            toModal Heart HeartMsg HeartForm.update subMsg subModel

          (TherapyStatusMsg subMsg, Just (TherapyStatus subModel)) ->
            toModal TherapyStatus TherapyStatusMsg TherapyStatusForm.update subMsg subModel
        
          (SetForm  form, _) -> 
            ({model | form = Just form}) => Cmd.none

          (ChangePage route, _) -> model => Route.newUrl route

          (_, _) -> model => Cmd.none
