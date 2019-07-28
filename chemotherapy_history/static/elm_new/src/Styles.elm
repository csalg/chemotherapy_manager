module Styles exposing(..)

import Style exposing(..)

--boldText = 
--  [ fontWeight "bold"
--  , letterSpacing (px 1)
--  , color "hsla(240, 13%, 25%, 1)"
--  ]

--horPadding1px = [padding "0 1px 0 1px"]

--blue_line = [backgroundColor "rgb(33,150,243)", margin "14px,14px,0,14px", height (px 6), width "100%"]
--gray_bg = [backgroundColor "hsla(210, 20%, 94%, 1)"]
--iconGray = [color "hsla(232, 1%, 70%, 1)", fontSize (px 24)]
--iconTxtGray = [color "hsla(232, 1%, 50%, 1)"]
--spaceBetween =  [ justifyContent "space-between"
--                , display flex_ ]
--whiteBg = [backgroundColor "#fff"]
--colorPrimary = [color "hsla(211, 100%, 50%, 1)"]
--colorDanger = [color "hsla(354, 70%, 54%, 1)"]
--colorWarning = [color "hsla(45, 100%, 51%, 1)"]
--colorSuccess = [color "hsla(134, 61%, 45%, 1)"]






boldText = 
  [ fontWeight "bold"
  , letterSpacing (px 1)
  , color "hsla(240, 13%, 25%, 1)"
  ]

horPadding1px = [padding "0 1px 0 1px"]

blue_line = [backgroundColor "rgb(33,150,243)", margin "14px,14px,0,14px", height (px 6), width "100%"]
gray_bg = [backgroundColor "hsla(210, 20%, 94%, 1)"]
iconGray = [color "hsla(232, 1%, 70%, 1)", fontSize (px 24)]
iconTxtGray = [color "hsla(232, 1%, 50%, 1)"]
spaceBetween =  [ justifyContent "space-between"
                , display flex_ ]
whiteBg = [backgroundColor "#fff"]
colorPrimary = [color "hsla(211, 100%, 50%, 1)"]
colorDanger = [color "hsla(354, 70%, 54%, 1)"]
colorWarning = [color "hsla(45, 100%, 51%, 1)"]
colorSuccess = [color "hsla(134, 61%, 45%, 1)"]



searchBarCustom = [ marginRight (px 20)
                  , backgroundColor "hsl(203,33%,95%)"
                  ]
newPatientContainer =
    [ marginTop (px 20) 
    , marginBottom (px 20) 
    , border "1px solid var(--gray-2)"
    , width (pc 75)
    ]++whiteBg

newPatientBigHeader = 
    [ fontSize "2.5rem"
    , letterSpacing "0.2rem"
    , color "hsla(198, 4%, 39%, 1)"
    , textAlign center
    ]
newPatientBigHeaderIcon =
    [ color "hsla(198, 4%, 53%, 1)"]

newPatientHeader = 
    [ display "flex"
    , alignItems center
    --, ("border-bottom", "1px solid var(--gray-2)")
    , width (pc 40)
    , paddingBottom (px 7)
    , ("border-bottom", "3px solid var(--blue-primary-4)")
    ]

newPatientHeaderIcon =
    [ fontSize "2rem"
    --, color "hsl(200,2%,54%)"
    , color "var(--blue-primary-4)"
    ]

newPatientHeaderText =
    [ marginLeft (px 10)
    --, color "hsl(200,2%,21%)"
    , color "hsla(215, 3%, 47%, 1)"
    ]

newPatientButton = 
    [ backgroundColor "var(--blue-primary-4)"
    , borderColor "var(--blue-primary-4)"
    ]

newPatientFooter = 
    [ display "flex"
    , justifyContent "flex-end"
    , alignItems "center"
    ]

newPatientFooterIcon =
    [ paddingRight (px 10)
    , fontSize "1.1rem"
    ]
formControlLabel = 
    [fontWeight "400"
    --display: inline-block;
    --margin-bottom: .5rem;
    --color: hsla(204, 2%, 54%, 1);
    --font-weight: 400;
    --letter-spacing: 1.5px;
    ]

padding40 = [padding (px 40)]


bottleHeader =     
    [ display "flex"
    , alignItems baseline
    , justifyContent center
    , letterSpacing (px 2)
    , color "hsla(215, 3%, 39%, 1)"
    , fontWeight "350"
    ]

modalFooterStyle = gray_bg++[("text-align", "right")]


bottleListReposition =
    [margin "-30px 0 50px 0"]