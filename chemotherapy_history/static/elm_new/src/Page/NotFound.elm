module Page.NotFound exposing (view)

import Html exposing (Html, div, h1, img, main_, text)
import Html.Attributes exposing (alt, class, id, src, tabindex)

import Util exposing ((=>))


-- VIEW --


view : Html msg
view =
    main_ [ id "content", class "container", tabindex -1 ]
        [ h1 [] [ text "Not Found" ]
        ]
