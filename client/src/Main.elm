module Main exposing (main)

import Browser
import Html exposing (Html, a, button, div, h1, input, p, text)
import Html.Attributes exposing (href, placeholder, type_, value)
import Html.Events exposing (onClick, onInput)
import Search


type alias Model =
    { inputBuffer : String
    , searchedPages : Search.Response
    , errorMessage : String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { inputBuffer = ""
      , searchedPages = []
      , errorMessage = ""
      }
    , Cmd.none
    )


type Msg
    = UpdateInputBuffer String
    | GotSearchMsg Search.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateInputBuffer content ->
            ( { model | inputBuffer = content }, Cmd.none )

        GotSearchMsg (Search.SendRequest request) ->
            let
                sendCmd =
                    Search.sendRequest request
            in
            ( model, Cmd.map GotSearchMsg sendCmd )

        GotSearchMsg (Search.ReceiveResponse res) ->
            handleResponse res model


handleResponse : Result String Search.Response -> Model -> ( Model, Cmd Msg )
handleResponse res model =
    case res of
        Err err ->
            ( { model | searchedPages = [], errorMessage = err }, Cmd.none )

        Ok response ->
            ( { model | searchedPages = response, errorMessage = "" }, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "EduSeek" ]
        , input
            [ type_ "text"
            , placeholder "Type to topic you want to study..."
            , onInput UpdateInputBuffer
            , value model.inputBuffer
            ]
            []
        , button
            [ { input = model.inputBuffer }
                |> Search.SendRequest
                |> GotSearchMsg
                |> onClick
            ]
            [ text "Search" ]
        , p [] [ text model.errorMessage ]
        , model.searchedPages
            |> List.map renderSearchedPages
            |> div []
        ]


renderSearchedPages : Search.ResponseItem -> Html Msg
renderSearchedPages page =
    div []
        [ a [ href page.url ] [ text page.title ]
        , p [] [ text page.description ]
        ]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }
