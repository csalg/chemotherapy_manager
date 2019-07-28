module Main exposing (main)

import Html exposing (..)
import Json.Decode as Decode exposing (Value)
import Navigation exposing (Location)
import Route exposing (Route)
import Task
import Date
import Time exposing(Time)

import Util exposing ((=>))
import Page.NewPatient as NewPatient
import Page.NotFound as NotFound
import Page.Patient as Patient
import Page.Patients as Patients
import Route

--
type Page
    = Blank
    | NotFound
    --| Errored PageLoadError
    | Patients Patients.Model
    | Patient Patient.Model
    | NewPatient NewPatient.Model


-- MODEL --


type alias Model =
    { page : Page
    , patients: Maybe Int
    , dt_now: Time
    , csrf: String
    }


-- INIT ---


initialPage : Page
initialPage =
    Blank


init : String -> Location -> ( Model, Cmd Msg )
init val location =
    setRoute (Route.fromLocation location)
        { page = initialPage
        , patients= Nothing
        , dt_now = 0
        , csrf = val
        }


-- VIEW --


view : Model -> Html Msg
view model =
    case model.page of
        NotFound ->
            NotFound.view

        Blank ->
            -- This is for the very initial page load, while we are loading
            -- data via HTTP. We could also render a spinner here.
            Html.text ""

        --Errored subModel ->
        --    Errored.view subModel

        Patients subModel ->
            Patients.view subModel
                |> Html.map PatientsMsg

        Patient subModel ->
            Patient.view subModel
                |> Html.map PatientMsg

        NewPatient subModel ->
            NewPatient.view subModel
                |> Html.map NewPatientMsg

-- UPDATE --


type Msg
    = SetRoute (Maybe Route)
    | PatientsMsg Patients.Msg
    | PatientMsg Patient.Msg
    | NewPatientMsg NewPatient.Msg
    | DTNow Time

setRoute : Maybe Route -> Model -> ( Model, Cmd Msg )
setRoute maybeRoute model =

    case maybeRoute of
        Nothing ->
            { model | page = NotFound } => Cmd.none

        Just Route.Root ->
            model => Route.modifyUrl Route.Patients

        Just Route.Patients ->
            { model | page = Patients Patients.init } => Cmd.map PatientsMsg Patients.initTask
        
        Just (Route.PatientsWithExpress p) ->
            { model | page = Patients Patients.init } => Cmd.map PatientsMsg (Patients.initTaskWithExpress p)

        Just ( Route.Patient p ) ->
            { model | page = (Patient (Patient.init p)) } => Cmd.map PatientMsg Patient.initTask
       
        Just ( Route.PatientWithExpress p ) ->
            { model | page = Patient (Patient.init p) } => Cmd.map PatientMsg Patient.initTaskExpressModal

        Just Route.NewPatient ->
            { model | page = NewPatient NewPatient.init } => Cmd.map NewPatientMsg NewPatient.initTask


--pageErrored : Model -> ActivePage -> String -> ( Model, Cmd msg )
--pageErrored model activePage errorMessage =
--    let
--        error =
--            Errored.pageLoadError activePage errorMessage
--    in
--    { model | pageState = Loaded (Errored error) } => Cmd.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        page = model.page

        toPage toModel toMsg subUpdate subMsg subModel =
            let
                ( newModel, newCmd ) =
                    subUpdate subMsg subModel
            in
            ( { model | page = toModel newModel }, Cmd.map toMsg newCmd )

        --errored =
        --    pageErrored model
    in
    case (msg, page) of
        ( SetRoute route, _ ) ->
            setRoute route model

        ( PatientsMsg subMsg, Patients subModel )  ->
            toPage Patients PatientsMsg Patients.update subMsg subModel

        ( PatientMsg subMsg, Patient subModel )  ->
            toPage Patient PatientMsg Patient.update subMsg subModel

        ( NewPatientMsg subMsg, NewPatient subModel )  ->
            toPage NewPatient NewPatientMsg NewPatient.update subMsg subModel

        ( _, NotFound ) ->
            -- Disregard incoming messages when we're on the
            -- NotFound page.
            model => Cmd.none

        ( DTNow dt, _ ) ->
            { model | dt_now = dt } => Cmd.none


        ( _, _ ) ->
            -- Disregard incoming messages that arrived for the wrong page
            model => Cmd.none



-- MAIN --


main : Program String Model Msg
main =
    Navigation.programWithFlags (Route.fromLocation >> SetRoute)
        { init = init
        , view = view
        , update = update
        , subscriptions = (\_ -> Sub.none)
        }
