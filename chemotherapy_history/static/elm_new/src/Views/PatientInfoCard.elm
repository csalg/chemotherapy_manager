module Views.PatientInfoCard exposing (..)

import Html exposing(..)
import Html.Attributes exposing (..)
import Style exposing(Style)
import Material.Card as Card
import Material
import Material.Options as Options exposing (css)
import Material.Color as Color
import Material.List as Lists
import Material.Button as Button
import Material.Typography as Typo
import Material.Icon as Icon
import Material.Menu as Menu
import Material.Grid exposing (grid, cell, size, stretch, align, Align(..), Device(..))


-- TYPES --

type alias PatientInfoCard msg =
    { icn: String
    , txt: String
    , idx: Int
    , menuList: List (MenuBtn msg)
    , cellList: List (CardBodyCell msg)
    }

type alias MenuBtn msg =
    { icn: String
    , txt: String
    , act: msg
    }

type alias CardBodyCell msg = 
    { labl: String
    , val: String
    , valueUnit: String
    , wdth: Int
    , cellAttr: List (Options.Style msg)
}

type alias InfoItem = 
    { cellWidth:  Maybe Int
    , cellStyle:  List Style
    , icon:       String
    , iconStyle:  List Style
    , txt:        String
    , txtStyle:   List Style
    }

type alias ImportantItem msg =
    { wdth: Maybe Int
    , icon: String
    , iconStyle: List Style
    , txt: Html msg
    , badgeIcon: String
    } 

type alias ProfileSection msg = 
    { header: Maybe Header
    , contentRows: List (List (Html msg))
    , footer: List (Html msg)
}

profileSectionInit = ProfileSection Nothing [] []

type alias Header =
    { txt: String
    , icn: String
    , color: String
    }

-- HELPERS --

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


white : Options.Property c m
white =
  Color.text Color.white

-- RENDERERS --

gridRender lst =
    let
        makeLi {labl, val, valueUnit, wdth, cellAttr} = (cell ([Material.Grid.size All wdth, stretch, Material.Grid.align Middle]++cellAttr)  [Lists.li  
            [ Lists.withSubtitle, css "class" "background-success" ] -- NB! Required on every Lists.li containing subtitle.
                [ Lists.content []
                        [ 
                         Lists.subtitle [] [ text labl]
                        , text (val ++ " " ++ valueUnit)
                        ]

                ]])
    in grid [] (List.map makeLi lst)
    
view pinfocard model menuRenderFunction =
    let
        {icn, txt, idx, menuList, cellList} = pinfocard

        i name =
          Icon.view name [ css "width" "40px" ]

        renderMenu model idx btnList =
          let
            padding = (css "padding-right" "24px")
            btnRender {icn, txt, act} = Menu.item [Menu.onSelect act] [ i icn, text txt ]       
          in 
            (menuRenderFunction model idx)
              [ Menu.bottomRight ] (List.map btnRender btnList)
    in
         Card.view [css "width" "auto"]
            [ Card.title    [ Color.background Color.primary, Card.expand] 
                            [ Card.head [ white ] [i icn, text txt ] ]
            , Card.menu [] [renderMenu model idx menuList] 
            , Card.text [ ] [(gridRender (cellList))]
            ]

viewInfoItem { cellWidth, cellStyle, icon, iconStyle, txt, txtStyle } =
    let
        cellW = case cellWidth of 
            Nothing -> ""
            Just w -> "mdl-cell--"++ (toString w) ++"-col"
            
    in 
        div [ class ("mdl-color--white mdl-cell--middle mdl-cell--stretch mdl-cell"++cellW), style cellStyle ]
            [ i [ class icon, style iconStyle]
                []
            , span [ class "mdl-list__item-primary-content mdl-list__item", style txtStyle, style [("display", "inline")]  ]
                [ text txt ]
            ]

viewImportantItem {wdth, icon, iconStyle, txt, badgeIcon} =
    let
        cellW = case wdth of 
            Nothing -> ""
            Just w -> "mdl-cell--"++ (toString w) ++"-col"
    in
        div [ class (" mdl-cell--middle mdl-cell--stretch mdl-cell "++cellW) ]
            [ li [ class "mdl-list__item mdl-list__item--two-line" ]
                [ span [ class "mdl-list__item-primary-content" ]
                    [ span [ class "fa-stack fa-lg", attribute "style" " margin-right:10px;" ]
                        [ i [ class "fa fa-circle fa-stack-2x", style iconStyle ]
                            []
                        , i [ class (icon++" fa-stack-1x fa-inverse") ]
                            []
                        ]
                    , txt
                    , i [ class badgeIcon ]
                        []
                    ]
                ]
    ]

viewProfileInfoItem item =
    let
        { cellWidth, cellStyle, icon , iconStyle, txt , txtStyle} = item
        cellWidth_ = case cellWidth of
            Nothing -> ""
            Just x -> x |> toString
    in
        div [ class ("info-item x"++ (cellWidth_)) ]
            [ i [ class (icon++" info-icon new-patient-footer-icon "), style iconStyle]
                []
            , span [class "info-item-text",style txtStyle]
                [ text txt ]
            ]

viewProfileSection ps = 
    let
        { header, contentRows, footer } = ps
        renderRow row = div [ class "row info-row" ] row

        headerHtml =
            case header of
                Nothing -> text ""
                Just { txt, icn, color } -> 
                    div [ class "info-header" ]
                        [ h5 [] [ i [ class (icn++" info-header-icon") ]
                            []
                        , span [ class "info-header-text" ]
                            [ text txt ]
                        ]]

    in    
        div [ class "profile-section border" ]
        [ headerHtml

        , div [ class "profile-section-content"]
            (List.map renderRow contentRows)

        --, div [ class "row info-row" ]
        --    [ div [ class "x6" ]
        --        [ i [ class "fas fa-female info-icon new-patient-footer-icon " ]
        --            []
        --        , span [ class "text-default" ]
        --            [ text "葛红香, 100 岁" ]
        --        ]

        --    , div [ class "x6" ]
        --        [ i [ class "far fa-id-card info-icon new-patient-footer-icon " ]
        --            []
        --        , span []
        --            [ text "3794898" ]
        --        ]
        --    ]
        --, div [ class "row info-row" ]
        --    [ div [ class "infoitem x6" ]
        --        [ i [ class "fas fa-medkit info-icon new-patient-footer-icon " ]
        --            []
        --        , span []
        --            [ text "ddAC - ddP(H)" ]
        --        ]
        --    , div [ class "infoitem x6" ]
        --        [ i [ class "far fa-calendar-alt info-icon new-patient-footer-icon " ]
        --            []
        --        , span []
        --            [ text "一周一次" ]
        --        ]
        --    ]
        --, div [ class "row info-row" ]
        --    [ div [ class "infoitem x4" ]
        --        [ span [ class "badge bg-blue-light" ]
        --            [ text "氯化钠注射液" ]
        --        , text "250 ml"
        --        ]
        --    , div [ class "infoitem x4" ]
        --        [ span [ class "badge bg-green-light" ]
        --            [ text "首次剂量" ]
        --        , text "324 mg"
        --        ]
        --    , div [ class "infoitem x4" ]
        --        [ span [ class "badge bg-green" ]
        --            [ text "维持剂量" ]
        --        , text "259 mg"
        --        ]
        --    ]
        --, div [ class "row info-row" ]
        --    [ div [ class "infoitem x9", attribute "style" "padding:0 5px 0 5px;" ]
        --        [ div [ class "progress progress-small" ]
        --            [ div [ class "progress-bar", attribute "style" "width: 83%;" ]
        --                []
        --            ]
        --        ]
        --    , div [ class "infoitem x3" ]
        --        [ span []
        --            [ text "左心射血分数：83%" ]
        --        ]
        --    ]
        ]


        --, div [ class "row info-row" ]
        --    [ div [ class "infoitem x6" ]
        --        [ i [ class "fas fa-medkit info-icon new-patient-footer-icon " ]
        --            []
        --        , span []
        --            [ text "ddAC - ddP(H)" ]
        --        ]
        --    , div [ class "infoitem x6" ]
        --        [ i [ class "far fa-calendar-alt info-icon new-patient-footer-icon " ]
        --            []
        --        , span []
        --            [ text "一周一次" ]
        --        ]
        --    ]
