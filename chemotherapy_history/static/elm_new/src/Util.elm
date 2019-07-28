module Util exposing (..)

import Html exposing (Attribute, Html, text, div)
import Html.Events exposing (defaultOptions, onWithOptions, on)
import Json.Decode as Decode
import Dict

import Constants exposing(constants)

(=>) : a -> b -> ( a, b )
(=>) =
    (,)


{-| infixl 0 means the (=>) operator has the same precedence as (<|) and (|>),
meaning you can use it at the end of a pipeline and have the precedence work out.
-}
infixl 0 =>


{-| Useful when building up a Cmd via a pipeline, and then pairing it with
a model at the end.

    session.user
        |> User.Request.foo
        |> Task.attempt Foo
        |> pair { model | something = blah }

-}
pair : a -> b -> ( a, b )
pair first second =
    first => second


viewIf : Bool -> Html msg -> Html msg
viewIf condition content =
    if condition then
        content
    else
        Html.text ""


onClickStopPropagation : msg -> Attribute msg
onClickStopPropagation msg =
    onWithOptions "click"
        { defaultOptions | stopPropagation = True }
        (Decode.succeed msg)


appendErrors : { model | errors : List error } -> List error -> { model | errors : List error }
appendErrors model errors =
    { model | errors = model.errors ++ errors }

--onInput : (String -> m) -> Property c m
onChange f =
    on "change" (Decode.map f Html.Events.targetValue)

debug str = if constants.debug_mode then (div [] [text str]) else (text "")

stringToInt val = val |> String.toInt |> (Result.withDefault 0)     

withMsg_ msgWrapper = Dict.map (\key val -> {val | inputArgs = ([onChange (msgWrapper val.fieldName)]++val.inputArgs)} )

valuesFromRecord stringAccessorPairs record =
  let
    listOfRecords     = List.repeat (List.length stringAccessorPairs) record
  in
    List.map2 (\(name, accessor) record -> accessor record) stringAccessorPairs listOfRecords

decodeStringToInt = 
  Decode.string
  |> Decode.map String.toInt
  |> Decode.map (Result.withDefault 0) 
