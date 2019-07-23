module All exposing (main)

import Json.Encode as JE
import Main
import Realm as R
import Realm.Layout
import Widget.Empty


main : Program JE.Value Main.Model Main.Msg
main =
    R.program (Native.Helpers.identity >> Main.PathChanged)
        Main.OnBack
        { init = Main.init
        , view = Main.view
        , update = Main.update
        , subscriptions = Main.subscriptions
        }
