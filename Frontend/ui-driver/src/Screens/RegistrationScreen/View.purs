{-
 
  Copyright 2022-23, Juspay India Pvt Ltd
 
  This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License
 
  as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program
 
  is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 
  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of
 
  the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}

module Screens.RegistrationScreen.View where

import Common.Types.App
import Debug
import Mobility.Prelude
import Screens.RegistrationScreen.ComponentConfig

import Animation as Anim
import Common.Animation.Config as AnimConfig
import Animation.Config as AnimConf
import Components.AppOnboardingNavBar as AppOnboardingNavBar
import Components.InAppKeyboardModal as InAppKeyboardModal
import Components.PopUpModal as PopUpModal
import Components.PrimaryButton as PrimaryButton
import Components.PrimaryEditText as PrimaryEditText
import Control.Monad.ST (for)
import Data.Array (all, any, elem, filter, fold, length, mapWithIndex, find)
import Data.Foldable (foldl)
import Data.Maybe (Maybe(..), isJust, isNothing)
import Data.String as DS
import Effect (Effect)
import Effect.Uncurried (runEffectFn1)
import Engineering.Helpers.Commons (getNewIDWithTag)
import Engineering.Helpers.Commons as EHC
import Font.Size as FontSize
import Font.Style as FontStyle
import Helpers.Utils (fetchImage, FetchImageFrom(..))
import JBridge (lottieAnimationConfig, startLottieProcess)
import Language.Strings (getString, getVarString)
import Language.Types (STR(..))
import PaymentPage (consumeBP)
import Prelude (Unit, bind, const, map, not, pure, show, unit, void, ($), (&&), (+), (-), (<<<), (<>), (==), (>=), (||), (/=), (*), (>), (/))
import PrestoDOM (Gravity(..), Length(..), Margin(..), Orientation(..), Padding(..), PrestoDOM, Prop, Screen, Visibility(..), afterRender, alignParentBottom, background, clickable, color, cornerRadius, editText, fontStyle, gravity, height, hint, id, imageUrl, imageView, imageWithFallback, layoutGravity, linearLayout, lottieAnimationView, margin, onAnimationEnd, onBackPressed, onChange, onClick, orientation, padding, pattern, relativeLayout, stroke, text, textSize, textView, visibility, weight, width, scrollView, scrollBarY, fillViewport, alpha)
import PrestoDOM.Animation as PrestoAnim
import PrestoDOM.Properties (cornerRadii)
import PrestoDOM.Types.DomAttributes (Corners(..))
import Screens.RegistrationScreen.Controller (Action(..), eval, ScreenOutput)
import Screens.Types (RegisterationStep(..), StageStatus(..), ValidationStatus(..))
import Screens.Types as ST
import Services.API as API
import Storage (KeyStore(..), getValueToLocalNativeStore)
import Storage (getValueToLocalStore, KeyStore(..))
import Styles.Colors as Color
import Screens.RegistrationScreen.ScreenData as SD
import Resource.Constants as Constant
import Data.Int (toNumber, floor)
import Components.OptionsMenu as OptionsMenu

screen :: ST.RegistrationScreenState -> Screen Action ST.RegistrationScreenState ScreenOutput
screen initialState =
  { initialState
  , view
  , name : "RegistrationScreen"
  , globalEvents : []
  , eval :
      ( \state action -> do
          let _ = spy "RegistrationScreen ----- state" state
          let _ = spy "RegistrationScreen --------action" action
          eval state action
      )
  }

view ::
  forall w.
  (Action -> Effect Unit) ->
  ST.RegistrationScreenState ->
  PrestoDOM (Effect Unit) w
view push state =
  let showSubscriptionsOption = (getValueToLocalNativeStore SHOW_SUBSCRIPTIONS == "true") && state.data.config.bottomNavConfig.subscription.isVisible
      documentList = if state.data.vehicleCategory == Just ST.CarCategory then state.data.registerationStepsCabs else state.data.registerationStepsAuto
      completedStatusCount = length $ filter (\doc -> (getStatus doc.stage state) == ST.COMPLETED) documentList
      subScriptionStepCount = if showSubscriptionsOption && state.data.subscriptionStatus == IN_PROGRESS then 1 else 0
      progressPercent = floor $ (toNumber completedStatusCount - toNumber subScriptionStepCount) / toNumber (length documentList) * 100.0
  in
    Anim.screenAnimation
      $ relativeLayout
          [ height MATCH_PARENT
          , width MATCH_PARENT
          , orientation VERTICAL
          , background Color.white900
          , clickable true
          , onBackPressed push (const BackPressed)
          , afterRender
              ( \action -> do
                  _ <- push action
                  pure unit
              )
              $ const (AfterRender)
          ]
      $ [ chooseVehicleView push state
        , linearLayout
            [ height MATCH_PARENT
            , width MATCH_PARENT
            , gravity CENTER
            , orientation VERTICAL
            , visibility $ boolToVisibility $ isJust state.data.vehicleCategory || not state.data.cityConfig.variantSubscriptionConfig.enableVariantBasedSubscription
            ]
            [ headerView state push                    
            , linearLayout
                [ height WRAP_CONTENT
                , width MATCH_PARENT
                , orientation VERTICAL
                , padding $ Padding 16 16 16 0
                , weight 1.0
                ]
                [ imageView
                    [ width (V 20)
                    , height (V 20)
                    , imageWithFallback $ fetchImage FF_ASSET "ny_ic_back"
                    , visibility GONE
                    ]
                , linearLayout
                    [ width MATCH_PARENT
                    , height WRAP_CONTENT
                    , orientation VERTICAL
                    ]
                    [ linearLayout
                        [ width MATCH_PARENT
                        , height WRAP_CONTENT
                        , margin $ MarginBottom 20
                        , gravity CENTER_VERTICAL
                        ]
                        [ imageView
                            [ width $ V 32
                            , height $ V 32
                            , margin $ MarginRight 4
                            , imageWithFallback $ fetchImage FF_ASSET if state.data.vehicleCategory == Just ST.CarCategory then "ny_ic_sedan_side" else "ny_ic_auto_side"
                            ]
                        , textView
                            $ [ width WRAP_CONTENT
                              , height WRAP_CONTENT
                              , text $ getVarString START_EARNING_IN_FOUR_STEPS [ "" ]
                              , weight 1.0
                              ]
                            <> FontStyle.body2 TypoGraphy
                        , textView
                            $ [ width WRAP_CONTENT
                              , height WRAP_CONTENT
                              , text $ show progressPercent <> "% " <> getString COMPLETE
                              ]
                            <> FontStyle.body2 TypoGraphy
                        ]
                    , linearLayout
                        [ width MATCH_PARENT
                        , height WRAP_CONTENT
                        , margin $ MarginBottom 20
                        , weight 1.0
                        , visibility GONE
                        ]
                        ( mapWithIndex
                            ( \index item ->
                                linearLayout
                                  [ height $ V 5
                                  , weight 1.0
                                  , cornerRadius 2.0
                                  , visibility case item.stage of
                                      ST.SUBSCRIPTION_PLAN -> boolToVisibility showSubscriptionsOption
                                      _ -> VISIBLE
                                  , background case getStatus item.stage state of
                                      ST.COMPLETED -> Color.green900
                                      ST.IN_PROGRESS -> Color.yellow900
                                      ST.FAILED -> Color.red
                                      ST.NOT_STARTED -> Color.grey900
                                  , margin $ MarginLeft if index == 0 then 0 else 15
                                  ]
                                  []
                            )
                            (documentList)
                        )
                    , cardsListView push state
                    ]
                ]
            , refreshView push state
            , linearLayout
                [ height $ V 1
                , width MATCH_PARENT
                , background Color.grey900
                , margin $ MarginBottom 16
                , visibility $ boolToVisibility state.props.driverEnabled
                ]
                []
            , linearLayout
                [ height WRAP_CONTENT
                , width MATCH_PARENT
                , gravity CENTER
                , margin $ Margin 16 0 16 16
                , visibility $ boolToVisibility state.props.driverEnabled
                ]
                [ PrimaryButton.view (push <<< PrimaryButtonAction) (primaryButtonConfig state) ]
            , linearLayout
                [ height WRAP_CONTENT
                , width MATCH_PARENT
                , margin $ Margin 16 0 16 16
                , clickable false
                , visibility $ boolToVisibility $ state.data.cityConfig.showDriverReferral || state.data.config.enableDriverReferral
                ][enterReferralCode push state]
            , linearLayout
                [ height WRAP_CONTENT
                , width MATCH_PARENT
                , margin $ Margin 16 0 16 16
                , clickable false
                , visibility $ boolToVisibility callSupportVisibility
                ][contactSupportView push state]
            ]
            , if state.props.enterReferralCodeModal then enterReferralCodeModal push state else linearLayout[][]
        ]
      <> if any (_ == true) [state.props.logoutModalView, state.props.confirmChangeVehicle, state.data.vehicleTypeMismatch] then [ popupModal push state ] else []
      <> if state.props.contactSupportModal /= ST.HIDE then [contactSupportModal push state] else []
      <> if state.props.menuOptions then [menuOptionModal push state] else []
      where callSupportVisibility = (state.data.drivingLicenseStatus == ST.FAILED && state.data.enteredDL /= "__failed") || (state.data.vehicleDetailsStatus == ST.FAILED && state.data.enteredRC /= "__failed")

headerView :: forall w. ST.RegistrationScreenState -> (Action -> Effect Unit) -> PrestoDOM (Effect Unit) w
headerView state push = AppOnboardingNavBar.view (push <<< AppOnboardingNavBarAC) (appOnboardingNavBarConfig state)

menuOptionModal :: forall w. (Action -> Effect Unit) -> ST.RegistrationScreenState -> PrestoDOM (Effect Unit) w
menuOptionModal push state = 
  linearLayout 
    [ height MATCH_PARENT
    , width MATCH_PARENT
    , padding $ PaddingTop 55
    , background Color.blackLessTrans
    ][ OptionsMenu.view (push <<< OptionsMenuAction) (optionsMenuConfig state) ]

contactSupportView :: forall w. (Action -> Effect Unit) -> ST.RegistrationScreenState -> PrestoDOM (Effect Unit) w
contactSupportView push state = 
  linearLayout
    [ width MATCH_PARENT
    , height WRAP_CONTENT
    , orientation HORIZONTAL
    , stroke $ "1," <> Color.grey900
    , cornerRadius 4.0
    , padding $ Padding 10 8 10 8
    , gravity CENTER_VERTICAL
    , onClick push $ const $ SupportClick true
    , visibility $ boolToVisibility $ viewVisibility
    ][  textView $
        [ width MATCH_PARENT
        , height WRAP_CONTENT
        , color Color.black800
        , text $ getString NEED_HELP
        , weight 1.0
        ] <> FontStyle.body3 TypoGraphy
      , textView $
        [ width WRAP_CONTENT
        , height WRAP_CONTENT
        , text $ getString CONTACT_SUPPORT
        , margin $ MarginRight 7
        , color Color.blue900
        ] <> FontStyle.tags TypoGraphy
      ]
      where viewVisibility = state.props.contactSupportView && (state.data.cityConfig.registration.callSupport || state.data.cityConfig.registration.whatsappSupport)

contactSupportModal :: forall w. (Action -> Effect Unit) -> ST.RegistrationScreenState -> PrestoDOM (Effect Unit) w
contactSupportModal push state = 
  linearLayout
  [ height MATCH_PARENT
  , width MATCH_PARENT
  , background Color.black9000
  , clickable true
  , gravity BOTTOM
  , onClick push $ const BackPressed
  , visibility $ boolToVisibility $ state.props.contactSupportModal /= ST.HIDE
  ][  PrestoAnim.animationSet
      [ Anim.translateYAnim AnimConfig.animConfig {fromY = 300, toY = 0, ifAnim = state.props.contactSupportModal == ST.SHOW}
      , Anim.translateYAnim AnimConfig.animConfig {fromY = 0, toY = 300, ifAnim = state.props.contactSupportModal == ST.ANIMATING}
      ] $
        linearLayout
          [ width MATCH_PARENT
          , height WRAP_CONTENT
          , gravity BOTTOM
          , orientation VERTICAL
          , background Color.white900
          , cornerRadii $ Corners 24.0 true true false false
          , padding $ Padding 16 16 16 24
          , onAnimationEnd push $ const $ SupportClick false
          ][  commonTV push (getString CONTACT_SUPPORT_VIA) Color.black700 FontStyle.subHeading2 LEFT 8 NoAction true (Padding 16 0 0 20)
            , supportComponent push state {prefixImg : "ny_ic_whatsapp_black", title : "Whatsapp", desc : getString YOU_CAN_SHARE_SCREENSHOT , postFixImg : "ny_ic_chevron_right", action : WhatsAppClick, visibility : state.data.cityConfig.registration.whatsappSupport}
            , linearLayout[width MATCH_PARENT, height $ V 1, background Color.grey900, margin $ MarginVertical 16 16, visibility border][]
            , supportComponent push state {prefixImg : "ny_ic_direct_call", title : getString CALL, desc : getString PLACE_A_CALL, postFixImg : "ny_ic_chevron_right", action : CallButtonClick, visibility : state.data.cityConfig.registration.callSupport}
          ]
  ]
  where border = boolToVisibility $ state.data.cityConfig.registration.callSupport && state.data.cityConfig.registration.whatsappSupport

type SupportComponent = {
  prefixImg :: String,
  title :: String,
  desc :: String,
  postFixImg :: String,
  action :: Action,
  visibility :: Boolean
}

supportComponent :: forall w. (Action -> Effect Unit) -> ST.RegistrationScreenState -> SupportComponent -> PrestoDOM (Effect Unit) w
supportComponent push state supportComponent = 
  linearLayout
  [ width MATCH_PARENT
  , height WRAP_CONTENT
  , gravity CENTER_VERTICAL
  , onClick push $ const supportComponent.action
  , visibility $ boolToVisibility supportComponent.visibility
  ][  imageView
      [ width $ V 26
      , height $ V 26
      , imageWithFallback $ fetchImage FF_ASSET supportComponent.prefixImg
      ]
    , linearLayout
      [ weight 1.0
      , height WRAP_CONTENT
      , orientation VERTICAL
      , margin $ MarginHorizontal 10 10
      ][  commonTV push supportComponent.title Color.black800 FontStyle.subHeading2 LEFT 0 NoAction true (PaddingTop 0)
        , commonTV push supportComponent.desc Color.black600 FontStyle.tags LEFT 4 NoAction true (PaddingTop 0)
      ]
    , imageView
      [ width $ V 26
      , height $ V 26
      , imageWithFallback $ fetchImage FF_ASSET supportComponent.postFixImg
      ]
  ]

commonTV :: forall w .  (Action -> Effect Unit) -> String -> String -> (LazyCheck -> forall properties. (Array (Prop properties))) -> Gravity -> Int -> Action -> Boolean -> Padding -> PrestoDOM (Effect Unit) w
commonTV push text' color' theme gravity' marginTop action visibility' padding' = 
  textView $
  [ width MATCH_PARENT
  , height WRAP_CONTENT
  , color color'
  , gravity gravity'
  , margin $ MarginTop marginTop
  , padding padding'
  , text text'
  , visibility $ boolToVisibility visibility'
  ] <> theme TypoGraphy
    <>  if action == NoAction then []
        else [onClick push $ const action]

cardsListView :: forall w. (Action -> Effect Unit) -> ST.RegistrationScreenState -> PrestoDOM (Effect Unit) w
cardsListView push state =
  scrollView
    [ width MATCH_PARENT
    , height WRAP_CONTENT
    , scrollBarY false
    , fillViewport true
    , margin $ MarginBottom 20
    ][ linearLayout
        [ width MATCH_PARENT
        , height WRAP_CONTENT
        , orientation VERTICAL
        , weight 1.0
        ][ if state.data.vehicleCategory == Just ST.CarCategory then
            vehicleSpecificList push state state.data.registerationStepsCabs
          else
            vehicleSpecificList push state state.data.registerationStepsAuto
        ]
    ]

vehicleSpecificList :: forall w. (Action -> Effect Unit) -> ST.RegistrationScreenState -> Array ST.StepProgress -> PrestoDOM (Effect Unit) w
vehicleSpecificList push state registerationSteps = 
  let mandatoryDocs = filter(\elem -> elem.isMandatory) registerationSteps
      optionalDocs = filter(\elem -> not elem.isMandatory) registerationSteps
  in
  linearLayout
    [ width MATCH_PARENT
    , height WRAP_CONTENT
    , orientation VERTICAL
    ][  linearLayout
        [ width MATCH_PARENT
        , height WRAP_CONTENT
        , orientation VERTICAL
        ](map (\item -> listItem push item state) mandatoryDocs)
      , linearLayout
        [ width MATCH_PARENT
        , height WRAP_CONTENT
        , gravity CENTER_VERTICAL
        , visibility $ boolToVisibility $ length optionalDocs > 0
        , onClick push $ const ExpandOptionalDocs
        ][ textView $
            [ text "Optional Document"
            , color Color.black800
            ] <> FontStyle.body1 TypoGraphy
          , imageView
            [ imageWithFallback
                $ fetchImage FF_ASSET
                    if state.props.optionalDocsExpanded then
                      "ny_ic_chevron_up"
                    else
                      "ny_ic_chevron_down"
            , height $ V 12
            , width $ V 12
            , margin $ MarginLeft 6
            ]
        ]
      , linearLayout
        [ width MATCH_PARENT
        , height WRAP_CONTENT
        , orientation VERTICAL
        , margin $ MarginTop 20
        , visibility $ boolToVisibility $ length optionalDocs > 0 && state.props.optionalDocsExpanded
        ](map (\item -> listItem push item state) optionalDocs)
    ]

listItem :: forall w. (Action -> Effect Unit) ->  ST.StepProgress -> ST.RegistrationScreenState -> PrestoDOM (Effect Unit) w
listItem push item state = 
  linearLayout
    [ width MATCH_PARENT
    , height WRAP_CONTENT
    , orientation HORIZONTAL
    , padding $ Padding 12 12 12 12
    , cornerRadius 8.0
    , visibility $ boolToVisibility $ cardVisibility item state
    , stroke $ componentStroke state item
    , background $ compBg state item
    , clickable $ compClickable state item
    , alpha $ compAlpha state item
    , onClick push (const (RegistrationAction item.stage))
    , margin (MarginBottom 20)
    , gravity CENTER_VERTICAL
    ][  linearLayout
        [ width WRAP_CONTENT
        , height WRAP_CONTENT
        , background case getStatus item.stage state of
                              ST.NOT_STARTED -> Color.blue600
                              _ -> Color.white900
        , cornerRadius 24.0
        , padding $ Padding 8 8 8 8
        , margin (MarginRight 14)
        ][ imageView
          [ imageWithFallback $ compImage item
          , width $ V 24
          , height $ V 24
          ]
        ]
    ,  linearLayout
      [ width WRAP_CONTENT
      , height WRAP_CONTENT
      , orientation VERTICAL
      , gravity CENTER_VERTICAL
      , weight 1.0
      ][ textView $
          [ text item.stageName
          , color Color.black800
          ] <> FontStyle.body1 TypoGraphy
        , textView $
          [ color Color.black700
          ] <> FontStyle.body3 TypoGraphy
            <> case (getVerificationMessage item.stage state) of
                Just txt -> [text txt, visibility $ boolToVisibility $ not showRetry && docUploadStarted]
                Nothing -> [visibility GONE]
        , textView $
          [ text $ getString RETRY_UPLOAD
          , color Color.blue900
          , visibility $ boolToVisibility $ showRetry
          , margin $ MarginTop 2
          ] <> FontStyle.tags TypoGraphy
      ]
        , imageView
          [ imageWithFallback $ compStatusImg state item
          , width (V 20)
          , height (V 20)
          ]
    ]
    where 
      showRetry = getStatus item.stage state == ST.FAILED && not checkLimitReached item.stage state.props.limitReachedFor
      docUploadStarted = getStatus item.stage state /= ST.NOT_STARTED

      compImage :: ST.StepProgress -> String
      compImage item = 
        fetchImage FF_ASSET $ case item.stage of
          ST.DRIVING_LICENSE_OPTION -> "ny_ic_dl_blue"
          ST.VEHICLE_DETAILS_OPTION -> if state.data.vehicleCategory == Just ST.CarCategory then "ny_ic_car_onboard" else "ny_ic_vehicle_onboard"
          ST.GRANT_PERMISSION -> "ny_ic_grant_permission"
          ST.SUBSCRIPTION_PLAN -> "ny_ic_plus_circle_blue"
          ST.PROFILE_PHOTO -> "ny_ic_profile_image_blue"
          ST.AADHAAR_CARD -> "ny_ic_aadhaar_blue"
          ST.PAN_CARD -> "ny_ic_pan"
          ST.VEHICLE_PERMIT -> "ny_ic_permit"
          ST.FITNESS_CERTIFICATE -> "ny_ic_fitness"
          ST.VEHICLE_INSURANCE -> "ny_ic_insurance"
          ST.VEHICLE_PUC -> "ny_ic_puc"
          _ -> ""

      componentStroke :: ST.RegistrationScreenState -> ST.StepProgress -> String
      componentStroke state item = 
        let strokeWidth = "1,"
            colour = case getStatus item.stage state of
                      ST.COMPLETED -> Color.green900
                      ST.IN_PROGRESS -> Color.yellow900
                      ST.NOT_STARTED -> Color.black500
                      ST.FAILED -> Color.red
                      _ -> Color.black500
        in strokeWidth <> colour

      compBg :: ST.RegistrationScreenState -> ST.StepProgress -> String
      compBg state item = 
        case getStatus item.stage state of
          ST.COMPLETED -> Color.greenOpacity10
          ST.IN_PROGRESS -> Color.yellowOpacity10
          ST.NOT_STARTED -> Color.white900
          ST.FAILED -> Color.redOpacity10
          _ -> Color.white900

      compClickable :: ST.RegistrationScreenState -> ST.StepProgress -> Boolean
      compClickable state item = dependentDocAvailable item state && not item.isDisabled && not 
        case item.stage of
          ST.DRIVING_LICENSE_OPTION -> state.props.limitReachedFor == Just "DL" || any (_ == state.data.drivingLicenseStatus) [COMPLETED, IN_PROGRESS]
          ST.GRANT_PERMISSION -> state.data.permissionsStatus == COMPLETED
          ST.SUBSCRIPTION_PLAN -> state.data.subscriptionStatus == COMPLETED
          _ -> (getStatus item.stage state) == ST.COMPLETED

      compAlpha :: ST.RegistrationScreenState -> ST.StepProgress -> Number
      compAlpha state item = if dependentDocAvailable item state && not item.isDisabled then 1.0 else 0.5

      compStatusImg :: ST.RegistrationScreenState -> ST.StepProgress -> String
      compStatusImg state item = 
        case getStatus item.stage state of
          ST.COMPLETED -> "ny_ic_green_tick,https://assets.juspay.in/nammayatri/images/driver/ny_ic_green_tick"
          ST.IN_PROGRESS -> "ny_ic_pending,https://assets.juspay.in/nammayatri/images/driver/ny_ic_pending"
          ST.NOT_STARTED -> "ny_ic_chevron_right,https://assets.juspay.in/nammayatri/images/driver/ny_ic_chevron_right"
          ST.FAILED -> "ny_ic_warning_filled_red,https://assets.juspay.in/nammayatri/images/driver/ny_ic_warning_filled_red"

      getVerificationMessage :: ST.RegisterationStep -> ST.RegistrationScreenState -> Maybe String
      getVerificationMessage step state = 
        case step of
          GRANT_PERMISSION -> Nothing
          _ -> let currentDoc = find (\docStatus -> docStatus.docType == step) state.data.documentStatusList
                in case currentDoc of
                    Just doc -> doc.verificationMessage
                    _ -> Nothing

      cardVisibility :: ST.StepProgress -> ST.RegistrationScreenState -> Boolean
      cardVisibility item state = 
        case item.stage of
          SUBSCRIPTION_PLAN -> not item.isHidden && (getValueToLocalNativeStore SHOW_SUBSCRIPTIONS == "true") && state.data.config.bottomNavConfig.subscription.isVisible
          _ -> not item.isHidden


popupModal :: forall w . (Action -> Effect Unit) -> ST.RegistrationScreenState -> PrestoDOM (Effect Unit) w
popupModal push state =
    linearLayout
    [ width MATCH_PARENT
    , height MATCH_PARENT
    , background Color.blackLessTrans
    ][ PopUpModal.view (push <<< action) popupConfig ] 
    where 
      action = if state.props.logoutModalView then PopUpModalLogoutAction 
                else if state.props.confirmChangeVehicle then ChangeVehicleAC
                else if state.data.vehicleTypeMismatch then VehicleMismatchAC
                else VehicleMismatchAC
      popupConfig = if state.props.logoutModalView then logoutPopUp Language
                    else if state.props.confirmChangeVehicle then changeVehicleConfig FunctionCall
                    else if state.data.vehicleTypeMismatch then vehicleMismatchConfig state
                    else vehicleMismatchConfig state

refreshView :: forall w . (Action -> Effect Unit) -> ST.RegistrationScreenState -> PrestoDOM (Effect Unit) w
refreshView push state =
  let documentList = if state.data.vehicleCategory == Just ST.CarCategory then state.data.registerationStepsCabs else state.data.registerationStepsAuto
      showRefresh = any (_ == IN_PROGRESS) $ map (\item -> getStatus item.stage state) documentList
  in 
    linearLayout
      [ width MATCH_PARENT
      , height WRAP_CONTENT
      , stroke $ "1,"<> Color.grey900
      , padding $ Padding 16 12 16 12
      , cornerRadius 8.0
      , alignParentBottom "true,-1"
      , onClick push $ const Refresh
      , margin $ Margin 16 0 16 16
      , visibility $ boolToVisibility $ showRefresh
      ][ textView $
          [ text $ getString LAST_UPDATED
          , gravity CENTER
          ] <> FontStyle.body3 TypoGraphy
        , textView $
          [ text state.data.lastUpdateTime
          , gravity CENTER
          , margin $ MarginLeft 6
          ] <> FontStyle.body15 TypoGraphy
        , linearLayout
          [ width WRAP_CONTENT
          , weight 1.0
          ][] 
        , PrestoAnim.animationSet [Anim.rotateAnim (AnimConf.rotateAnimConfig state.props.refreshAnimation)] $
          imageView
          [ imageWithFallback $ fetchImage FF_ASSET "ny_ic_refresh"
          , height $ V 16
          , width $ V 16
          ]
        , textView $ 
          [ text $ getString REFRESH_STRING
          , color Color.blue800
          , margin $ MarginLeft 4
          ] <> FontStyle.body9 TypoGraphy
      ]

enterReferralCode :: forall w . (Action -> Effect Unit) -> ST.RegistrationScreenState -> PrestoDOM (Effect Unit) w
enterReferralCode push state =
  let allStepsCompleted = state.props.driverEnabled
    in linearLayout
            [ width MATCH_PARENT
            , height WRAP_CONTENT
            , orientation HORIZONTAL
            , stroke $ "1," <> Color.grey900
            , cornerRadius 4.0
            , padding $ Padding 10 8 10 8
            ][  textView $
                [ width MATCH_PARENT
                , height WRAP_CONTENT
                , color if allStepsCompleted then Color.black900 else Color.greyTextColor
                , text $ getString if state.props.referralCodeSubmitted then REFERRAL_APPLIED else HAVE_A_REFERRAL_CODE
                , weight 1.0
                ] <> FontStyle.body3 TypoGraphy
              , textView $
                [ width WRAP_CONTENT
                , height WRAP_CONTENT
                , text $ getString ENTER_CODE
                , margin $ MarginRight 7
                , color if allStepsCompleted then Color.darkBlue else Color.primaryBG
                , onClick push $ const $ EnterReferralCode allStepsCompleted
                , visibility $ boolToVisibility $ not state.props.referralCodeSubmitted
                ] <> FontStyle.body3 TypoGraphy
              , imageView
                [ width $ V 20
                , height $ V 20 
                , imageWithFallback $ fetchImage FF_COMMON_ASSET "ny_ic_green_tick"
                , visibility $ boolToVisibility state.props.referralCodeSubmitted
                , margin $ MarginRight 7
                ]
              ]

enterReferralCodeModal :: forall w . (Action -> Effect Unit) -> ST.RegistrationScreenState -> PrestoDOM (Effect Unit) w
enterReferralCodeModal push state =
  InAppKeyboardModal.view (push <<< InAppKeyboardModalAction) (enterReferralStateConfig state)

checkLimitReached :: ST.RegisterationStep -> Maybe String -> Boolean
checkLimitReached step limitReachedFor = 
  case limitReachedFor of
    Just "RC" -> step == ST.VEHICLE_DETAILS_OPTION
    Just "DL" -> step == ST.DRIVING_LICENSE_OPTION
    _ -> false

chooseVehicleView :: forall w . (Action -> Effect Unit) -> ST.RegistrationScreenState -> PrestoDOM (Effect Unit) w
chooseVehicleView push state = 
  linearLayout
    [ width MATCH_PARENT
    , height MATCH_PARENT
    , orientation VERTICAL
    , visibility $ boolToVisibility $ isNothing state.data.vehicleCategory && state.data.cityConfig.variantSubscriptionConfig.enableVariantBasedSubscription
    ]
    [ headerView state push
    , textView $ 
      [ text $ getString SELECT_YOUR_VEHICLE_TYPE
      , color Color.black700
      , margin $ Margin 16 24 16 0
      , height WRAP_CONTENT
      , width MATCH_PARENT
      ] <> FontStyle.body1 TypoGraphy
    , variantListView push state
    , linearLayout [ weight 1.0 ][]
    , linearLayout
      [ width MATCH_PARENT
      , height WRAP_CONTENT
      , orientation VERTICAL
      ]
      [  linearLayout 
         [ height $ V 1
         , width MATCH_PARENT
         , background Color.grey900
         ]
         []
      , PrimaryButton.view (push <<< ContinueButtonAction) (continueButtonConfig state)
      ]
    ]

variantListView :: forall w . (Action -> Effect Unit) -> ST.RegistrationScreenState -> PrestoDOM (Effect Unit) w
variantListView push state = 
  linearLayout
  [ width MATCH_PARENT
  , height WRAP_CONTENT
  , orientation VERTICAL
  , padding $ Padding 16 0 16 16
  , gravity CENTER
  ]( mapWithIndex
      ( \index item -> 
          let stroke' = case state.props.selectedVehicleIndex of
                          Just i -> if i == index 
                                      then "2," <> Color.blue800 
                                      else "1," <> Color.grey900
                          Nothing -> "1," <> Color.grey900
          in
          linearLayout
          [ width MATCH_PARENT
          , height WRAP_CONTENT
          , cornerRadius 8.0
          , stroke stroke'
          , gravity CENTER_VERTICAL
          , margin $ MarginTop 16
          , onClick push $ const $ ChooseVehicleCategory index
          ][  imageView
              [ width $ V 116
              , height $ V 80
              , imageWithFallback $ fetchImage FF_ASSET 
                  case item of
                    ST.AutoCategory -> "ny_ic_auto_side"
                    ST.CarCategory -> "ny_ic_sedan_side"
              ]
            , textView $
              [ width WRAP_CONTENT
              , height WRAP_CONTENT
              , text case item of
                        ST.AutoCategory -> getString AUTO_RICKSHAW
                        ST.CarCategory -> getString CAR
              , color Color.black800
              , margin $ MarginLeft 20
              ] <> FontStyle.subHeading1 TypoGraphy
          ]
      ) (state.data.variantList))

getStatus :: ST.RegisterationStep -> ST.RegistrationScreenState -> ST.StageStatus
getStatus step state = 
  case step of
    ST.GRANT_PERMISSION -> state.data.permissionsStatus
    -- ST.SUBSCRIPTION_PLAN -> state.data.subscriptionStatus  //don't check from frontend
    _ -> do
          let documentStatusArr = state.data.documentStatusList
              vehicleDoc = [ ST.VEHICLE_PERMIT, ST.FITNESS_CERTIFICATE, ST.VEHICLE_INSURANCE, ST.VEHICLE_PUC, ST.VEHICLE_DETAILS_OPTION]
              findStatus = if step `elem` vehicleDoc 
                          then find (\docStatus -> docStatus.docType == step && filterCondition docStatus) documentStatusArr
                          else find (\docStatus -> docStatus.docType == step) documentStatusArr
          case findStatus of
            Nothing -> ST.NOT_STARTED
            Just docStatus -> docStatus.status
  where filterCondition item = (state.data.vehicleCategory == item.verifiedVehicleCategory) ||  (isNothing item.verifiedVehicleCategory && item.vehicleType == state.data.vehicleCategory)

dependentDocAvailable :: ST.StepProgress -> ST.RegistrationScreenState -> Boolean
dependentDocAvailable item state = all (\docType -> (getStatus docType state) == ST.COMPLETED) item.dependencyDocumentType