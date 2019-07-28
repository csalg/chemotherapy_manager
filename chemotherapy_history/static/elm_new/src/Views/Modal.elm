module Views.Modal exposing(..)

import Html exposing(..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Style exposing(..)

import Bootstrap.Grid as Grid
import Bootstrap.Modal as Modal

import Styles exposing (..)
--import Util exposing ((=>), debug, stringToInt)
--import Route
--import Data.Patient exposing (Patient, TherapyStatus(..), patientDecoder)
--import Data.Date
--import Request.Patient as RequestHandler
--import Request.External
--import Views.PatientInfoCard as Card exposing (..)
--import Views.ExpressForm as ExpressForm
--import Views.PatientForms.Dose as DoseForm
--import Views.PatientForms.Heart as HeartForm
--import Views.PatientForms.PersonalInfo as PersonalInfoForm
--import Views.PatientForms.TherapyStatus as TherapyStatusForm
--import Constants exposing(constants)


view msgWrapper closeMsg icon title subView buttons msgToMap  =
    div []
      [ text ""
      , (Modal.config closeMsg
          |> Modal.large
          |> Modal.header [ style gray_bg] 
            [ h5 [class "modal-title"] 
              [i [class icon, style ([paddingRight (px 10)]++boldText)] [], text title]
            ]
          |> Modal.body [style whiteBg]
                [ Grid.containerFluid []
                  [ subView |> Html.map msgToMap |> Html.map msgWrapper
                  --, text (model |> toString)
                  ]
                ]
          |> Modal.footer [ style modalFooterStyle ] (buttons |> List.map (Html.map msgToMap) |>  List.map (Html.map msgWrapper))
          |> Modal.view Modal.shown)
      ]