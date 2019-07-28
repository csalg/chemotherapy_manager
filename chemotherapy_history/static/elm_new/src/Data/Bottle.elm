module Data.Bottle exposing (..)

import Date
import Http
import Json.Encode as Encode exposing(int,string)

import Data.Date exposing(addDays)
import Constants exposing(constants)

type alias Bottle =
    { amount: Int
    , remaining: Int
    , dt: Date.Date
    , opened: Date.Date
    , expiry: Date.Date
    , number : Int
    }


init = Bottle 0 0 (Date.fromTime 0) (Date.fromTime 0) (Date.fromTime 0) 0

encode : Bottle -> Encode.Value
encode bottle_ =            
    let
        bottle =  { bottle_ 
                        | dt     = bottle_.dt       |> Data.Date.dateToString
                        , opened = bottle_.opened   |> Data.Date.dateToString
                        , expiry = bottle_.expiry   |> Data.Date.dateToString
                    }
    in
        Encode.object
            [ ("amount", int bottle.amount)
            , ("remaining", int bottle.remaining)
            , ("dt", string bottle.dt)
            , ("opened", string bottle.opened)
            , ("expiry", string bottle.expiry)
            , ("number", int bottle.number)
            ]

encodeList bottleLst =
    bottleLst
        |> List.map encode
        |> Encode.list 
        --|> Http.jsonBody



calculateBottles dose_amount dose_remaining_ first_bottle_dt_ dt=
  let
    (dose_remaining, first_bottle_dt) =    if ((first_bottle_dt_ |> Data.Date.addDays constants.drug_shelf_life_days |> Date.toTime) > (dt |> Date.toTime))
                        then (dose_remaining_, first_bottle_dt_)
                        else (constants.single_bottle_dosage, dt)
    innerFold dose_left dose_remaining_in_bottle number acc=
      if dose_left == 0
      then acc
      else
        (if dose_remaining_in_bottle > dose_left
        then acc++
          [ { amount= dose_left
            , remaining = dose_remaining_in_bottle - dose_left
            , dt = dt
            , opened = dt
            , expiry= addDays constants.drug_shelf_life_days dt
            , number = number 
            }
          ] |> innerFold 0 (dose_remaining_in_bottle - dose_left) (number+1)
        else if dose_remaining_in_bottle < dose_left
        then
          acc++
            [ { amount= dose_remaining_in_bottle
            , remaining = 0
            , dt = dt
            , opened = dt
            , expiry= addDays constants.drug_shelf_life_days dt 
            , number = number
            }
            ] |> innerFold (dose_left - dose_remaining_in_bottle) 440 (number+1)
        else
          innerFold dose_left 440 (number+1) acc) 
  in
    if (dose_remaining - dose_amount >= 0)
    then 
      [ { amount= dose_amount
        , remaining= dose_remaining - dose_amount
        , dt= dt
        , opened= first_bottle_dt
        , expiry= addDays constants.drug_shelf_life_days first_bottle_dt 
        , number = 1
        }
      ]
      else
      ( [ { amount= dose_remaining
          , remaining= 0
          , dt= dt
          , opened= first_bottle_dt
          , expiry= addDays constants.drug_shelf_life_days first_bottle_dt
          , number = 1
          } 
        ]
        |> innerFold (dose_amount-dose_remaining) constants.single_bottle_dosage 2)

lastBottleRemaining bottleList =
    case (bottleList |> List.reverse |> List.head) of
        Nothing -> 0
        Just lastBottle -> lastBottle.remaining

lastBottleDate bottleList =
        case (bottleList |> List.reverse |> List.head) of
        Nothing -> Date.fromTime 0
        Just lastBottle -> lastBottle.opened

isNewBottle previous_dt new_dt bottleLst =
    (not ((Date.toTime (lastBottleDate bottleLst)) == (Date.toTime previous_dt)) )