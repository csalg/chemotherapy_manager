module Views.Bottle exposing(..)

import Date
import Html exposing(..)
import Html.Attributes exposing(..)


import Material.Table as Table
import Material.Elevation as Elevation
import Material.Options as Options exposing(css)
import Material.Scheme as Scheme
import Material.Color as Color

import Styles exposing(..)
import Data.Bottle as Bottle
import Data.Date

type alias Bottle =
    { amount: Int
    , remaining: Int
    , dt: Date.Date
    , opened: Date.Date
    , expiry: Date.Date
    , number : Int
    }


view bottleList =
    let fields = 
        [ (.number >> toString,  "瓶数", [], [])
        , (.amount >> toString,  "剂量", [], [])
        , (.remaining >> toString,  "该瓶剩余", [], [])
        , (.opened >> Data.Date.dateToString,  "开封日期", [], [])
        , (.expiry >> Data.Date.dateToString,  "失效日期", [], [])
        ]
    in
        (div [style bottleListReposition]
            [ h6 [style bottleHeader] [i [class "fas fa-prescription-bottle", style newPatientFooterIcon] [], span [] [text "药品清单"]]
            , Table.table [css "width" "100%", Elevation.e2]
                  [ Table.thead [ Options.css "background-color" "white"]
                    [ Table.tr []
                        ( fields
                            |> List.map (\(accessor, field_name, th_attr, td_attr)
                                     -> Table.th th_attr [ text field_name ])
                            )
                    ]
                  , Table.tbody []
                        (bottleList
                            |> List.map (\bottle ->
                                 Table.tr []
                                    ( fields
                                        |> List.map (\(accessor, field_name, th_attr, td_attr)
                                            -> Table.td td_attr [ text (accessor bottle) ])
                                    )
                               ))
                  ]
                  ])
