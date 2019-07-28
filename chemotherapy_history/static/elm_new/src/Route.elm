module Route exposing (Route(..), fromLocation, href, modifyUrl, newUrl)

import Html exposing (Attribute)
import Html.Attributes as Attr
import Navigation exposing (Location)
import UrlParser as Url exposing ((</>), Parser, oneOf, parseHash, s, int)


-- ROUTING --


type Route
    = Root
    | Patients
    | PatientsWithExpress Int
    | Patient Int
    | PatientWithExpress Int
    | NewPatient

route : Parser (Route -> a) a
route =
    oneOf
        [ Url.map Root (s "")
        , Url.map Patients (s "patients")
        , Url.map PatientsWithExpress (s "patients" </> int)
        , Url.map Patient (s "patient" </> int)
        , Url.map PatientWithExpress (s "patient" </> int </> s "express")
        , Url.map NewPatient (s "newpatient")
        ]


-- INTERNAL --


routeToString : Route -> String
routeToString page =
    let
        pieces =
            case page of
                Root ->
                    []

                Patients ->
                    [ "patients" ]

                PatientsWithExpress p ->
                    [ "patients",toString p ]

                Patient p ->
                    [ "patient", toString p ]

                PatientWithExpress p ->
                    [ "patient", toString p,"express" ]

                NewPatient ->
                    [ "newpatient" ]

    in
    "#/" ++ String.join "/" pieces



-- PUBLIC HELPERS --


href : Route -> Attribute msg
href route =
    Attr.href (routeToString route)


modifyUrl : Route -> Cmd msg
modifyUrl =
    routeToString >> Navigation.modifyUrl

newUrl =
    Navigation.newUrl << routeToString

fromLocation : Location -> Maybe Route
fromLocation location =
    if String.isEmpty location.hash then
        Just Root
    else
        parseHash route location
