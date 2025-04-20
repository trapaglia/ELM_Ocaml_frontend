module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Decode exposing (Decoder)



-- TIPO DE DATOS


type alias Ticket =
    { ticketName : String
    , estado : String
    , compra1 : Float
    , compra2 : Float
    , venta1 : Float
    , venta2 : Float
    , takeProfit : Float
    , stoLoss : Float
    , puntaCompra : Float
    , puntaVenta : Float
    , lastUpdate : String
    }



-- DECODIFICADOR


ticketDecoder : Decoder Ticket
ticketDecoder =
    Decode.map8
        (\ticketName estado compra1 compra2 venta1 venta2 takeProfit stopLoss ->
            \puntaCompra puntaVenta lastUpdate ->
                Ticket
                    ticketName
                    estado
                    compra1
                    compra2
                    venta1
                    venta2
                    takeProfit
                    stopLoss
                    puntaCompra
                    puntaVenta
                    lastUpdate
        )
        (Decode.field "ticket_name" Decode.string)
        (Decode.field "estado" Decode.string)
        (Decode.field "compra1" Decode.float)
        (Decode.field "compra2" Decode.float)
        (Decode.field "venta1" Decode.float)
        (Decode.field "venta2" Decode.float)
        (Decode.field "take_profit" Decode.float)
        (Decode.field "stop_loss" Decode.float)
        |> Decode.andThen
            (\buildPartial ->
                Decode.map3 buildPartial
                    (Decode.field "punta_compra" Decode.float)
                    (Decode.field "punta_venta" Decode.float)
                    (Decode.field "last_update" Decode.string)
            )



-- MODELO


type alias Model =
    { tickets : List Ticket
    , error : Maybe String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { tickets = [], error = Nothing }
    , getTickets
    )



-- MENSAJES


type Msg
    = TicketsFetched (Result Http.Error (List Ticket))



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TicketsFetched (Ok tickets) ->
            ( { model | tickets = tickets }, Cmd.none )

        TicketsFetched (Err err) ->
            ( { model | error = Just (debugErr err) }, Cmd.none )



-- HTTP


getTickets : Cmd Msg
getTickets =
    Http.get
        { url = "/api/tickets"

        -- { url = "http://localhost:8081/api/tickets"
        , expect = Http.expectJson TicketsFetched (Decode.list ticketDecoder)
        }


debugErr : Http.Error -> String
debugErr err =
    case err of
        Http.BadUrl url ->
            "Bad URL: " ++ url

        Http.Timeout ->
            "Request timed out"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus status ->
            "Bad status: " ++ String.fromInt status

        Http.BadBody body ->
            "Bad body: " ++ body



-- VISTA


view : Model -> Html Msg
view model =
    div [ style "padding" "2rem", style "font-family" "sans-serif" ]
        [ h2 [] [ text "📋 Tickets actuales" ]
        , case model.error of
            Just errMsg ->
                div [ style "color" "red" ] [ text ("Error: " ++ errMsg) ]

            Nothing ->
                table [ style "border" "1px solid black" ]
                    ([ thead []
                        [ tr []
                            [ th [] [ text "Ticket" ]
                            , th [] [ text "Estado" ]
                            , th [] [ text "Compra1" ]
                            , th [] [ text "Venta1" ]
                            , th [] [ text "Last Update" ]
                            ]
                        ]
                     ]
                        ++ List.map viewRow model.tickets
                    )
        ]


viewRow : Ticket -> Html msg
viewRow t =
    tr []
        [ td [] [ text t.ticketName ]
        , td [] [ text t.estado ]
        , td [] [ text (String.fromFloat t.compra1) ]
        , td [] [ text (String.fromFloat t.venta1) ]
        , td [] [ text t.lastUpdate ]
        ]



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }
