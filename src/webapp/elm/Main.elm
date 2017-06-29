module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Navigation exposing (..)
import Ports
import Login
import Dashboard
import Suppression


-- MODEL


type alias Model =
    { page : Page
    , username : Maybe String
    , loggedIn : Bool
    , login : Login.Model
    , dashboard : Dashboard.Model
    , suppression : Suppression.Model
    }


type Page
    = DashboardPage
    | SuppressionPage
    | LoginPage
    | NotFoundPage


type alias Flags =
    { username : Maybe String
    }


authWhiteListPages : List Page
authWhiteListPages =
    [ LoginPage, NotFoundPage ]


init : Flags -> Location -> ( Model, Cmd Msg )
init flags location =
    let
        page =
            hashToPage location.hash

        loggedIn =
            flags.username /= Nothing

        ( updatedPage, cmd ) =
            onChangePage page loggedIn

        ( loginInitModel, loginCmd ) =
            Login.init

        ( suppressionInitModel, suppressionCmd ) =
            Suppression.init

        ( dashboardInitModel, dashboardCmd ) =
            Dashboard.init

        initModel =
            { page = updatedPage
            , username = flags.username
            , loggedIn = loggedIn
            , login = loginInitModel
            , suppression = suppressionInitModel
            , dashboard = dashboardInitModel
            }

        cmds =
            Cmd.batch
                [ Cmd.map LoginMsg loginCmd
                , Cmd.map SuppressionMsg suppressionCmd
                , Cmd.map DashboardMsg dashboardCmd
                , cmd
                ]
    in
        ( initModel, cmds )



-- MESSAGES


type Msg
    = NavigateMsg Page
    | ChangePageMsg Page
    | LoginMsg Login.Msg
    | LogoutMsg
    | SuppressionMsg Suppression.Msg
    | DashboardMsg Dashboard.Msg



-- | LogoutMsg
-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NavigateMsg page ->
            ( model, Navigation.newUrl <| pageToHash page )

        ChangePageMsg page ->
            let
                ( updatedPage, cmd ) =
                    onChangePage page model.loggedIn
            in
                ( { model | page = updatedPage }, cmd )

        SuppressionMsg msg ->
            let
                ( suppressionModel, cmd ) =
                    Suppression.update msg model.suppression
            in
                ( { model
                    | suppression = suppressionModel
                  }
                , Cmd.batch
                    [ Cmd.map SuppressionMsg cmd ]
                )

        DashboardMsg msg ->
            let
                ( dashboardModel, cmd ) =
                    Dashboard.update msg model.dashboard
            in
                ( { model
                    | dashboard = dashboardModel
                  }
                , Cmd.batch
                    [ Cmd.map DashboardMsg cmd ]
                )

        LoginMsg msg ->
            let
                ( loginModel, cmd, username ) =
                    Login.update msg model.login

                loggedIn =
                    username /= Nothing
            in
                ( { model
                    | login = loginModel
                    , username = username
                    , loggedIn = loggedIn
                  }
                , Cmd.batch
                    [ Cmd.map LoginMsg cmd ]
                )

        LogoutMsg ->
            ( { model
                | loggedIn = False
                , username = Nothing
              }
            , Cmd.batch
                [ Ports.logoutPort ()
                , Navigation.modifyUrl <| pageToHash LoginPage
                ]
            )


onChangePage : Page -> Bool -> ( Page, Cmd Msg )
onChangePage page loggedIn =
    if authForPage page loggedIn then
        let
            ( updatedPage, cmd ) =
                case page of
                    LoginPage ->
                        if loggedIn then
                            ( DashboardPage, Navigation.modifyUrl <| pageToHash DashboardPage )
                        else
                            ( page, Cmd.none )

                    DashboardPage ->
                        ( SuppressionPage, Navigation.modifyUrl <| pageToHash SuppressionPage )

                    SuppressionPage ->
                        ( SuppressionPage, Ports.suppressionPort () )

                    _ ->
                        ( page, Cmd.none )
        in
            ( updatedPage, cmd )
    else
        ( LoginPage, Navigation.modifyUrl <| pageToHash LoginPage )


authForPage : Page -> Bool -> Bool
authForPage page loggedIn =
    loggedIn || List.member page authWhiteListPages



-- VIEW


view : Model -> Html Msg
view model =
    let
        ( title, page ) =
            case model.page of
                DashboardPage ->
                    ( model.dashboard.title, Html.map DashboardMsg (Dashboard.view model.dashboard) )

                SuppressionPage ->
                    ( model.suppression.title, Html.map SuppressionMsg (Suppression.view model.suppression) )

                LoginPage ->
                    ( model.login.title, Html.map LoginMsg (Login.view model.login) )

                NotFoundPage ->
                    ( "Page Not Found", text "" )
    in
        div []
            [ viewNavbar model
            , viewPage page title
            , footer
                [ class "footer" ]
                [ div
                    [ class "container" ]
                    [ p
                        [ class "text-muted" ]
                        [ text "Place sticky footer content here." ]
                    ]
                ]
            ]


viewNavbar : Model -> Html Msg
viewNavbar model =
    nav
        [ class "navbar navbar-default navbar-fixed-top" ]
        [ div
            [ class "container" ]
            [ div
                [ class "navbar-header" ]
                [ button
                    [ type_ "button"
                    , class "navbar-toggle collapsed"
                    , attribute "data-toggle" "collapse"
                    , attribute "data-target" "#navbar"
                    , attribute "aria-expanded" "false"
                    , attribute "aria-controls" "navbar"
                    ]
                    [ span
                        [ class "sr-only" ]
                        [ text "Toggle navigation" ]
                    , span
                        [ class "icon-bar" ]
                        []
                    , span
                        [ class "icon-bar" ]
                        []
                    , span
                        [ class "icon-bar" ]
                        []
                    ]
                , a
                    [ class "navbar-brand menu-link"
                    , onClick (NavigateMsg DashboardPage)
                    ]
                    [ text "SES Monitor" ]
                ]
            , div
                [ class "collapse navbar-collapse"
                , id "navbar"
                ]
                [ ul
                    [ class "nav navbar-nav" ]
                    [ li
                        []
                        [ a
                            [ onClick (NavigateMsg DashboardPage)
                            , class "menu-link"
                            ]
                            [ text "Dashboard" ]
                        ]
                    , li
                        []
                        [ a
                            [ onClick (NavigateMsg SuppressionPage)
                            , class "menu-link"
                            ]
                            [ text "Suppression List" ]
                        ]
                    ]
                , ul
                    [ class "nav navbar-nav navbar-right" ]
                    [ li
                        []
                        [ viewNavbarAuth model ]
                    ]
                , p
                    [ class "navbar-text pull-right" ]
                    [ text (Maybe.withDefault "" model.username) ]
                ]
            ]
        ]


viewPage : Html Msg -> String -> Html Msg
viewPage page title =
    div
        [ class "container page-container" ]
        [ div
            [ class "page-header" ]
            [ h1
                []
                [ text title ]
            ]
        , page
        ]


viewNavbarAuth : Model -> Html Msg
viewNavbarAuth model =
    if model.loggedIn then
        a
            [ onClick LogoutMsg
            , class "menu-link"
            ]
            [ text "Log Out" ]
    else
        a
            [ onClick (NavigateMsg LoginPage)
            , class "menu-link"
            ]
            [ text "Log In" ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        loginSub =
            Login.subscriptions model.login

        suppressionSub =
            Suppression.subscriptions model.suppression
    in
        Sub.batch
            [ Sub.map LoginMsg loginSub
            , Sub.map SuppressionMsg suppressionSub
            ]



-- NAVIGATION


pageToHash : Page -> String
pageToHash page =
    case page of
        DashboardPage ->
            "#/"

        SuppressionPage ->
            "#/suppression"

        LoginPage ->
            "#/login"

        NotFoundPage ->
            "#/notfound"


hashToPage : String -> Page
hashToPage hash =
    case hash of
        "" ->
            DashboardPage

        "#/" ->
            DashboardPage

        "#/suppression" ->
            SuppressionPage

        "#/login" ->
            LoginPage

        _ ->
            NotFoundPage


locationToMsg : Location -> Msg
locationToMsg location =
    location.hash
        |> hashToPage
        |> ChangePageMsg



-- MAIN


main : Program Flags Model Msg
main =
    Navigation.programWithFlags locationToMsg
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
