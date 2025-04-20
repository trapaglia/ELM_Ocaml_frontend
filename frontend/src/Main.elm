module Main exposing (main)

import Browser
import Html exposing (Html, div, text, ul, li)


-- MODELO

type alias Model =
    { messages : List String }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { messages = [ "Hola, mi amor", "¿Cómo estás?", "Esto es Elm..." ] }, Cmd.none )


-- MENSAJES

type Msg
    = NoOp


-- UPDATE

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )


-- VISTA

view : Model -> Html Msg
view model =
    div []
        [ Html.h2 [] [ text "Mensajes desde Elm:" ]
        , ul []
            (List.map (\msg -> li [] [ text msg ]) model.messages)
        ]


-- PROGRAMA

main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }
