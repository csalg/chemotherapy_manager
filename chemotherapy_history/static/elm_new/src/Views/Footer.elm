module Views.Footer exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http

import Constants exposing (..)
import Types exposing (..)

type ButtonAction msg = External String | Internal msg | Pass

type alias Btn msg = 
            { btnType: String
            , faClass: String
            , txt: String
            , action: ButtonAction msg

            }

btnRender: Btn -> Html Msg
btnRender btn = 
  let
  clk = case btn.action of
      Internal msg -> [(onClick msg)]
      Pass -> []  
      External lnk -> [(href lnk)]  
  args = List.append clk [ type_ btn.btnType, class "btn btn-default btn-inline"]
  contents = ([ i
              [ class btn.faClass ]
                []
                , text btn.txt
              ])
    in 
  case btn.action of
    External _ -> a args contents
    _ -> button args contents

personalViewViewFooter = 
  [ Btn "button" "fas fa-clock" "查看历史"  (External constants.links.personalHistory)
  , Btn "button" "fas fa-print" "打印标签" (External constants.links.namePDF)
  , Btn "button" "far fa-plus-square" "添加更新" Pass
  ]


personalViewEditFooter = 
  [ Btn "button" "fas fa-undo-alt" "回到患者消息" Pass
  , Btn "submit" "fas fa-check" "提交" Pass
  ]

doseViewViewFooter = 
  [ Btn "button" "far fa-times-circle" "停药" Pass
  , Btn "button" "fas fa-clock" "查看历史" (External constants.links.doseHistory)
  , Btn "button" "fas fa-print" "打印单子"  (External constants.links.dosePDF)
  , Btn "button" "far fa-file" "记录剂量" Pass
  ]

heartViewViewFooter = 
  [ Btn "button" "fas fa-clock" "查看历史"  (External constants.links.heartHistory)
  , Btn "button" "far fa-file" "记录新的报告" Pass
  ]


footerRender btnList=
  div
                    [ class "panel-footer", style [("text-align", "right")] ]
                    [ div
                        [ class "row" ]
                        (List.map btnRender btnList)
                    ]