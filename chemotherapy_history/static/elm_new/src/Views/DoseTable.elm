module Views.DoseTable exposing (..)

import Html exposing(..)
import Html.Attributes exposing (..)
import Material
import Material.Options as Options exposing (css)
import Material.Color as Color
import Material.List as Lists
import Material.Button as Button
import Material.Typography as Typo
import Material.Table as Table

import Data.Dose as Dose

view doses =
  let fields = 
    [ "dose_number"
    , "dose_amount"
    , "dose_dt"
    , "dose_remarks"
    ]
  in
    Table.table [css "width" "100%"]
      [ Table.thead []
        [ Table.tr [ Options.css "background-color" "white"]
            ( fields
                |> List.map Dose.toChinese
                |> List.map (\(field_name)
                         -> Table.th [] [ text field_name ])
                )
        ]
      , Table.tbody []
            (doses
                |> List.map (\dose ->
                     Table.tr []
                        ( fields
                            |> List.map (\(field_name)
                                -> Table.td [] [ text (Dose.getValue dose field_name) ])
                        )
                   ))
      ]
viewWithInit = view [Dose.init, Dose.init]