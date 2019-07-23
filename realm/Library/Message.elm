module Library.Message exposing (boxCenter, container, errorText, text, view)

import Realm exposing (Node)
import Realm.Layout as L
import Realm.Style exposing (..)
import Style as C


view : String -> String -> Node msg
view message error =
    L.column_ container
        [ L.column_ boxCenter
            [ L.text text message
            , L.text errorText error
            ]
        ]


container : List Style
container =
    [ L.widthRaw "100%"
    , L.heightRaw "70vh"
    , L.position "relative"
    ]


boxCenter : List Style
boxCenter =
    [ L.rawTop "40%"
    , L.rawLeft "50%"
    , L.position "absolute"
    , L.rawTransform "translate(-50%, -50%)"
    , textAlign "center"
    ]


text : List Style
text =
    [ fontSize 80
    , color C.lightGrey
    , fontWeight "800"
    , L.marginBottom 15
    , textTransform "uppercase"
    ]


errorText : List Style
errorText =
    [ fontSize 27
    , color C.darkGrey
    ]
