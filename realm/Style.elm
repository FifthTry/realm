module Style exposing (..)

-- TODO: remove Realm.Layout import and move everything to view

import Helpers.Utils exposing (yesno)
import Realm.Layout as L exposing (defaultTransform, flexShrink)
import Realm.Style exposing (..)
import RealmApi.Platform as Platform
    exposing
        ( ($)
        , (~)
        , Native(..)
        , OS(..)
        , Web(..)
        )


null : List Style
null =
    []


pointer : List Style
pointer =
    [ cursor "pointer" ]


positionCenter : List Style
positionCenter =
    [ L.position "absolute"
    , L.rawLeft "50%"
    , L.rawTop "50%"
    , L.rawTransform "translate(-50%, -50%)"
    ]


loaderSize : List Style
loaderSize =
    [ L.height 45 ]


generic : List Style
generic =
    []


flexN : Float -> List Style
flexN n =
    [ L.flex n
    ]


flex1 : List Style
flex1 =
    flexN 1


paddedContainer : List Style
paddedContainer =
    [ L.padding <| 21 ~ 10
    , L.margin <| 10 ~ 2
    ]


vfloatWrapper : List Style
vfloatWrapper =
    [ L.justifyContent "flex-start"
    ]


screen : List Style
screen =
    [ L.flex 1
    ]


relative : List Style
relative =
    [ L.position "relative"
    ]


link : List Style
link =
    [ color newBlue
    , cursor "pointer"
    ]


centerAligned : List Style
centerAligned =
    [ L.alignItems "center"
    ]


frontHeader : List Style
frontHeader =
    [ backgroundColor bgLightestBlue
    , L.justifyContent "space-between"
    , L.height 75
    , L.widthRaw "100%"
    , L.rawPadding <| "1em 5em 2em 5em" ~ "1em .6em 2em"
    , L.alignItems "center"
    , L.boxSizing "border-box"
    , L.position "relative"
    , L.zIndex 1
    ]


frontHeaderHamburger : List Style
frontHeaderHamburger =
    [ L.display <| "none" ~ "auto"
    , L.rawMarginRight ".6em"
    , L.width 22
    ]


sideNavOpen : List Style
sideNavOpen =
    [ L.widthRaw "100%"
    , L.position "fixed"
    , L.left 0
    , L.top 0
    , L.bottom 0
    , L.zIndex 9999
    ]


sideNavClose : List Style
sideNavClose =
    [ L.rawTransform "translateX(-500px)"
    ]


sideNavOverlay : List Style
sideNavOverlay =
    [ L.position "absolute"
    , L.zIndex 1
    , L.left 0
    , L.top 0
    , L.bottom 0
    , L.right 0
    , backgroundColor lightTransparent
    , L.rawTransition "all .2s"
    ]


hamMenuHeader : List Style
hamMenuHeader =
    [ L.rawPadding "3em 1em"
    , L.justifyContent "space-between"
    ]


frontHeaderCross : List Style
frontHeaderCross =
    [ L.width 17
    ]


frontHeaderLogo : List Style
frontHeaderLogo =
    [ L.width <| 84 ~ 60
    ]


hamMenuHeaderLoggedLabel : List Style
hamMenuHeaderLoggedLabel =
    [ fontSize 11
    , L.rawMarginLeft "auto"
    , color grey
    ]


hamMenuHeaderMobile : List Style
hamMenuHeaderMobile =
    [ fontSize 13
    , color darkGrey
    , L.paddingLeft 4
    ]


hamburgerListItem : List Style
hamburgerListItem =
    [ L.rawPadding "1em 2em"
    , borderTop "1px solid #b6b6b6"
    , color darkGrey
    , rawWidth "100%"
    , L.boxSizing "border-box"
    , L.rawLetterSpacing ".1em"
    ]


hamburgerListItemSingleA : List Style
hamburgerListItemSingleA =
    [ L.display <| "initial" ~ "block" ]


frontHeaderDownArrow : List Style
frontHeaderDownArrow =
    [ L.width 10
    , L.height 6
    , L.rawMarginLeft "auto"
    ]


dropMenuListItem : List Style
dropMenuListItem =
    [ L.rawPadding "0 0 1em"
    , L.rawFontSize "14px"
    , L.rawLetterSpacing "normal"
    ]


dropMenuListFirstItem : List Style
dropMenuListFirstItem =
    [ L.marginTop 15
    ]


hamburgerSocialIconList : List Style
hamburgerSocialIconList =
    [ L.rawPadding "2em"
    , rawWidth "100%"
    , L.boxSizing "border-box"
    , L.justifyContent "space-between"
    ]


hamburgerListBorderBottom : List Style
hamburgerListBorderBottom =
    [ borderBottom "1px solid #b6b6b6"
    ]


hamburgerSocialIcon : List Style
hamburgerSocialIcon =
    [ L.rawMarginRight "15px"
    , opacity 0.4
    , L.width 30
    ]


irdaiWrapper : List Style
irdaiWrapper =
    [ L.rawPadding "2em"
    , rawWidth "100%"
    , L.boxSizing "border-box"
    , L.rawLetterSpacing ".1em"
    , L.alignItems "center"
    ]


irdaiLogo : List Style
irdaiLogo =
    [ L.width 50
    , L.marginRight 10
    ]


irdaiText : List Style
irdaiText =
    [ fontSize 12
    , color textGrey
    , L.rawLetterSpacing "0px"
    ]


hamburgerContent : List Style
hamburgerContent =
    [ L.widthRaw "75%"
    , backgroundColor white
    , L.zIndex 3
    , L.heightRaw "100%"
    , L.position "absolute"
    , L.rawTransition "all .4s"
    , L.display <| "flex" ~ "block"
    , L.overflow "auto"
    ]



--vfloat : List Style
--vfloat =
--    paddedContainer
--        ++ [ L.width <| 400 ~ 350
--           , L.minHeightRaw "min-content"
--           ]


quote__inputField : List Style
quote__inputField =
    [ L.flex 1
    , L.padding 10
    ]


quote__objectionablePincode : List Style
quote__objectionablePincode =
    [ L.flex 1
    , backgroundColor orange
    , color white
    ]


fwidget__requiredFlag : List Style
fwidget__requiredFlag =
    [ color red
    , L.marginLeft 4
    ]


rooms : List Style
rooms =
    []


room : List Style
room =
    [ color red ]


gmap : List Style
gmap =
    [ rawWidth "100%" ]


gmap_label : List Style
gmap_label =
    --    [ L.paddingTop 5
    --    , L.paddingBottom 5
    --
    --    -- , textTransform "uppercase"
    --    , fontSize 14
    --    ]
    boxLineInput__label


gmap_map : List Style
gmap_map =
    [ L.height 330 ]


calendorIcon : List Style
calendorIcon =
    [ L.width 16
    , L.height 16
    ]


gmap__lookup : List Style
gmap__lookup =
    [ L.justifyContent "space-between"
    , L.paddingTop 5
    , L.paddingBottom 10
    ]


gmap_address : List Style
gmap_address =
    boxLineInput__input
        ++ [ L.flex 4
           , L.marginTop 0
           , L.marginBottom 0
           , fontFamily "Arial"
           ]


gmap_button : List Style
gmap_button =
    buttonRow
        ++ [ L.marginVertical 5
           , L.paddingHorizontal 5
           , L.paddingVertical 2
           , fontSize 13
           , L.marginLeft 10
           , rawBackgroundColor "#9073e7"
           , color white
           , fontWeight "bold"
           ]


addressInput : List Style
addressInput =
    input


addressInput__address : List Style
addressInput__address =
    [ L.flex 1
    ]


lineInput : List Style
lineInput =
    [ L.marginLeft -15
    , L.maxWidth 350
    ]


lineInput__input : List Style
lineInput__input =
    [ L.padding 5
    , L.height 25
    , borderStyle "solid"
    , borderBottomWidth 1
    , borderBottomColor lightGrey
    , borderTopColor white
    , borderTopWidth 1
    , borderRightColor white
    , borderRightWidth 1
    , borderLeftColor white
    , borderLeftWidth 1
    , L.marginTop 5
    , L.marginBottom 10
    , fontSize 16
    ]


dateLabel : List Style
dateLabel =
    [ L.paddingRight 10
    ]


dateInputLabel : List Style
dateInputLabel =
    [ L.paddingRight 10
    , L.paddingTop 2
    ]


dateInput : List Style
dateInput =
    [ L.paddingVertical 2
    , L.paddingHorizontal 5
    , fontSize 12
    ]


boxLineInput__labelWrapper : List Style
boxLineInput__labelWrapper =
    [ L.minWidth 65
    , L.paddingRight 8
    ]


boxLineInput__label : List Style
boxLineInput__label =
    [ color grey
    , fontSize 13
    , rawLineHeight <|
        case Platform.os of
            Web Desktop ->
                "20px"

            Web Mobile ->
                "20px"

            Native IOS ->
                ""

            Native Android ->
                ""
    ]


input__read : List Style
input__read =
    []


boxLineInput__read : List Style
boxLineInput__read =
    input__read


input : List Style
input =
    [ textAlign "left"
    , L.marginTop 15
    , L.marginBottom 15
    ]


fkUserBox : List Style
fkUserBox =
    [ textAlign "left"
    , L.marginTop 10
    , L.marginBottom 45
    ]


boxLineInput : List Style
boxLineInput =
    input


boxLineInput__input : List Style
boxLineInput__input =
    [ L.padding 5
    , L.minHeight 25
    , borderRadius 3
    , borderStyle "solid"
    , borderWidth 1
    , borderColor lightGrey
    , L.marginTop 5
    , L.marginBottom 10
    , fontSize 16
    ]


minHeightFix : List Style
minHeightFix =
    [ rawMinHeight "fit-content" ]


labelLineInput : List Style
labelLineInput =
    input


focusAnimLabel : List Style
focusAnimLabel =
    input


labelLineInput__read : List Style
labelLineInput__read =
    input__read


labelLineInput__label : List Style
labelLineInput__label =
    [ L.paddingTop 5
    , L.paddingBottom 1

    -- , textTransform "uppercase"
    , fontSize 14
    , color darkGrey
    ]


labelLineInput__label_re_enter_up : List Style
labelLineInput__label_re_enter_up =
    [ L.paddingTop 5
    , L.paddingBottom 1
    , L.marginTop 10

    -- , textTransform "uppercase"
    , fontSize 14
    , color darkGrey
    ]


labelLineInput__checkbox : List Style
labelLineInput__checkbox =
    []


labelLineInput__label_checkbox : List Style
labelLineInput__label_checkbox =
    [ L.paddingTop 5
    , L.paddingBottom 1

    -- , textTransform "uppercase"
    , fontSize 14
    , color darkGrey
    , L.marginLeft 10
    ]


compactWidget__value : List Style
compactWidget__value =
    [ L.paddingTop 5
    , L.paddingBottom 1

    -- , textTransform "uppercase"
    , fontSize 14
    ]


compactWidget__label : List Style
compactWidget__label =
    [ L.paddingTop 5
    , L.paddingBottom 1

    -- , textTransform "uppercase"
    , fontSize 14
    , color grey
    ]


focusRow : List Style
focusRow =
    [ L.position "absolute"
    , L.top -8
    , pointerEvents "none"
    ]


focusRow1 : List Style
focusRow1 =
    [ L.position "absolute"
    , L.top -14
    ]


focusInput : List Style
focusInput =
    [ L.position "relative"
    ]


focusAnimLabel_label : List Style
focusAnimLabel_label =
    [ fontSize 12
    , L.paddingBottom 1
    , L.paddingRight 4
    , color labelGrey
    , transition "all 450ms cubic-bezier(0.23, 1, 0.32, 1) 0ms"
    , transform "scale (0.75) translate(0px, -28px)"
    , pointerEvents "none"
    ]


focusAnimLabelLarge : List Style
focusAnimLabelLarge =
    [ fontSize 15
    ]


focusRowMove : List Style
focusRowMove =
    [ L.position "absolute"
    , L.top 13
    , pointerEvents "none"
    ]


focusRowMove1 : List Style
focusRowMove1 =
    [ L.position "absolute"
    , L.top -4
    ]


labelLineInput__description : List Style
labelLineInput__description =
    [ L.paddingTop 5
    , L.paddingBottom 1

    -- , textTransform "uppercase"
    , fontSize 11
    ]


labelLineInput__input : List Style
labelLineInput__input =
    [ L.paddingTop 2
    , L.paddingBottom <| 0 $ 12
    , L.paddingRight 1
    , L.paddingLeft 1
    , L.height <| 20 $ 32
    , borderStyle "solid"
    , borderBottomWidth 1
    , rawBorderBottomColor <| "lightGrey" $ "transparent"
    , rawBorderTopColor "transparent"
    , borderTopWidth 1
    , rawBorderRightColor "transparent"
    , borderRightWidth 1
    , rawBorderLeftColor "transparent"
    , borderLeftWidth 1
    , L.marginBottom 10
    , L.marginTop 10
    , fontSize 16
    , rawBackgroundColor "transparent"
    ]


labelLineInput__input_re_enter : List Style
labelLineInput__input_re_enter =
    [ L.paddingTop 2
    , L.paddingBottom <| 0 $ 12
    , L.paddingRight 1
    , L.paddingLeft 1
    , L.height <| 20 $ 32
    , borderStyle "solid"
    , borderBottomWidth 1
    , rawBorderBottomColor <| "lightGrey" $ "transparent"
    , rawBorderTopColor "transparent"
    , borderTopWidth 1
    , rawBorderRightColor "transparent"
    , borderRightWidth 1
    , rawBorderLeftColor "transparent"
    , borderLeftWidth 1
    , L.marginTop 10
    , fontSize 16
    , rawBackgroundColor "transparent"
    ]


pickerSelect : List Style
pickerSelect =
    [ fontSize 16
    ]


focusAnimInput_input : List Style
focusAnimInput_input =
    [ L.paddingTop 2
    , L.paddingBottom <| 0 $ 12
    , L.paddingRight 35
    , L.paddingLeft 1
    , borderStyle "solid"
    , borderBottomWidth 1
    , rawBorderBottomColor <| "lightGrey" $ "transparent"
    , rawBorderTopColor "transparent"
    , borderTopWidth 1
    , rawBorderRightColor "transparent"
    , borderRightWidth 1
    , rawBorderLeftColor "transparent"
    , borderLeftWidth 1
    , L.marginVertical 10
    , fontSize 16
    , rawBackgroundColor "transparent"
    , L.height 38
    ]


mmv__picker : List Style
mmv__picker =
    [ L.height 35
    , L.marginBottom 10
    , fontSize 14
    , rawBackgroundColor "transparent"
    , rawBorderBottomColor "lightGrey"
    , borderStyle "solid"
    , borderWidth 1
    ]


fk : List Style
fk =
    input


fklabel : List Style
fklabel =
    [ L.paddingTop 6
    , L.paddingBottom 6
    , L.paddingLeft 4
    , L.paddingRight 4
    , L.marginTop 8
    ]


fkfield : List Style
fkfield =
    [ L.position "relative"
    ]


fkinput : List Style
fkinput =
    [ backgroundColor white
    , L.justifyContent "space-between"
    , L.paddingTop 12
    , L.paddingBottom 12
    , L.paddingLeft 0
    , L.paddingRight 16
    , fontSize 14
    , borderTop "none"
    , borderRight "none"
    , borderLeft "none"
    , borderBottom "1px solid #d0d0d0"
    , L.marginTop 5
    , textTransform "capitalize"
    ]


fkac : List Style
fkac =
    [ L.marginTop 45
    , rawBoxShadow "0 1px 10px #e4e1e1"
    , L.paddingVertical 10
    , L.height 220
    , L.overflow "auto"
    , backgroundColor white
    , L.widthRaw "100%"
    , L.position "absolute"
    , L.top 5
    , borderRadius 2
    , boxSizing "border-box"
    ]


fkacli : List Style
fkacli =
    [ L.rawPadding "12px 15px"
    , cursor "pointer"
    , borderBottom "1px solid #f3f3f3"
    ]


fkbox : List Style
fkbox =
    [ borderColor grey
    , backgroundColor bgGrey
    , borderRadius 3
    , L.width 300
    , borderWidth 1
    , borderStyle "solid"
    , L.justifyContent "space-between"
    , L.paddingTop 12
    , L.paddingBottom 12
    , L.paddingLeft 10
    , L.paddingRight 10
    , boxShadow "0" "2px" "4px" "0" <|
        withOpacity 0.24 black
    ]


font15 : List Style
font15 =
    [ fontSize 15 ]


fkcross : List Style
fkcross =
    [ backgroundColor lightGreen
    , borderRadius 25

    --, L.paddingLeft 5
    --, L.paddingRight 5
    , color white
    , L.maxHeight 18
    , L.minWidth 18
    , textAlign "center"
    , fontSize 13
    , L.marginRight 3
    ]


bRow : List Style
bRow =
    [--L.marginTop 20
     --, L.marginBottom 15
    ]


buttonTable : List Style
buttonTable =
    [ L.padding 10
    ]


imageDiv : List Style
imageDiv =
    [ L.paddingVertical 10
    , L.paddingHorizontal 5
    , borderBottomWidth 1
    , borderStyle "solid"
    , borderBottomColor grey
    ]


wrapper : List Style
wrapper =
    [ backgroundColor lightBlue2
    , L.flex 1
    , L.alignItems "stretch"
    ]


columnOuterWrapper : List Style
columnOuterWrapper =
    [ backgroundColor white
    , L.flex 1
    ]


contentWrapper : List Style
contentWrapper =
    [ L.flex 1
    , L.widthRaw "100%"

    --, L.maxWidth 1400
    ]


componentWrapper : List Style
componentWrapper =
    [ backgroundColor white
    , L.flex 1
    , L.paddingHorizontal 20
    , L.paddingBottom 20
    , L.paddingTop 10
    , borderRadius 2
    , rawBoxShadow "0 0 10px rgba(0, 0, 0, 0.1)"
    ]


componenSideBarWrapper : List Style
componenSideBarWrapper =
    [ backgroundColor white
    , L.flex 1

    --, L.padding 20
    , borderRadius 2
    ]


componentWrapper2 : List Style
componentWrapper2 =
    [ backgroundColor white
    , L.flex 1
    ]


bgLightestBlueRow : List Style
bgLightestBlueRow =
    [ backgroundColor bgLightestBlue ]


subHeader : List Style
subHeader =
    [ backgroundColor white
    , L.alignItems "center"
    , L.heightRaw <| "55px" ~ "auto"
    , L.position "relative"
    , L.padding <| 3 ~ 0
    , L.boxSizing "border-box"
    , L.paddingBottom <| 20 ~ 0
    , L.marginTop <| 30 ~ 0
    , L.paddingHorizontal <| 30 ~ 0
    , L.justifyContent <| "space-between" ~ ""
    , L.widthRaw <| "auto" ~ "100%"
    ]


hamburger : List Style
hamburger =
    [ L.justifyContent "center"
    , L.height 30
    , L.width 40
    ]


openFullMode : List Style
openFullMode =
    [ color white
    , textAlign "center"
    , L.paddingVertical 5
    ]


hamburger__image : List Style
hamburger__image =
    [ L.width 30
    , L.height 30
    , opacity 0.6
    ]


subHeader__dots : List Style
subHeader__dots =
    [ L.display "flex"
    , L.flexDirection "column"
    , L.justifyContent "space-around"
    , L.alignItems "center"
    , L.width 30
    , L.height 35
    ]


subHeader__dot : List Style
subHeader__dot =
    [ L.width 0
    , L.height 0
    , borderRadius 3
    , borderWidth 3
    , borderStyle "solid"
    , borderColor white
    , L.marginBottom 3
    ]


ola__dot : List Style
ola__dot =
    [ L.width 0
    , L.height 0
    , borderRadius 3
    , borderWidth 3
    , borderStyle "solid"
    , borderColor grey
    , L.marginBottom 3
    ]


olaSubHeader__dots : List Style
olaSubHeader__dots =
    subHeader__dots
        ++ [ L.alignSelf "center"
           , cursor "pointer"
           , L.height 30
           , L.marginTop 8
           ]


secondaryActionsArrowRight : List Style
secondaryActionsArrowRight =
    []


secondaryActions__children : List Style
secondaryActions__children =
    [ color <| withOpacity 0.9 grey
    , L.paddingLeft 5
    ]


footer : List Style
footer =
    [ color <| withOpacity 0.7 white
    , fontSize 14
    , L.margin <| 15 ~ 1
    ]


footer__copyright : List Style
footer__copyright =
    [ color <| withOpacity 0.9 white
    , fontSize 14
    , textAlign "center"
    ]


iframe : List Style
iframe =
    [ L.display "none" ]


header__top : List Style
header__top =
    [ L.marginTop 10
    , L.justifyContent "space-between"
    ]


header__bottom : List Style
header__bottom =
    []


lightBottomBorder : List Style
lightBottomBorder =
    [ borderStyle "solid"
    , borderBottomWidth 1
    , borderBottomColor lightGrey
    ]


nav : List Style
nav =
    [ L.marginTop <| 0 ~ 10
    , L.paddingTop <| 0 ~ 10
    , L.paddingBottom <| 0 ~ 10
    , borderRadius <| 0 ~ 3

    --, rawBackgroundColor "transparent" ~ backgroundColor (withOpacity 0.3 lightPurple)
    ]


navItemMobileStyle : List Style
navItemMobileStyle =
    [ L.marginLeft <| 0 ~ -40
    , L.marginRight <| 0 ~ -40
    , L.paddingLeft <| 0 ~ 40
    , L.paddingBottom <| 0 ~ 15
    , L.paddingTop <| 0 ~ 15
    ]


navItem : Bool -> List Style
navItem isActive =
    (null ~ lightBottomBorder)
        ++ (null ~ navItemMobileStyle)
        ++ [ L.paddingRight <| 30 ~ 0
           , L.justifyContent "center"
           , L.marginTop 0
           , L.marginBottom 0

           --, rawBackgroundColor "transparent" ~ backgroundColor (yesno isActive lightPurple (withOpacity 0 lightPurple))
           ]


navItemText : Bool -> List Style
navItemText isActive =
    [ color black
    , fontWeight <| yesno isActive "normal" "normal"

    --, borderColor white
    --, borderRightWidth <|
    --    if Platform.isMobile && isActive then
    --        4
    --    else
    --        0
    --, borderStyle "solid"
    --, backgroundColor <|
    --    if isActive then
    --        if Platform.isMobile then
    --            lightPurpleHl
    --        else
    --            withOpacity 0 lightPurpleHl
    --    else
    --        withOpacity 0 white
    --, L.paddingTop <|
    --    case Platform.os of
    --        Web _ ->
    --            10
    --        Native _ ->
    --            5
    --, L.paddingBottom <|
    --    case Platform.os of
    --        Web _ ->
    --            10
    --        Native _ ->
    --            5
    --, L.paddingLeft <| yesno Platform.isMobile 30 0
    , fontSize <|
        case Platform.os of
            Web Desktop ->
                14

            Web Mobile ->
                14

            Native IOS ->
                16

            Native Android ->
                14
    ]


header__rect : List Style
header__rect =
    [ backgroundColor <| withOpacity 0.35 lightPurple
    , color <| withOpacity 0.9 white
    , L.paddingVertical <| 7 ~ 0.3
    ]


switchArea : Bool -> Bool -> List Style
switchArea isConcrete isOnline =
    [ L.width 36
    , L.height 14
    , rawBackgroundColor <| yesno isOnline "rgba(24, 210, 120, 0.5)" "rgba(204, 204, 204, 0.5)"
    , L.marginLeft 5
    , borderRadius 10
    , L.position "relative"
    ]


switch : Bool -> List Style
switch isOnline =
    [ L.width 20
    , L.height 20
    , rawBackgroundColor <| yesno isOnline "#18D278" "#909090"
    , L.left 0
    , L.position "absolute"
    , rawBorderRadius "50%"
    , L.top -3
    , rawBoxShadow "0 1px 5px 0 rgba(0, 0, 0, 0.6)"
    , L.rawTransform <| yesno isOnline "translateX(16px)" ""
    , L.rawTransition "transform linear .08s, background-color linear .08s"
    ]


filler : List Style
filler =
    [ L.flex 1
    ]


buttonRowRetakeDelete : List Style
buttonRowRetakeDelete =
    [ L.paddingVertical 3
    , L.paddingHorizontal 5
    , L.marginTop 2
    , L.marginLeft 1
    , borderColor darkGrey
    , borderStyle "solid"
    , borderWidth 1
    , borderRadius 3
    , fontSize 12
    ]


photo__title : List Style
photo__title =
    [ L.paddingTop 10
    , L.width 220
    , L.paddingLeft 5

    --, L.flex 1
    ]


buttonRow : List Style
buttonRow =
    [ L.padding 10
    , L.marginTop 10
    , L.marginLeft 10
    , borderColor darkGrey
    , borderStyle "solid"
    , borderWidth 1
    , borderRadius 3
    ]


nextButton : List Style
nextButton =
    [ L.width 60
    , L.margin 10
    , color green2
    , border "1px solid transparent"
    ]


paginationBox : List Style
paginationBox =
    [ L.padding 10
    , L.justifyContent "center"
    , backgroundColor white
    , L.margin 5
    ]


paginationLeftBox : List Style
paginationLeftBox =
    [ L.marginLeft 20
    , backgroundColor lightestGrey
    , L.paddingVertical 8
    , L.paddingHorizontal 14
    ]


paginationLeftUpper : List Style
paginationLeftUpper =
    lightBottomBorder
        ++ [ L.display "block"
           , L.paddingBottom 20
           ]


paginationRightUpper : List Style
paginationRightUpper =
    lightBottomBorder
        ++ [ L.display "flex"
           , L.justifyContent "center"
           ]


paginationLeftLower : List Style
paginationLeftLower =
    [ L.display "block"
    , L.paddingTop 5
    ]


paginationRightLower : List Style
paginationRightLower =
    [ L.display "flex"
    , L.paddingTop 7
    , L.justifyContent "space-between"
    ]


paginationText : List Style
paginationText =
    [ fontSize 12
    ]


paginationEllipsis : List Style
paginationEllipsis =
    paginationText
        ++ [ L.paddingHorizontal 10
           ]


paginationLeftText : List Style
paginationLeftText =
    paginationText


paginationHighLight : List Style
paginationHighLight =
    paginationText
        ++ [ color green2
           , fontWeight "bold"
           , border "none"
           ]


paginationRightBox : List Style
paginationRightBox =
    [ L.display "block"
    , L.paddingVertical 8
    , L.paddingHorizontal 14
    ]


paginatedCurrent : List Style
paginatedCurrent =
    [ L.display "block"
    , L.width 30
    , L.height 20
    , L.marginBottom 10
    , L.marginLeft 10
    , borderBottom "1px solid "
    , borderBottomColor green2
    ]


paginatedCurrentText : List Style
paginatedCurrentText =
    paginationText ++ [ L.paddingLeft 11 ]


paginationBorderIndex : List Style
paginationBorderIndex =
    paginationIndex
        ++ [ borderColor grey ]


paginationIndex : List Style
paginationIndex =
    [ L.display "block"
    , borderStyle "solid"
    , borderWidth 1
    , borderRadius 3
    , L.width 30
    , L.height 20
    , L.marginBottom 5
    , L.marginLeft 10
    ]


paginationButton : List Style
paginationButton =
    [ border "none"
    , L.paddingVertical 0
    , L.paddingHorizontal 10
    , L.paddingBottom 25
    , borderBottom "5px solid "
    , borderBottomColor transparent
    ]


pageSelected : List Style
pageSelected =
    paginationButton
        ++ [ borderBottom "5px solid "
           , color green2
           , borderBottomColor green2
           ]


paginationInput : List Style
paginationInput =
    [ color green2
    , fontWeight "bold"
    , border "none"
    , L.width 45
    , L.height 25
    , L.marginLeft 10
    , L.paddingLeft 10
    ]


paginationHighLightButton : List Style
paginationHighLightButton =
    [ color green2
    , fontWeight "bold"
    , border "none"
    , fontSize 12
    , L.paddingVertical 0
    ]


pageNumberScroll : List Style
pageNumberScroll =
    [ L.overflowX "auto"
    , L.display "flex"
    , L.flexWrap "nowrap"
    ]


paginationSideIndex : List Style
paginationSideIndex =
    paginationIndex
        ++ [ border "transparent" ]


paginatedIndexText : List Style
paginatedIndexText =
    [ L.padding 10
    ]


paginatedUpperBox : List Style
paginatedUpperBox =
    [ borderStyle "solid"
    , borderBottomWidth 1
    , borderBottomColor white
    ]


buttonRow__active : List Style
buttonRow__active =
    buttonRow
        ++ [ backgroundColor blue
           ]


presales__customerDetails : List Style
presales__customerDetails =
    [ L.justifyContent "space-between"
    , L.padding 10
    ]


presales__customerDetail : List Style
presales__customerDetail =
    [ fontWeight "bold"
    ]


presales__quotes : List Style
presales__quotes =
    [ backgroundColor bgGrey
    , L.padding 10
    , borderRadius 7
    , L.flex 1
    ]


presales__quotes1 : List Style
presales__quotes1 =
    [ borderRadius 7
    , L.flex 1
    ]


tabRow : List Style
tabRow =
    [ L.flex 1 ]


presales__quoteTabElement : List Style
presales__quoteTabElement =
    [ L.paddingHorizontal 10
    , L.paddingVertical 5
    , borderStyle "solid"
    , borderColor grey
    , borderBottomWidth 1
    , cursor "pointer"
    , L.flex 1
    , L.display "flex"
    , L.flexDirection "row"
    , L.justifyContent "center"
    ]


presales__quoteTabElement__selected : List Style
presales__quoteTabElement__selected =
    presales__quoteTabElement
        ++ [ color orange
           , fontWeight "bold"
           , borderBottomWidth 0
           , borderTopWidth 3
           , borderRightWidth 1
           , borderLeftWidth 1
           , backgroundColor bgGrey
           ]


customerDetail__tab : List Style
customerDetail__tab =
    [ L.paddingHorizontal 10
    , L.paddingVertical 5
    , borderStyle "solid"
    , borderColor grey
    , borderBottomWidth 1
    , cursor "pointer"
    , L.flex 1
    , L.display "flex"
    , L.flexDirection "row"
    , L.justifyContent "center"
    ]


customerDetail__tab__selected : List Style
customerDetail__tab__selected =
    customerDetail__tab
        ++ [ color orange
           , fontWeight "bold"
           , borderBottomWidth 0
           , borderTopWidth 3
           , borderRightWidth 1
           , borderLeftWidth 1
           , backgroundColor bgGrey
           ]


panelLightGrey : List Style
panelLightGrey =
    [ rawBackgroundColor "#eee"
    , L.margin 15
    , L.padding 10
    , borderRadius 6
    ]


panelWhite : List Style
panelWhite =
    [ backgroundColor white
    , L.margin 10
    , L.marginBottom 30
    , L.paddingTop 10
    , borderRadius 6
    , L.widthRaw "100%"
    ]


infoProfileWrapper : List Style
infoProfileWrapper =
    [ L.paddingVertical 20
    , L.paddingHorizontal 10
    , rawBackgroundColor "#eee"
    ]


infoProfilePicDetails : List Style
infoProfilePicDetails =
    [ L.flex 1
    , fontSize 14
    , L.paddingVertical 15
    , L.paddingLeft 15
    ]


infoProfileName : List Style
infoProfileName =
    [ textTransform "uppercase"
    , color purple
    , fontSize 20
    , L.flex 1
    ]


infoProfileEdit : List Style
infoProfileEdit =
    [ textAlign "right"
    , color lightBlue
    , fontSize 14
    , L.flex 1
    ]


infoProfilePicWrapper : List Style
infoProfilePicWrapper =
    [ L.width 220
    , L.height 220
    , borderRadius 10
    , overflow "hidden"
    , L.alignItems "center"
    ]


infoProfilePic : List Style
infoProfilePic =
    [ rawWidth "100%"
    ]


infoProfileDesignation : List Style
infoProfileDesignation =
    [ color green
    , L.marginBottom 15
    ]


infoProfileDetails : List Style
infoProfileDetails =
    []


infoProfileDetailsOne : List Style
infoProfileDetailsOne =
    [ L.flex 1 ]


infoProfileDetailsTwo : List Style
infoProfileDetailsTwo =
    [ L.flex 1 ]


infoProfileDetailsText : List Style
infoProfileDetailsText =
    [ L.paddingVertical 5 ]


infoProfileDetailsLabel : List Style
infoProfileDetailsLabel =
    [ color lightBlue ]


infoTitleReport : List Style
infoTitleReport =
    [ L.padding 5 ]


infoTitleReportTextOne : List Style
infoTitleReportTextOne =
    [ textTransform "uppercase"
    , fontSize 18
    , color purple
    , L.flex 1
    ]


infoTitleReportTextTwo : List Style
infoTitleReportTextTwo =
    [ L.flex 1 ]


infoTitleReportTextTwoRow : List Style
infoTitleReportTextTwoRow =
    [ L.justifyContent "flex-end" ]


infoTitleReportTextTwoReport : List Style
infoTitleReportTextTwoReport =
    [ color purple
    , fontSize 14
    , L.justifyContent "center"
    , L.paddingHorizontal 2
    ]


infoTitleReportTextTwoName : List Style
infoTitleReportTextTwoName =
    [ color lightBlue
    , fontSize 18
    , textTransform "uppercase"
    , L.paddingHorizontal 2
    , cursor "pointer"
    ]


infoWorkingOn : List Style
infoWorkingOn =
    [ L.paddingVertical 15
    , L.paddingHorizontal 10
    ]


infoWorkingOnLabel : List Style
infoWorkingOnLabel =
    [ fontSize 15
    , L.paddingHorizontal 2
    ]


infoWorkingOnText : List Style
infoWorkingOnText =
    [ color blue
    , fontSize 16
    , L.paddingHorizontal 2
    ]


taskWrapper : List Style
taskWrapper =
    []


taskWrapperRow : List Style
taskWrapperRow =
    [ L.paddingHorizontal 30
    , L.paddingVertical 10
    ]


taskWrapperLeft : List Style
taskWrapperLeft =
    [ L.flex 1 ]


taskWrapperRight : List Style
taskWrapperRight =
    [ L.flex 1
    ]


taskWrapperText : List Style
taskWrapperText =
    []


taskWrapperSubText : List Style
taskWrapperSubText =
    [ rawColor "#555"
    , fontSize 14
    ]


taskTime : List Style
taskTime =
    [ L.justifyContent "flex-end"
    , rawColor "#555"
    , fontSize 14
    ]


taskDate : List Style
taskDate =
    [ L.justifyContent "flex-end"
    ]


taskTitle : List Style
taskTitle =
    [ color purple
    , fontSize 18
    , textTransform "uppercase"
    , L.marginBottom 15
    ]


taskHr : List Style
taskHr =
    [ borderBottom "2px solid #ddd"
    , L.marginVertical 10
    ]


basicTable : List Style
basicTable =
    [ rawWidth "99%"
    , rawMaxWidth "100%"
    , boxShadow "0" "0" "4px" "0" <|
        withOpacity 0.75 black
    , backgroundColor white
    , borderCollapse "collapse"
    , L.margin 6
    , border "1px solid #ddd"
    ]


basicTableTh : List Style
basicTableTh =
    [ textAlign "left"
    , L.padding 10
    , backgroundColor bgGrey
    , textTransform "capitalize"
    , fontSize 14
    , rawColor "#666"
    ]


basicTableTd : List Style
basicTableTd =
    [ textAlign "left"
    , L.padding 10
    , fontSize 14
    , rawColor "#888"
    , borderBottom "1px solid #ddd"
    ]


basicTable2 : List Style
basicTable2 =
    [ rawWidth "100%"
    , rawMaxWidth "100%"

    --, boxShadow "0" "0" "4px" "0" <|
    --    withOpacity 0.75 black
    --, backgroundColor white
    , borderCollapse "collapse"
    , L.marginVertical 6

    --, border "1px solid #000"
    ]


basicTable2Th : List Style
basicTable2Th =
    [ textAlign "left"
    , L.padding 10
    , L.widthRaw "50%"
    , border "1px solid #000"

    --, backgroundColor bgGrey
    , fontWeight "600"
    , fontSize 14

    --, rawColor "#666"
    , color black
    ]


basicTable3Th : List Style
basicTable3Th =
    [ textAlign "left"
    , L.padding 10
    , border "1px solid #000"

    --, backgroundColor bgGrey
    , fontWeight "600"
    , fontSize 10

    --, rawColor "#666"
    , color black
    ]


basicTable2Td : List Style
basicTable2Td =
    [ textAlign "left"
    , L.padding 10
    , fontSize 10
    , color black

    --, rawColor "#888"
    , border "1px solid #000"
    ]


tdTitleName : List Style
tdTitleName =
    [ color blue ]


tdDesignation : List Style
tdDesignation =
    [ fontSize 13 ]


tdTotal : List Style
tdTotal =
    [ fontSize 16
    ]


tdTotalTitle : List Style
tdTotalTitle =
    [ textTransform "uppercase"
    , color purple
    ]


customerSearchH1 : List Style
customerSearchH1 =
    [ fontSize 25
    , color purple
    , L.marginVertical 15
    ]


customerSearchH2 : List Style
customerSearchH2 =
    [ fontSize 20
    , color purple
    , L.marginVertical 5
    , textTransform "uppercase"
    , fontWeight "bold"
    ]


rowCustSearch : List Style
rowCustSearch =
    [ L.marginVertical 10 ]


colCustSearch : List Style
colCustSearch =
    [ --L.flexBasis "25%"
      rawWidth "33.33%"
    , L.paddingVertical 4
    ]


justifyContentCenter : List Style
justifyContentCenter =
    [ L.justifyContent "center" ]


buttonCustSearch : List Style
buttonCustSearch =
    [ fontWeight "bold"
    , backgroundColor green
    , L.paddingHorizontal 60
    , L.paddingVertical 15
    , borderRadius 5
    , L.marginVertical 10
    , color white
    , textAlign "center"
    , cursor "pointer"
    , boxShadow "0" "2px" "4px" "0" <|
        withOpacity 0.24 black
    ]


colCustSearchDisp : List Style
colCustSearchDisp =
    [ rawWidth "25%"
    , L.marginVertical 3
    ]


colCustSearchDispValue : List Style
colCustSearchDispValue =
    [ L.paddingHorizontal 5
    , fontWeight "600"
    ]


colCustSearchDispLabelWrapper : List Style
colCustSearchDispLabelWrapper =
    [ L.flexWrap "wrap"
    , L.flexDirection <| "row" ~ "column"
    ]


colCustSearchDispLabel : List Style
colCustSearchDispLabel =
    [ color darkGrey
    , L.flexBasis "32%"
    ]


customerDetails__panel : List Style
customerDetails__panel =
    [ L.marginTop 15
    ]


fullWidth : List Style
fullWidth =
    [ L.widthRaw "100%" ]


assetsPanel : List Style
assetsPanel =
    [ backgroundColor white
    , L.padding 20
    , L.marginRight 10
    , L.marginTop 25
    , L.marginBottom 10
    , L.flexBasis "100%"
    , rawBoxShadow "0 0 6px rgba(0, 0, 0, 0.2)"
    , borderLeft "3px solid #5accc0"
    , cursor "pointer"
    ]


assetsWrapper : List Style
assetsWrapper =
    [ L.flexWrap "wrap"
    , L.flexDirection <| "row" ~ "column"
    ]


leadPanel : List Style
leadPanel =
    [ rawBackgroundColor "#eee"
    , L.padding 10
    , borderRadius 6
    , border "1px solid #ddd"
    , rawWidth "25%"
    , L.marginRight 20
    , L.alignSelf "flex-start"
    , L.flex 1
    , L.minWidth 250
    , L.maxWidth 400
    ]


assetCardLink : List Style
assetCardLink =
    [ L.display "flex"
    , L.flexBasis "100%"
    ]


assetsInfo : List Style
assetsInfo =
    [ L.justifyContent "flex-start"
    , L.flex 4
    , fontSize 14
    ]


assetsIcon : List Style
assetsIcon =
    [ L.justifyContent "flex-end"
    , L.alignSelf "flex-start"
    , L.flex 1
    ]


assetsInfoVehRow : List Style
assetsInfoVehRow =
    [ L.marginVertical 8
    , L.alignItems "flex-start"
    ]


assetsInfoVeh : List Style
assetsInfoVeh =
    []


assetsInfoVehImg : List Style
assetsInfoVehImg =
    [ L.width 70 ]


assetsInfoIconImg : List Style
assetsInfoIconImg =
    [ L.width 45
    , L.justifyContent "flex-end"
    , L.marginVertical 5
    ]


assetsInfoVehText : List Style
assetsInfoVehText =
    [ L.justifyContent "center"
    , L.paddingHorizontal 5
    ]


assetRegNo : List Style
assetRegNo =
    [ fontSize 16
    , fontWeight "600"
    , L.marginBottom 2
    ]


assetsInfoDetailRow : List Style
assetsInfoDetailRow =
    []


assetsInfoDetailCol : List Style
assetsInfoDetailCol =
    [ L.marginVertical 3 ]


assetsInfoDetailColLabel : List Style
assetsInfoDetailColLabel =
    []


assetsInfoDetailColText : List Style
assetsInfoDetailColText =
    [ L.paddingHorizontal 4 ]


assetsPanelDetails : List Style
assetsPanelDetails =
    [ L.marginVertical 2
    , L.flexWrap "wrap"
    ]


assetsPanelDetailsLabel : List Style
assetsPanelDetailsLabel =
    [ fontSize 14
    , L.flexBasis "49%"
    , color grey
    ]


assetsPanelDetailsValue : List Style
assetsPanelDetailsValue =
    [ fontSize 14
    , L.flexBasis "49%"
    , color newBlue
    ]


assetsPartnerPanel : List Style
assetsPartnerPanel =
    [ L.flexWrap "wrap"
    , L.marginVertical 5
    , L.flexDirection <| "row" ~ "column"
    ]


assetsPartnerIconWrapper : List Style
assetsPartnerIconWrapper =
    [ L.flexBasis "32%"
    , L.alignItems "flex-start"
    , L.marginTop 5
    , L.marginBottom 10
    , L.marginRight 5
    ]


assetsPartnerIcon : List Style
assetsPartnerIcon =
    [ L.height 40
    , L.marginBottom 5
    ]


assetsPartnerLinksWrapper : List Style
assetsPartnerLinksWrapper =
    [ L.flexWrap "wrap"
    , L.marginLeft 5
    ]


assetsPartnerLink : List Style
assetsPartnerLink =
    [ color newBlue
    , fontSize 14
    , L.marginBottom 2
    , L.marginRight 10
    ]


redText : List Style
redText =
    [ color red ]


empDirProfileInfoCode : List Style
empDirProfileInfoCode =
    [ color grey
    , L.justifyContent "flex-end"

    --, L.flex 1
    ]


qtime__title : List Style
qtime__title =
    [ fontWeight "bold"
    ]


qtime__val : List Style
qtime__val =
    [ fontWeight "bold"
    , fontSize 13
    ]


page : List Style
page =
    [ L.flex 5
    ]


pageWrapper : List Style
pageWrapper =
    [ L.paddingVertical <| 30 ~ 20
    , L.paddingHorizontal <| 30 ~ 15
    , backgroundColor lightBlue2
    ]


pageWrapperSideWrapper : List Style
pageWrapperSideWrapper =
    [ --L.padding 30
      backgroundColor white
    ]


pageWrapper2 : List Style
pageWrapper2 =
    [ L.padding 0
    , backgroundColor lightBlue2
    ]


pageWrapper2Left : List Style
pageWrapper2Left =
    [ L.flexBasis "50%"
    , L.flexGrow "1"
    , L.alignItems "flex-end"
    ]


pageWrapper2Right : List Style
pageWrapper2Right =
    [ L.flexBasis "50%"
    , L.flexGrow "1"
    , L.alignItems "flex-start"
    ]


columnWrapper : List Style
columnWrapper =
    [ L.padding 0
    , L.justifyContent "center"
    , L.flexWrap "wrap"
    ]


columnWidgetWrapper : List Style
columnWidgetWrapper =
    [ L.display "flex"
    , L.flexWrap "wrap"
    , L.marginHorizontal <| -10 ~ 0
    , L.alignItems "initial"
    ]


hidden : List Style
hidden =
    [ L.display "none"
    ]


arrowDown : List Style
arrowDown =
    [ L.height 10
    , L.rawTransition "all 0.2s"
    ]


arrowDown__username : List Style
arrowDown__username =
    [ L.width 10
    , L.height 6
    , L.paddingLeft 10
    ]


arrowUp : List Style
arrowUp =
    [ L.height 10
    , L.paddingRight 10
    , L.rawTransform "rotate(-90deg)"
    , L.rawTransition "all 0.2s"
    ]


pdfPage : List Style
pdfPage =
    [ L.widthRaw "100%"
    , L.heightRaw "100%"
    ]


mainPage : List Style
mainPage =
    [ L.flex 1 ]


vacancySpan : List Style
vacancySpan =
    [ textTransform "uppercase"
    , backgroundColor orange
    , L.paddingHorizontal 2
    , L.paddingVertical 4
    , borderRadius 4
    , fontSize 10
    , L.position "absolute"
    , L.right 5
    , L.top -5
    ]


marginBottomZero : List Style
marginBottomZero =
    [ L.marginBottom 0 ]


successClaimPanel : List Style
successClaimPanel =
    [ L.padding 10
    , borderColor green
    , borderStyle "solid"
    , borderWidth 2
    , borderRadius 3
    , L.alignItems "center"
    , L.marginBottom 10
    ]


failureClaimPanel : List Style
failureClaimPanel =
    [ L.padding 10
    , borderColor red
    , borderStyle "solid"
    , borderWidth 2
    , borderRadius 3
    , L.alignItems "center"
    , L.marginBottom 10
    ]


successClaimPanelText : List Style
successClaimPanelText =
    [ L.justifyContent "center"
    ]


successIcon : List Style
successIcon =
    [ L.width 25
    , L.height 25
    , L.paddingHorizontal 5
    ]


claimTypePanel : List Style
claimTypePanel =
    [ L.marginTop 5 ]


claimTypePanelMinHeight : List Style
claimTypePanelMinHeight =
    [ L.minHeight 240
    , L.marginBottom 25
    ]


noClaimHeight : List Style
noClaimHeight =
    [ L.minHeight 200
    , L.marginBottom 25
    ]


claimTypRadioButtonPanel : List Style
claimTypRadioButtonPanel =
    [ L.flex 1
    , L.flexWrap "wrap"
    ]


claimTypeHeader : List Style
claimTypeHeader =
    [ fontSize 22
    , textAlign "center"

    --    , L.marginBottom 20
    , fontWeight "600"

    --, L.flex 1
    ]


spaceBelow20 : List Style
spaceBelow20 =
    [ L.marginBottom 20
    ]


marginAuto : List Style
marginAuto =
    [ L.rawMarginHorizontal "auto" ]


claimTypRadioButton : List Style
claimTypRadioButton =
    [ borderColor grey
    , borderStyle "solid"
    , borderWidth 2
    , borderRadius 3
    , L.marginBottom 20
    , L.padding 10
    , L.alignItems "center"
    , L.flex 1
    , L.flexBasis "40%"
    , L.marginHorizontal 5
    , cursor "pointer"
    , L.minWidth 181
    ]


anchorClaimTypRadioButton : List Style
anchorClaimTypRadioButton =
    [ L.alignItems "center"
    , L.flex 1
    , L.flexBasis "40%"
    , cursor "pointer"
    ]


claimTypRadioButtonActive : List Style
claimTypRadioButtonActive =
    claimTypRadioButton
        ++ [ borderColor newBlue ]


ongoingStepIcon : List Style
ongoingStepIcon =
    [ L.width 20
    , L.height 20
    , L.paddingHorizontal 5
    ]


pendingStepIcon : List Style
pendingStepIcon =
    ongoingStepIcon


claimTypRadioButtonText : List Style
claimTypRadioButtonText =
    [ color grey
    , fontSize 14
    , L.paddingHorizontal 10
    ]


claimTypRadioButtonTextActive : List Style
claimTypRadioButtonTextActive =
    claimTypRadioButtonText
        ++ [ color black ]


claimHistory : List Style
claimHistory =
    [ borderTopColor bgGrey
    , borderTopWidth 1
    , borderBottomColor bgGrey
    , borderBottomWidth 1
    , borderStyle "solid"
    , L.paddingVertical 20
    , L.marginBottom 10
    , L.justifyContent "space-between"
    , cursor "pointer"
    , L.alignItems "center"
    ]


processClaimText : List Style
processClaimText =
    [ fontSize 25
    , fontWeight "700"
    , textAlign "center"
    , L.paddingVertical 60
    , L.paddingHorizontal 10
    ]


widthImg : List Style
widthImg =
    [ L.width 140
    , L.marginVertical 20
    , L.rawMarginHorizontal "auto"
    ]


reducePadding : List Style
reducePadding =
    [ L.paddingVertical 10
    , L.paddingHorizontal 10
    ]


claimHistoryText : List Style
claimHistoryText =
    [ color newBlue ]


forwardPurpleIcon : List Style
forwardPurpleIcon =
    [ L.width 10
    , L.height 17
    ]


backGreyIcon : List Style
backGreyIcon =
    [ L.width 10
    , L.height 17
    ]


addPurpleIcon : List Style
addPurpleIcon =
    [ L.width 14
    , L.height 14
    , L.paddingHorizontal 15
    ]


minusPurpleIcon : List Style
minusPurpleIcon =
    [ L.width 14
    , L.height 2
    , L.paddingHorizontal 15
    ]


rowJustFlexEnd : List Style
rowJustFlexEnd =
    [ L.justifyContent "flex-end" ]


homePageCarouselDotsWrapper : List Style
homePageCarouselDotsWrapper =
    [ L.justifyContent "center"
    , L.alignItems "center"
    , L.marginTop 10
    ]


marginBottom30 : List Style
marginBottom30 =
    [ L.marginBottom 30 ]


homePageCarouselDot : List Style
homePageCarouselDot =
    [ L.width 0
    , L.height 0
    , borderRadius 4
    , borderWidth 4
    , borderStyle "solid"
    , borderColor grey
    , L.marginHorizontal 3
    , cursor "pointer"
    ]


homePageCarouselDotActive : List Style
homePageCarouselDotActive =
    homePageCarouselDot
        ++ [ borderColor newBlue
           , borderRadius 5
           , borderWidth 5
           ]


balanceAmtWrapper : List Style
balanceAmtWrapper =
    [ backgroundColor orange
    , borderRadius 4
    , L.flex 1
    , L.justifyContent "center"
    , L.marginRight 10
    , L.marginBottom 15
    , L.marginTop 18
    , boxShadow "0" "1px" "10px" "-2px" <|
        withOpacity 0.75 black
    ]


policiesWrapper : List Style
policiesWrapper =
    [ L.flex 3
    , L.marginBottom 15
    ]


balanceAmtInnerWrapper : List Style
balanceAmtInnerWrapper =
    [ L.paddingVertical 25
    , L.paddingHorizontal 15
    , color white
    , L.justifyContent "space-between"
    ]


balanceAmt : List Style
balanceAmt =
    []


balanceAmtLabel : List Style
balanceAmtLabel =
    [ fontSize 12
    , color <| withOpacity 0.9 white
    ]


balanceAmtValue : List Style
balanceAmtValue =
    [ fontSize 25
    , fontWeight "600"
    , L.paddingVertical 5
    , letterSpacing 1
    ]


balanceAmtDateWrapper : List Style
balanceAmtDateWrapper =
    [ L.flex 1 ]


balanceAmtHr : List Style
balanceAmtHr =
    [ rawBorderBottomColor "#CA8017"
    , borderBottomWidth 2
    , borderStyle "solid"
    , L.marginVertical 2
    ]


balanceAmtDateValue : List Style
balanceAmtDateValue =
    [ fontSize 14 ]


analyticsTableNumberTd : List Style
analyticsTableNumberTd =
    [ textAlign "right"
    , L.paddingHorizontal 10
    , L.paddingVertical 12
    , fontSize 14
    , color darkGrey
    , borderColor bgGrey
    , borderWidth 1
    , borderStyle "solid"
    , borderBottom "1px solid #ddd"
    ]


textCenter : List Style
textCenter =
    [ textAlign "center" ]


snapshotBackGreyIcon : List Style
snapshotBackGreyIcon =
    [ L.width 8
    , L.height 12
    , L.alignSelf "center"
    , L.paddingRight 10
    ]


snapshotMonthInfoWrapper : List Style
snapshotMonthInfoWrapper =
    [ L.justifyContent "space-between"
    , L.alignItems "center"
    , L.marginTop 20
    ]


snapshotMonthInfo : List Style
snapshotMonthInfo =
    [ L.alignItems "center"
    ]


snapshotMonthInfoLabel : List Style
snapshotMonthInfoLabel =
    [ fontSize 12
    , L.paddingHorizontal 2
    , color newBlue
    ]


snapshotMonthInfoValue : List Style
snapshotMonthInfoValue =
    [ fontSize 12
    , fontWeight "600"
    , L.paddingHorizontal 2
    , color darkGrey
    ]


snapshotMonthInfoBr : List Style
snapshotMonthInfoBr =
    [ L.paddingHorizontal 5 ]


showGraph : List Style
showGraph =
    [ backgroundColor white
    , L.paddingHorizontal 8
    , L.paddingVertical 6
    , borderTopRightRadius 3
    , borderTopLeftRadius 3
    , cursor "pointer"
    , L.alignItems "center"
    , L.marginLeft 8
    , boxShadow "0" "-1px" "5px" "-2px" <|
        withOpacity 0.75 black
    , L.zIndex 2
    ]


graphWrapper : List Style
graphWrapper =
    [ L.height 100
    , backgroundColor white
    , borderTopLeftRadius 3
    , boxShadow "0" "1px" "10px" "-2px" <|
        withOpacity 0.75 black
    ]


olaPopUpMainWrapper : List Style
olaPopUpMainWrapper =
    [ L.position "fixed"
    , L.left 0
    , L.right 0
    , L.top 0
    , L.bottom 0
    , L.rawMarginHorizontal "auto"
    , L.zIndex 5555
    , L.alignItems "center"
    , L.justifyContent "center"
    , backgroundColor <| withOpacity 0.8 white
    ]


olaPopUpWrapper : List Style
olaPopUpWrapper =
    [ L.padding 20
    , L.widthRaw <| "500px" ~ "35%"
    , backgroundColor white
    , L.position "fixed"
    , boxShadow "0" "1px" "15px" "-2px" <|
        withOpacity 0.75 black
    , L.minWidth 270
    , L.rawTop "50%"
    , L.rawLeft "50%"
    , L.marginTop <| -202 ~ -155
    , L.marginLeft <| -250 ~ -155
    ]


movePopUp : List Style
movePopUp =
    [ L.marginTop -235
    ]


closeEmailPopUp : List Style
closeEmailPopUp =
    [ cursor "pointer"
    , L.position "absolute"
    , L.right 25
    , L.top 25
    , color grey
    , fontSize 14
    , fontWeight "800"
    , L.zIndex 2
    ]


closeEmail1 : List Style
closeEmail1 =
    [ L.top 18
    ]


mediaLinkWrapper : List Style
mediaLinkWrapper =
    [ backgroundColor bgLightestBlue
    , L.paddingHorizontal 30
    , L.paddingVertical 40
    , L.marginBottom 20
    , borderRadius 80
    , L.justifyContent "space-between"
    , L.flexDirection <| "row" ~ "column"
    ]


mediaLinkSection : List Style
mediaLinkSection =
    [ L.alignItems "center"
    , textAlign "center"
    , L.marginBottom <| 0 ~ 15
    ]


mediaLinkSectionText : List Style
mediaLinkSectionText =
    [ L.marginBottom 3 ]


mediaLinkSectionLink : List Style
mediaLinkSectionLink =
    [ cursor "pointer" ]


uploadAsterisk : List Style
uploadAsterisk =
    [ color red ]


uploadSmallText : List Style
uploadSmallText =
    [ fontSize 12
    , color grey
    ]


uploadInfoText : List Style
uploadInfoText =
    [ color grey
    , fontSize 12
    , textAlign "center"
    , L.marginTop 20
    ]


visibilityHidden : List Style
visibilityHidden =
    [ visibility "hidden" ]


campaignwrapper : List Style
campaignwrapper =
    [ L.margin 20
    , backgroundColor white
    , boxShadow "0" "3px" "9px" "0" <|
        withOpacity 1 lightGrey
    ]


freeCarWashLogin : List Style
freeCarWashLogin =
    [ L.width 60
    , L.height 60
    ]


otptext : List Style
otptext =
    [ fontSize 12
    , color purple
    , L.paddingTop 23
    , L.marginLeft -60
    , fontWeight "bold"
    , L.width 80
    ]


fontdec : List Style
fontdec =
    [ fontSize 16
    , L.paddingBottom 1
    , color labelGrey
    , L.position "absolute"
    , L.top 16
    , L.zIndex 1
    , transition "all 450ms cubic-bezier(0.23, 1, 0.32, 1) 0ms"
    , transform "scale (1) translate(0px, 0px)"
    , pointerEvents "none"
    ]


fontdec1 : List Style
fontdec1 =
    [ fontSize 16
    , color labelGrey
    , L.position "absolute"
    , L.top 8
    , L.zIndex 1
    , transition "all 450ms cubic-bezier(0.23, 1, 0.32, 1) 0ms"
    , transform "scale (1) translate(0px, 0px)"
    , pointerEvents "none"
    ]


moveLabel : List Style
moveLabel =
    [ fontSize 12
    , color labelGrey
    , L.position "absolute"
    , L.top 0
    , L.zIndex 1
    , transition "all 450ms cubic-bezier(0.23, 1, 0.32, 1) 0ms"
    , transform "scale (0.75) translate(0px, -28px)"
    , pointerEvents "none"
    ]


paddingLeft : List Style
paddingLeft =
    [ L.paddingLeft 30
    ]


moveLabel1 : List Style
moveLabel1 =
    [ fontSize 12
    , color labelGrey
    , L.position "absolute"
    , L.top -5
    , L.zIndex 1
    , transition "all 450ms cubic-bezier(0.23, 1, 0.32, 1) 0ms"
    , transform "scale (0.75) translate(0px, -28px)"
    , pointerEvents "none"
    ]


inputRelative : List Style
inputRelative =
    [ L.marginTop 20
    ]


inputRelative1 : List Style
inputRelative1 =
    [ L.marginTop 12
    ]


fontnormal : List Style
fontnormal =
    [ fontWeight "400"
    ]


freeCarWashdot : List Style
freeCarWashdot =
    [ backgroundColor lightGrey
    , L.width 30
    , L.height 30
    , rawBorderRadius "100%"
    , L.marginVertical 10
    , L.marginHorizontal 15
    ]


carwashrow1 : List Style
carwashrow1 =
    [ L.marginTop 20
    , L.marginHorizontal 10
    , L.marginBottom 25
    , L.position "relative"
    ]


carwashrow2 : List Style
carwashrow2 =
    [ L.marginHorizontal 10
    , L.position "relative"
    , L.marginBottom 10
    ]


columnstretch : List Style
columnstretch =
    [ L.width 300
    ]


dashedlink : List Style
dashedlink =
    [ L.height 40
    , L.width 10
    , borderLeftWidth 2
    , borderStyle "dashed"
    , borderLeftColor grey
    , L.position "absolute"
    , L.top -32
    , L.left 29
    ]


broadborder : List Style
broadborder =
    [ borderBottomWidth 2
    , borderBottomColor purple
    ]


errorOtp : List Style
errorOtp =
    [ color red
    ]


errorborder : List Style
errorborder =
    [ borderBottomWidth 2
    , rawBorderBottomColor <| "red" $ "transparent"
    ]


errorOlaClaim : List Style
errorOlaClaim =
    [ borderBottomWidth 2
    , fontSize 15
    , color red
    ]


otperrortext : List Style
otperrortext =
    [ fontSize 12
    , color red
    , L.paddingTop 15
    , L.marginLeft -60
    , fontWeight "bold"
    ]


errorimg : List Style
errorimg =
    [ L.width 30
    , L.height 30
    , L.marginVertical 10
    , L.marginHorizontal 15
    ]


loaderIn : List Style
loaderIn =
    [ L.width 30
    , L.height 30
    , L.marginVertical 10
    , L.marginHorizontal 15
    ]


successdone : List Style
successdone =
    [ L.width 30
    , L.height 30
    , L.marginVertical 10
    , L.marginHorizontal 15
    ]


verdone : List Style
verdone =
    [ L.marginTop 15
    , L.marginHorizontal 10
    , L.marginBottom 10
    ]


numberentered : List Style
numberentered =
    [ rawBorderBottomColor "transparent"
    , fontSize 16
    ]


dropmenuIcon : List Style
dropmenuIcon =
    [ L.width 12
    , L.height 8
    , L.paddingRight 10
    ]


preloaderCircleWrapper : List Style
preloaderCircleWrapper =
    [ L.position "absolute"
    , backgroundColor white
    , L.widthRaw "100%"
    , L.heightRaw "100%"
    , L.justifyContent "center"
    , L.alignItems "center"
    ]


preloaderCircle : List Style
preloaderCircle =
    []


positionR : List Style
positionR =
    [ L.position "relative" ]


datepickerContainer : List Style
datepickerContainer =
    [ backgroundColor white
    , fontSize 12
    , L.rawLeft <| "0px" ~ "50%"
    , rawLineHeight "30px"
    , L.position <| "absolute" ~ "fixed"
    , L.rawTop <| "28px" ~ "50%"
    , L.width 330
    , L.zIndex 1
    , L.rawTransform <| "none" ~ "translate(-50%, -50%)"
    ]


newDatepickerContainer : List Style
newDatepickerContainer =
    [ backgroundColor white
    , fontSize 12
    , L.rawLeft "50%"
    , rawLineHeight "30px"
    , L.position "fixed"
    , L.rawTop "50%"
    , L.width 330
    , L.zIndex 2
    , L.rawTransform "translate(-50%, -50%)"
    ]


newDatepickerDropdown : List Style
newDatepickerDropdown =
    [ boxShadow "0" "3px" "6px" "3px" <|
        withOpacity 1 lightGrey
    , L.position "fixed"
    , L.zIndex 1
    ]


datepickerDropdown : List Style
datepickerDropdown =
    [ boxShadow "0" "3px" "6px" "3px" <|
        withOpacity 1 lightGrey

    --    , L.position "absolute"
    , L.zIndex 1
    ]


hideDatepicker : List Style
hideDatepicker =
    [ L.display "none"
    ]


dateInpClass : List Style
dateInpClass =
    [ L.rawPadding "3px 3px 3px 40px"
    , fontSize 16
    , borderWidth 0
    , L.boxSizing "border-box"
    , L.height 39
    , border "1px solid #dedede"
    , L.minWidth 150
    , borderRadius 3
    , color darkGrey
    ]


dateInpMobileClass : List Style
dateInpMobileClass =
    [ L.rawPadding "3px 40px 3px 15px"
    , fontSize 12
    , borderWidth 0
    , L.boxSizing "border-box"
    , L.height 32
    , border "none"
    , borderRadius 25
    , color darkPurple
    , rawBackgroundColor "#e7e3ff"
    ]


dateInpMobileActive : List Style
dateInpMobileActive =
    [ border "none" ]


dateInpActive : List Style
dateInpActive =
    [ border "1px solid #9073e7" ]


crossbtn : List Style
crossbtn =
    [ L.position "absolute"
    , L.left 12
    , L.rawTop "50%"
    , L.rawTransform "translateY(-50%)"
    , pointerEvents "none"
    ]


calendorLink : List Style
calendorLink =
    [ L.position "absolute"
    , L.right 12
    , L.rawTop "50%"
    , L.rawTransform "translateY(-50%)"
    , pointerEvents "none"
    ]


datepickerTopLeft : List Style
datepickerTopLeft =
    []


datepickerHolder : List Style
datepickerHolder =
    [ L.position "relative"
    ]


datepickerPanel : List Style
datepickerPanel =
    [ L.display "none"
    ]


showDatePanel : List Style
showDatePanel =
    [ L.display "flex"
    , L.paddingHorizontal 25
    , L.paddingBottom 10
    ]


dayOfMonth : List Style
dayOfMonth =
    [ L.height 40
    , L.width 40
    , textAlign "center"
    , rawLineHeight "37px"
    ]


dayOfMonthSelected : List Style
dayOfMonthSelected =
    [ L.height 40
    , L.width 40
    , textAlign "center"
    , color white
    , fontWeight "bold"
    , backgroundColor purple
    , rawBorderRadius "100%"
    , rawLineHeight "37px"
    ]


monthName : List Style
monthName =
    [ L.height 50
    , L.width 70
    , textAlign "center"
    ]


headField : List Style
headField =
    []


titleField : List Style
titleField =
    [ L.width 110
    , textAlign "center"
    , L.paddingTop 4
    ]


hiddenField : List Style
hiddenField =
    [ L.display "none"
    ]


arrowdp : List Style
arrowdp =
    [ L.width 110
    , textAlign "center"
    , fontSize 16
    ]


monthRow : List Style
monthRow =
    []


yearBox : List Style
yearBox =
    [ fontSize 14
    , L.width 70
    , textAlign "center"
    , L.height 40
    ]


changeDir : List Style
changeDir =
    [ L.justifyContent "flex-end"
    ]


daysField : List Style
daysField =
    [ L.paddingHorizontal 25 ]


daysLabel : List Style
daysLabel =
    [ L.width 40
    , L.height 40
    , textAlign "center"
    , rawLineHeight "37px"
    ]


arrowIco : List Style
arrowIco =
    [ L.width 6
    , L.paddingTop 5
    ]


policyCard : List Style
policyCard =
    [ L.paddingLeft 20
    , L.paddingTop 20
    ]


compactWidget_policyCard : List Style
compactWidget_policyCard =
    [ L.paddingLeft 20
    ]


policyLeft : List Style
policyLeft =
    [ backgroundColor white
    , rawWidth "25%"
    , borderRadius 4
    ]


policyRight : List Style
policyRight =
    [ backgroundColor white
    , borderRadius 4
    , rawWidth "73%"
    , L.rawMarginHorizontal "0.7%"
    , L.paddingBottom 25
    ]


pidRow : List Style
pidRow =
    [ L.justifyContent "center"
    , L.paddingTop 20
    ]


pidData : List Style
pidData =
    [ L.paddingLeft 5
    ]


pid : List Style
pid =
    [ color grey
    ]


cid : List Style
cid =
    [ fontSize 14 ]


linkData : List Style
linkData =
    [ color newBlue
    ]


paymentClaim : List Style
paymentClaim =
    [ fontSize 22
    , L.paddingTop 6
    , rawWidth "50%"
    , textAlign "center"
    ]


regVeh : List Style
regVeh =
    [ rawWidth "50%"
    , L.paddingLeft 20
    , L.paddingBottom 10
    ]


regNo : List Style
regNo =
    [ fontSize 18
    ]


lastClaimRow : List Style
lastClaimRow =
    [ L.paddingBottom 25
    , borderBottomColor lightGrey
    , borderBottomWidth 2
    , borderStyle "solid"
    , L.marginHorizontal 20
    ]


claimsRow : List Style
claimsRow =
    [ L.marginHorizontal 20 ]


regYear : List Style
regYear =
    [ L.paddingTop 20
    , rawWidth "33.33%"
    , L.justifyContent "flex-start"
    ]


regClaims : List Style
regClaims =
    [ L.paddingTop 20
    , rawWidth "33.33%"
    , L.justifyContent "flex-start"
    ]


regClaimsFull : List Style
regClaimsFull =
    [ L.paddingTop 20
    , L.justifyContent "flex-start"
    ]


vehImg : List Style
vehImg =
    [ L.justifyContent "center"
    , L.paddingVertical 20
    ]


vehicleIco : List Style
vehicleIco =
    [ L.height 85
    ]


vehDet : List Style
vehDet =
    [ L.paddingTop 20
    ]


truncate : List Style
truncate =
    [ rawMaxWidth "200px"
    , overflow "hidden"
    ]


truncate1 : List Style
truncate1 =
    [ rawMaxWidth "183px"
    , overflow "hidden"
    , L.whiteSpace "nowrap"
    ]


truncate2 : List Style
truncate2 =
    [ rawMaxWidth "172px"
    , overflow "hidden"
    , L.whiteSpace "nowrap"
    ]


mmvWrapper : List Style
mmvWrapper =
    [ L.margin 20
    , backgroundColor white
    , boxShadow "0" "3px" "9px" "0" <|
        withOpacity 1 lightGrey
    , L.maxWidth 600
    , L.minWidth 400
    , rawWidth "100%"
    , L.paddingVertical 10
    ]


carJourneyCardWrapper : List Style
carJourneyCardWrapper =
    [ backgroundColor white
    , boxShadow "0" "3px" "9px" "0" <|
        withOpacity 1 lightGrey
    , L.zIndex 0
    , L.position "relative"

    --, L.margin 20
    --, L.rawMarginHorizontal "auto"
    -- , L.maxWidth 600
    -- , L.minWidth 400
    -- , rawWidth "100%"
    --, L.widthRaw <| "486px" ~ "96%"
    --, L.paddingVertical 10
    ]


carInput : List Style
carInput =
    [ L.width 500
    , L.marginLeft 16
    ]


carLabel : List Style
carLabel =
    [ L.left 51
    , L.paddingTop 3
    ]


searchImg : List Style
searchImg =
    [ L.height 20
    , L.paddingTop 21
    , L.paddingLeft 16
    ]


vehicleList : List Style
vehicleList =
    [ L.display "block"
    , L.paddingLeft 51
    , rawMaxHeight "210px"
    , overflow "auto"
    ]


vehicleName : List Style
vehicleName =
    [ L.display "inline-block"
    , rawWidth "50%"
    , L.paddingVertical 5
    ]


vehDashed : List Style
vehDashed =
    [ L.height 26
    , L.left 24
    , L.top -8
    ]


popCars : List Style
popCars =
    [ L.paddingLeft <| 51 ~ 0
    , fontSize 18
    , fontWeight "bold"
    , L.paddingBottom 7
    , L.paddingTop 15
    , borderBottom <| "none" ~ "1px solid #b6b6b6"
    ]


crossVehicle : List Style
crossVehicle =
    [ L.position "absolute"
    , L.right 15
    , L.top 20
    , L.zIndex 3
    ]


stopFocus : List Style
stopFocus =
    [ L.display "block"
    , L.position "absolute"
    , L.widthRaw <| "505px" ~ "50%"
    , L.height 23
    , L.left 51
    , L.top 20
    , L.zIndex 2
    ]


clearBtn : List Style
clearBtn =
    [ L.height 14
    ]


placeDriver : List Style
placeDriver =
    [ backgroundColor white
    , L.paddingTop 12
    , L.paddingHorizontal 20
    , L.paddingBottom 12
    , borderRadius 4
    , L.height 170
    , boxShadow "0" "3px" "9px" "0" <|
        withOpacity 1 lightGrey
    , L.position "relative"
    ]


reassignSubmit : List Style
reassignSubmit =
    [ L.paddingHorizontal 30
    , L.paddingVertical 5
    , L.width 115
    , borderRadius 4
    , backgroundColor green
    , color white
    , fontWeight "bold"
    , fontSize 14
    , L.marginTop 15
    ]


editBtn : List Style
editBtn =
    [ color white
    , L.paddingHorizontal 15
    , L.paddingVertical 3
    , rawBackgroundColor "#9073E8"
    , fontSize 12
    , cursor "pointer"
    , L.marginLeft 15
    ]


errCross : List Style
errCross =
    [ fontSize 18
    , fontWeight "bold"
    , L.position "absolute"
    , L.right 10
    ]


errMsg : List Style
errMsg =
    [ color red
    , L.marginTop 9
    , fontSize 12
    ]


assignSpace : List Style
assignSpace =
    [ L.marginRight 8
    , color grey
    , fontSize 14
    ]


assignVerSpace : List Style
assignVerSpace =
    [ L.marginTop 15 ]


wrapRegNo : List Style
wrapRegNo =
    [ backgroundColor white
    , boxShadow "0" "3px" "9px" "0" <|
        withOpacity 1 lightGrey
    , L.paddingVertical 15
    , L.paddingHorizontal 25
    ]


mainReg : List Style
mainReg =
    [ L.width 600
    , L.marginBottom 15
    ]


regImgWrap : List Style
regImgWrap =
    [ textAlign "center"
    ]


regCar : List Style
regCar =
    [ L.width 200
    , L.rawMarginHorizontal "auto"
    ]


innerReg : List Style
innerReg =
    []


regTitle : List Style
regTitle =
    [ L.marginTop 20
    , fontSize 25
    , fontWeight "bold"
    ]


regPetDie : List Style
regPetDie =
    [ L.marginTop 5
    , L.marginBottom 15
    , fontSize 18
    ]


errReg : List Style
errReg =
    [ color red
    , fontSize 12
    ]


regText : List Style
regText =
    [ color grey
    ]


editReg : List Style
editReg =
    [ L.position "absolute"
    , L.right 0
    , fontSize 18
    , L.top 7
    , color blue
    ]


regUp : List Style
regUp =
    [ L.paddingLeft 2
    ]


onlineCircle : List Style
onlineCircle =
    [ L.width 9
    , L.height 9
    , backgroundColor green
    , L.position "absolute"
    , L.right -15
    , L.top 4
    , borderRadius 10
    ]


offlineCircle : List Style
offlineCircle =
    [ L.width 9
    , L.height 9
    , backgroundColor lighterGrey
    , L.position "absolute"
    , L.right -15
    , L.top 4
    , borderRadius 12
    ]


bgFunnel : List Style
bgFunnel =
    [ L.width 100
    , L.height 9
    , backgroundColor green
    , L.position "absolute"
    , L.right -15
    , L.top 4
    , borderRadius 10
    ]


chartSvgColumn : List Style
chartSvgColumn =
    [ L.widthRaw "50%"
    , L.heightRaw "50%"
    , L.minHeight 500
    , L.minWidth 500
    ]


chartSvg : List Style
chartSvg =
    [ L.minHeight 500
    , L.minWidth 500
    ]


black : Color
black =
    rgb 0 0 0


lightBlue2 : Color
lightBlue2 =
    rgb 245 245 245


blueGray : Color
blueGray =
    rgb 82 95 124


purpleBlue : Color
purpleBlue =
    rgb 95 69 180


purpleBlue2 : Color
purpleBlue2 =
    rgb 102 109 220


lightChawk : Color
lightChawk =
    rgb 247 247 249


midBlack : Color
midBlack =
    rgb 35 36 41


transparent : Color
transparent =
    rgba 0 0 0 0


purpleNew : Color
purpleNew =
    rgb 154 122 246


lightTransparent : Color
lightTransparent =
    rgba 0 0 0 0.54


veryLightTransparent : Color
veryLightTransparent =
    rgba 0 0 0 0.15


white : Color
white =
    rgb 255 255 255


blue87979F : Color
blue87979F =
    rgb 135 151 159


purple : Color
purple =
    rgb 64 42 131


lightPurple : Color
lightPurple =
    rgb 133 17 235


lightPurpleHl : Color
lightPurpleHl =
    rgb 119 91 202


orange : Color
orange =
    rgb 228 136 16


newRed : Color
newRed =
    rgb 208 2 27


newLightRed : Color
newLightRed =
    rgb 236 87 106


green : Color
green =
    -- #0BCF00
    rgb 11 207 0


btngreen : Color
btngreen =
    -- #25cb7b
    rgb 37 203 123


linkBlue : Color
linkBlue =
    -- #643cb4
    rgb 100 60 180



--rgb 147 192 31


green2 : Color
green2 =
    -- #38A876
    rgb 56 168 118


green3 : Color
green3 =
    -- #26cb7b
    rgb 38 203 123


lightGreen : Color
lightGreen =
    rgb 75 162 161


lightWhite : Color
lightWhite =
    rgb 245 242 242


newBlue : Color
newBlue =
    -- #582CDB
    rgb 88 44 219


violet : Color
violet =
    rgb 118 113 255


blue : Color
blue =
    -- for links
    rgb 72 144 226


grey485359 : Color
grey485359 =
    rgb 72 83 89


overflowHidden : List Style
overflowHidden =
    [ overflow "hidden" ]


purpleblue : Color
purpleblue =
    --#9073e7
    rgb 144 115 231


newBlack : Color
newBlack =
    rgb 89 89 89


lightBlue : Color
lightBlue =
    rgb 75 135 172


grey8595a6 : Color
grey8595a6 =
    rgb 133 149 166


greyf5f4fa : Color
greyf5f4fa =
    rgb 245 244 250


blue9073e7 : Color
blue9073e7 =
    rgb 144 115 231


lightGreyMessage : Color
lightGreyMessage =
    rgb 242 242 245


lightGreyMessageText : Color
lightGreyMessageText =
    rgb 145 145 163


lighterGrey : Color
lighterGrey =
    -- #FBFBFA
    rgb 251 251 250


lightestGrey : Color
lightestGrey =
    -- #FBFBFA
    rgb 232 232 232


lightGrey : Color
lightGrey =
    -- #D4D3CE
    rgb 212 211 206


labelGrey : Color
labelGrey =
    rgb 109 110 106


grey : Color
grey =
    -- #919191
    rgb 145 145 145


textGrey : Color
textGrey =
    -- #b6b6b6
    rgb 182 182 182


textGreyMid : Color
textGreyMid =
    -- #808080
    rgb 128 128 128


darkGrey : Color
darkGrey =
    -- #4A4A4A
    rgb 74 74 74


darkGrey2 : Color
darkGrey2 =
    -- #1d1d1d
    rgb 29 29 29


bgGrey : Color
bgGrey =
    -- #F4F3F0
    rgb 244 243 240


bgLightGrey : Color
bgLightGrey =
    -- #f7f7f7
    rgb 247 247 247


greyLight : Color
greyLight =
    -- #dedede
    rgb 222 222 222


newBgGrey : Color
newBgGrey =
    -- #fafafa
    rgb 250 250 250


newBgGrey2 : Color
newBgGrey2 =
    -- #fafafa
    rgb 156 156 156


bgLightestBlue : Color
bgLightestBlue =
    -- #F5F6FA
    rgb 245 246 250


bgLightestBlue2 : Color
bgLightestBlue2 =
    -- #eaebf1
    rgb 234 235 241


darkYellow : Color
darkYellow =
    -- #f5a623
    rgb 245 166 35


red : Color
red =
    rgb 237 28 36


redNew : Color
redNew =
    rgb 219 44 44


olaYellow : Color
olaYellow =
    rgb 233 170 95


footerDarkColor : Color
footerDarkColor =
    -- #222328
    rgb 34 35 40


greyadadad : Color
greyadadad =
    rgb 173 173 173


newFooterDarkColor : Color
newFooterDarkColor =
    -- #303030
    rgb 48 48 48


newGrayForPlaceHolder : Color
newGrayForPlaceHolder =
    rgb 175 175 185


footerTextColor : Color
footerTextColor =
    -- #8c8f94
    rgb 140 143 148


borderColorGrey : Color
borderColorGrey =
    -- #e8e9ea
    rgb 232 233 234


newPurple : Color
newPurple =
    rgb 148 72 255


darkPurple : Color
darkPurple =
    rgb 103 84 161


purple9a7af6 : Color
purple9a7af6 =
    rgb 154 122 246


grey686868 : Color
grey686868 =
    rgb 104 104 104


dateTimeCol : List Style
dateTimeCol =
    [ L.position "absolute"
    , L.right 22
    ]


olaShareAnchor : List Style
olaShareAnchor =
    [ L.position "relative"
    ]


olaDotSpace : List Style
olaDotSpace =
    [ L.marginTop 3
    ]


dotSpaceWrap : List Style
dotSpaceWrap =
    [ L.paddingVertical 25
    , L.paddingHorizontal 15
    , L.marginTop -25
    , cursor "pointer"
    ]


shareCertOla : List Style
shareCertOla =
    [ backgroundColor white
    , boxShadow "0" "3px" "9px" "0" <|
        withOpacity 1 lightGrey
    , L.paddingTop 15
    , L.paddingHorizontal 25
    , L.paddingBottom 30
    , L.position "fixed"
    , L.rawLeft "50%"
    , L.rawTop "50%"
    , L.zIndex 99
    , L.marginLeft <| -206 ~ -165
    , L.marginTop -106
    , L.minWidth <| 0 ~ 270
    , L.maxWidth <| 500 ~ 270
    ]


olaDotOptionsWrap : List Style
olaDotOptionsWrap =
    [ backgroundColor white
    , boxShadow "0" "3px" "9px" "0" <|
        withOpacity 1 lightGrey
    , L.paddingVertical 15
    , L.paddingHorizontal 25
    , L.position "absolute"
    , L.right 14
    , L.top 45
    , L.zIndex 2
    ]


olaDotOpt : List Style
olaDotOpt =
    [ color blue
    , L.paddingVertical 5
    ]


sendEmail : List Style
sendEmail =
    [ L.paddingHorizontal 30
    , L.paddingVertical 5
    , borderRadius 4
    , backgroundColor green
    , color white
    , fontWeight "bold"
    , fontSize 14
    , L.marginTop 15
    ]


sendEmailInActive : List Style
sendEmailInActive =
    [ backgroundColor lightGrey
    ]


shareCert : List Style
shareCert =
    [ fontSize 21
    , fontWeight "bold"
    , L.paddingBottom 15
    ]


emailCert : List Style
emailCert =
    [ L.paddingBottom 20 ]


positionRClaim : List Style
positionRClaim =
    [ L.height 20
    , L.position "relative"
    ]


successHistory : List Style
successHistory =
    [ L.position "absolute"
    , L.left -36
    ]


moreFaqs : List Style
moreFaqs =
    [ color blue
    , textDecorationStyle "solid"
    , L.paddingVertical 15
    , L.paddingHorizontal 45
    ]


ccs : List Style
ccs =
    [ color grey
    ]


ccsRow : List Style
ccsRow =
    [ L.paddingVertical 15
    , L.paddingHorizontal 15
    , L.justifyContent "center"
    , L.marginBottom 10
    ]


ccsRow1 : List Style
ccsRow1 =
    [ L.paddingVertical 15
    , L.paddingHorizontal 15
    , L.justifyContent "center"
    , L.position "absolute"
    , L.bottom 0
    , L.rawLeft "50%"
    , L.marginLeft -167
    ]


ccsImg : List Style
ccsImg =
    [ L.height 20
    , L.marginRight 8
    ]


olaClaimHistoryLinker1 : List Style
olaClaimHistoryLinker1 =
    [ borderLeftColor grey
    , borderLeftWidth 2
    , borderStyle "dashed"
    , L.position "absolute"
    , L.left -25
    , L.height 72
    , L.zIndex 0
    , L.top -25
    , L.marginLeft 35
    ]


actionsRow : List Style
actionsRow =
    [ L.justifyContent "center"
    , flexShrink "0"
    ]


actionsRow2 : List Style
actionsRow2 =
    [ L.justifyContent "center"
    , L.marginTop 15
    ]


olaLoaderBg : List Style
olaLoaderBg =
    [ L.position "fixed"
    , L.heightRaw "100%"
    , L.widthRaw "100%"
    , backgroundColor white
    , L.zIndex 1
    , L.top 0
    , L.left 0
    , L.bottom 0
    , L.right 0
    ]


heightLoader : List Style
heightLoader =
    [ L.height 70
    , L.position <| "absolute" ~ "fixed"
    , L.rawLeft "50%"
    , L.rawTop "50%"
    , L.marginLeft -70
    , L.marginTop -35
    , L.zIndex 2
    ]


bikeLoader : List Style
bikeLoader =
    [ L.height 40
    , L.position <| "absolute" ~ "fixed"
    , L.rawLeft "50%"
    , L.rawTop "50%"
    , L.rawTransform "translate(-50%, -50%)"
    , L.zIndex 2
    ]


margin0 : List Style
margin0 =
    [ L.marginTop 0
    ]


apiErrorWrapper : List Style
apiErrorWrapper =
    [ L.widthRaw "100%" ]


apiErrorImg : List Style
apiErrorImg =
    [ L.marginTop <| 10 ~ 10
    , L.marginBottom 10
    , L.rawMarginHorizontal "auto"
    , L.rawMarginVertical "auto"
    , L.display "block"
    , L.height <| 336 ~ 240
    ]


apiErrorHeader404 : List Style
apiErrorHeader404 =
    [ fontSize 80
    , fontWeight "600"
    , L.marginVertical 30
    , L.marginHorizontal 0
    , L.alignSelf "center"
    ]


apiErrorHeader2 : List Style
apiErrorHeader2 =
    [ L.alignSelf "center"
    , fontWeight "600"
    , fontSize <| 30 ~ 25
    ]


apiErrorHeader3 : List Style
apiErrorHeader3 =
    [ L.alignSelf "center"
    , fontWeight "600"
    , fontSize <| 30 ~ 25
    , L.marginBottom 30
    ]


apiErrorText1 : List Style
apiErrorText1 =
    [ L.alignSelf "center"
    , fontSize <| 18 ~ 16
    ]


apiErrorText2 : List Style
apiErrorText2 =
    [ L.alignSelf "center"
    , fontSize <| 18 ~ 16
    , L.marginBottom 30
    ]


apiErrorButton : List Style
apiErrorButton =
    [ fontWeight "600"
    , backgroundColor green
    , borderRadius 5
    , L.marginVertical 10
    , L.alignSelf "center"
    , textAlign "center"
    , color white
    , L.paddingVertical 15
    , L.paddingHorizontal 30
    , L.widthRaw "30%"
    ]


socialFooterIcons : List Style
socialFooterIcons =
    [ L.marginRight 5
    ]


positionRight : List Style
positionRight =
    [ L.rawMarginLeft "auto"
    ]


plusIcon : List Style
plusIcon =
    [ fontSize 20
    , fontWeight "600"
    , L.marginRight 16
    ]


greenActionButton : List Style
greenActionButton =
    [ backgroundColor btngreen
    , L.paddingHorizontal 30
    , L.paddingVertical 15
    , borderRadius 5
    , color white
    , cursor "pointer"
    , L.widthRaw "100%"
    , L.boxSizing "border-box"

    --, L.height 48
    --, rawLineHeight "48px"
    , textAlign "center"
    , borderRadius 5
    , L.marginVertical 25
    , fontSize 14
    , fontWeight "600"
    , fontFamily "Montserrat"
    ]


disabledActionButton : List Style
disabledActionButton =
    [ backgroundColor textGrey
    , L.paddingHorizontal 30
    , borderRadius 5
    , color white
    , cursor "not-allowed"
    , L.widthRaw "100%"
    , L.boxSizing "border-box"
    , L.height 48
    , rawLineHeight "48px"
    , textAlign "center"
    , borderRadius 5
    , L.marginVertical 25
    ]
