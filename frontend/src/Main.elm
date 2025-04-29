module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode



-- TIPO DE DATOS


type alias Ticket =
    { ticketName : String
    , estado : String
    , compra1 : Float
    , compra2 : Float
    , venta1 : Float
    , venta2 : Float
    , takeProfit : Float
    , stopLoss : Float
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


-- CODIFICADOR
encodeTicket : Ticket -> Encode.Value
encodeTicket ticket =
    Encode.object
        [ ( "ticket_name", Encode.string ticket.ticketName )
        , ( "estado", Encode.string ticket.estado )
        , ( "compra1", Encode.float ticket.compra1 )
        , ( "compra2", Encode.float ticket.compra2 )
        , ( "venta1", Encode.float ticket.venta1 )
        , ( "venta2", Encode.float ticket.venta2 )
        , ( "take_profit", Encode.float ticket.takeProfit )
        , ( "stop_loss", Encode.float ticket.stopLoss )
        , ( "punta_compra", Encode.float ticket.puntaCompra )
        , ( "punta_venta", Encode.float ticket.puntaVenta )
        , ( "last_update", Encode.string ticket.lastUpdate )
        ]


-- MODELO


type alias Model =
    { tickets : List Ticket
    , error : Maybe String
    , success : Maybe String
    , editingTicket : Maybe Ticket
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { tickets = []
      , error = Nothing
      , success = Nothing 
      , editingTicket = Nothing
      }
    , getTickets
    )



-- MENSAJES


type Msg
    = TicketsFetched (Result Http.Error (List Ticket))
    | StartEditing Ticket
    | CancelEditing
    | UpdateField String String
    | UpdateFloatField String String
    | SaveTicket
    | SaveTicketResult (Result Http.Error String)



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TicketsFetched (Ok tickets) ->
            ( { model | tickets = tickets, error = Nothing }, Cmd.none )

        TicketsFetched (Err err) ->
            ( { model | error = Just (debugErr err) }, Cmd.none )

        StartEditing ticket ->
            ( { model | editingTicket = Just ticket, error = Nothing, success = Nothing }, Cmd.none )

        CancelEditing ->
            ( { model | editingTicket = Nothing }, Cmd.none )

        UpdateField field value ->
            case model.editingTicket of
                Just ticket ->
                    let
                        updatedTicket =
                            case field of
                                "ticketName" ->
                                    { ticket | ticketName = value }

                                "estado" ->
                                    { ticket | estado = value }

                                "lastUpdate" ->
                                    { ticket | lastUpdate = value }

                                _ ->
                                    ticket
                    in
                    ( { model | editingTicket = Just updatedTicket }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        UpdateFloatField field value ->
            case model.editingTicket of
                Just ticket ->
                    let
                        floatValue =
                            String.toFloat value |> Maybe.withDefault 0.0

                        updatedTicket =
                            case field of
                                "compra1" ->
                                    { ticket | compra1 = floatValue }

                                "compra2" ->
                                    { ticket | compra2 = floatValue }

                                "venta1" ->
                                    { ticket | venta1 = floatValue }

                                "venta2" ->
                                    { ticket | venta2 = floatValue }

                                "takeProfit" ->
                                    { ticket | takeProfit = floatValue }

                                "stopLoss" ->
                                    { ticket | stopLoss = floatValue }

                                "puntaCompra" ->
                                    { ticket | puntaCompra = floatValue }

                                "puntaVenta" ->
                                    { ticket | puntaVenta = floatValue }

                                _ ->
                                    ticket
                    in
                    ( { model | editingTicket = Just updatedTicket }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        SaveTicket ->
            case model.editingTicket of
                Just ticket ->
                    ( model, updateTicket ticket )

                Nothing ->
                    ( model, Cmd.none )

        SaveTicketResult (Ok _) ->
            ( { model | editingTicket = Nothing, success = Just "Ticket actualizado correctamente" }
            , getTickets
            )

        SaveTicketResult (Err err) ->
            ( { model | error = Just ("Error al guardar: " ++ debugErr err) }, Cmd.none )



-- HTTP


getTickets : Cmd Msg
getTickets =
    Http.get
        { url = "/api/tickets"
        , expect = Http.expectJson TicketsFetched (Decode.list ticketDecoder)
        }


updateTicket : Ticket -> Cmd Msg
updateTicket ticket =
    Http.request
        { method = "PUT"
        , headers = []
        , url = "/api/tickets"
        , body = Http.jsonBody (encodeTicket ticket)
        , expect = Http.expectString SaveTicketResult
        , timeout = Nothing
        , tracker = Nothing
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
        , viewMessages model
        , viewContent model
        ]


viewMessages : Model -> Html Msg
viewMessages model =
    div []
        [ case model.error of
            Just errMsg ->
                div [ style "color" "red", style "margin-bottom" "1rem" ] 
                    [ text ("Error: " ++ errMsg) ]

            Nothing ->
                text ""
        , case model.success of
            Just successMsg ->
                div [ style "color" "green", style "margin-bottom" "1rem" ] 
                    [ text successMsg ]

            Nothing ->
                text ""
        ]


viewContent : Model -> Html Msg
viewContent model =
    case model.editingTicket of
        Just ticket ->
            viewEditForm ticket

        Nothing ->
            viewTicketsTable model


viewTicketsTable : Model -> Html Msg
viewTicketsTable model =
    table [ style "border-collapse" "collapse", style "width" "100%" ]
        ([ thead []
            [ tr [ style "background-color" "#f2f2f2" ]
                [ th [ style "padding" "8px", style "text-align" "left", style "border" "1px solid #ddd" ] [ text "Ticket" ]
                , th [ style "padding" "8px", style "text-align" "left", style "border" "1px solid #ddd" ] [ text "Estado" ]
                , th [ style "padding" "8px", style "text-align" "left", style "border" "1px solid #ddd" ] [ text "Compra1" ]
                , th [ style "padding" "8px", style "text-align" "left", style "border" "1px solid #ddd" ] [ text "Venta1" ]
                , th [ style "padding" "8px", style "text-align" "left", style "border" "1px solid #ddd" ] [ text "Last Update" ]
                , th [ style "padding" "8px", style "text-align" "left", style "border" "1px solid #ddd" ] [ text "Acciones" ]
                ]
            ]
         ]
            ++ List.map viewRow model.tickets
        )


viewRow : Ticket -> Html Msg
viewRow t =
    tr [ style "border" "1px solid #ddd" ]
        [ td [ style "padding" "8px", style "border" "1px solid #ddd" ] [ text t.ticketName ]
        , td [ style "padding" "8px", style "border" "1px solid #ddd" ] [ text t.estado ]
        , td [ style "padding" "8px", style "border" "1px solid #ddd" ] [ text (String.fromFloat t.compra1) ]
        , td [ style "padding" "8px", style "border" "1px solid #ddd" ] [ text (String.fromFloat t.venta1) ]
        , td [ style "padding" "8px", style "border" "1px solid #ddd" ] [ text t.lastUpdate ]
        , td [ style "padding" "8px", style "border" "1px solid #ddd" ] 
            [ button 
                [ onClick (StartEditing t)
                , style "background-color" "#4CAF50"
                , style "color" "white"
                , style "padding" "6px 10px"
                , style "border" "none"
                , style "cursor" "pointer"
                ] 
                [ text "Editar" ] 
            ]
        ]


viewEditForm : Ticket -> Html Msg
viewEditForm ticket =
    div [ style "border" "1px solid #ddd", style "padding" "20px", style "border-radius" "5px" ]
        [ h3 [] [ text ("Editar Ticket: " ++ ticket.ticketName) ]
        , div [ style "margin-bottom" "15px" ]
            [ label [ style "display" "block", style "margin-bottom" "5px" ] [ text "Estado:" ]
            , input
                [ type_ "text"
                , value ticket.estado
                , onInput (UpdateField "estado")
                , style "width" "100%"
                , style "padding" "8px"
                , style "box-sizing" "border-box"
                ]
                []
            ]
        , div [ style "display" "flex", style "gap" "15px", style "margin-bottom" "15px" ]
            [ div [ style "flex" "1" ]
                [ label [ style "display" "block", style "margin-bottom" "5px" ] [ text "Compra 1:" ]
                , input
                    [ type_ "number"
                    , value (String.fromFloat ticket.compra1)
                    , onInput (UpdateFloatField "compra1")
                    , style "width" "100%"
                    , style "padding" "8px"
                    , style "box-sizing" "border-box"
                    ]
                    []
                ]
            , div [ style "flex" "1" ]
                [ label [ style "display" "block", style "margin-bottom" "5px" ] [ text "Compra 2:" ]
                , input
                    [ type_ "number"
                    , value (String.fromFloat ticket.compra2)
                    , onInput (UpdateFloatField "compra2")
                    , style "width" "100%"
                    , style "padding" "8px"
                    , style "box-sizing" "border-box"
                    ]
                    []
                ]
            ]
        , div [ style "display" "flex", style "gap" "15px", style "margin-bottom" "15px" ]
            [ div [ style "flex" "1" ]
                [ label [ style "display" "block", style "margin-bottom" "5px" ] [ text "Venta 1:" ]
                , input
                    [ type_ "number"
                    , value (String.fromFloat ticket.venta1)
                    , onInput (UpdateFloatField "venta1")
                    , style "width" "100%"
                    , style "padding" "8px"
                    , style "box-sizing" "border-box"
                    ]
                    []
                ]
            , div [ style "flex" "1" ]
                [ label [ style "display" "block", style "margin-bottom" "5px" ] [ text "Venta 2:" ]
                , input
                    [ type_ "number"
                    , value (String.fromFloat ticket.venta2)
                    , onInput (UpdateFloatField "venta2")
                    , style "width" "100%"
                    , style "padding" "8px"
                    , style "box-sizing" "border-box"
                    ]
                    []
                ]
            ]
        , div [ style "display" "flex", style "gap" "15px", style "margin-bottom" "15px" ]
            [ div [ style "flex" "1" ]
                [ label [ style "display" "block", style "margin-bottom" "5px" ] [ text "Take Profit:" ]
                , input
                    [ type_ "number"
                    , value (String.fromFloat ticket.takeProfit)
                    , onInput (UpdateFloatField "takeProfit")
                    , style "width" "100%"
                    , style "padding" "8px"
                    , style "box-sizing" "border-box"
                    ]
                    []
                ]
            , div [ style "flex" "1" ]
                [ label [ style "display" "block", style "margin-bottom" "5px" ] [ text "Stop Loss:" ]
                , input
                    [ type_ "number"
                    , value (String.fromFloat ticket.stopLoss)
                    , onInput (UpdateFloatField "stopLoss")
                    , style "width" "100%"
                    , style "padding" "8px"
                    , style "box-sizing" "border-box"
                    ]
                    []
                ]
            ]
        , div [ style "display" "flex", style "gap" "15px", style "margin-bottom" "15px" ]
            [ div [ style "flex" "1" ]
                [ label [ style "display" "block", style "margin-bottom" "5px" ] [ text "Punta Compra:" ]
                , input
                    [ type_ "number"
                    , value (String.fromFloat ticket.puntaCompra)
                    , onInput (UpdateFloatField "puntaCompra")
                    , style "width" "100%"
                    , style "padding" "8px"
                    , style "box-sizing" "border-box"
                    ]
                    []
                ]
            , div [ style "flex" "1" ]
                [ label [ style "display" "block", style "margin-bottom" "5px" ] [ text "Punta Venta:" ]
                , input
                    [ type_ "number"
                    , value (String.fromFloat ticket.puntaVenta)
                    , onInput (UpdateFloatField "puntaVenta")
                    , style "width" "100%"
                    , style "padding" "8px"
                    , style "box-sizing" "border-box"
                    ]
                    []
                ]
            ]
        , div [ style "display" "flex", style "gap" "10px", style "margin-top" "20px" ]
            [ button
                [ onClick SaveTicket
                , style "background-color" "#4CAF50"
                , style "color" "white"
                , style "padding" "10px 15px"
                , style "border" "none"
                , style "border-radius" "4px"
                , style "cursor" "pointer"
                ]
                [ text "Guardar" ]
            , button
                [ onClick CancelEditing
                , style "background-color" "#f44336"
                , style "color" "white"
                , style "padding" "10px 15px"
                , style "border" "none"
                , style "border-radius" "4px"
                , style "cursor" "pointer"
                ]
                [ text "Cancelar" ]
            ]
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
