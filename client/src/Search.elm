module Search exposing
    ( Msg(..)
    , Request
    , Response
    , ResponseItem
    , responseDecoder
    , responseItemDecoder
    , sendRequest
    )

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)


apiUrl : String
apiUrl =
    "http://localhost:8080"


type alias Request =
    { input : String
    }


type alias ResponseItem =
    { id : Int
    , createdAt : String
    , updatedAt : String
    , url : String
    , title : String
    , description : String
    , content : String
    , rawHtml : String
    , hash : String
    , lastIndexed : String
    , snippet : String
    , rank : Float
    }


type alias Response =
    List ResponseItem


type Msg
    = SendRequest Request
    | ReceiveResponse (Result String Response)


responseItemDecoder : Decoder ResponseItem
responseItemDecoder =
    Decode.succeed ResponseItem
        |> required "ID" Decode.int
        |> required "CreatedAt" Decode.string
        |> required "UpdatedAt" Decode.string
        |> required "URL" Decode.string
        |> required "Title" Decode.string
        |> required "Description" Decode.string
        |> required "Content" Decode.string
        |> required "RawHTML" Decode.string
        |> required "Hash" Decode.string
        |> required "LastIndexed" Decode.string
        |> required "Snippet" Decode.string
        |> required "Rank" Decode.float


responseDecoder : Decoder Response
responseDecoder =
    Decode.list responseItemDecoder


sendRequest : Request -> Cmd Msg
sendRequest request =
    let
        url =
            apiUrl ++ "/api/search?q=" ++ request.input
    in
    Http.get
        { url = url
        , expect =
            Http.expectJson
                (ReceiveResponse << Result.mapError httpErrorToString)
                responseDecoder
        }


httpErrorToString : Http.Error -> String
httpErrorToString err =
    case err of
        Http.BadUrl url ->
            "Bad URL: " ++ url

        Http.Timeout ->
            "Timed out."

        Http.NetworkError ->
            "Network error. Please check your internet connection."

        Http.BadStatus code ->
            "The server responded with an error status: " ++ String.fromInt code

        Http.BadBody msg ->
            "Failed to process to response body: " ++ msg
