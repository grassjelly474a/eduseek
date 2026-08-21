module Search exposing
    ( Msg(..)
    , Request
    , Response
    , ResponseItem
    , Webpage
    , Website
    , createWebpage
    , createWebsite
    , deleteWebsite
    , getWebpages
    , getWebsites
    , responseDecoder
    , responseItemDecoder
    , sendRequest
    , webpageDecoder
    , websiteDecoder
    )

import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode


apiUrl : String
apiUrl =
    "http://localhost:1234"


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


type alias Website =
    { id : Int
    , createdAt : String
    , updatedAt : String
    , domain : String
    , name : String
    }


type alias Webpage =
    { id : Int
    , createdAt : String
    , updatedAt : String
    , websiteId : Int
    , url : String
    , title : String
    , description : String
    , content : String
    , rawHtml : String
    , hash : String
    , lastIndexed : String
    }


type Msg
    = SendRequest Request
    | ReceiveResponse (Result String Response)
    | GetWebsites
    | ReceiveWebsites (Result String (List Website))
    | CreateWebsite { domain : String, name : String }
    | ReceiveCreateWebsite (Result String Website)
    | DeleteWebsite Int
    | ReceiveDeleteWebsite Int (Result String String)
    | GetWebpages Int
    | ReceiveWebpages Int (Result String (List Webpage))
    | CreateWebpage { websiteId : Int, url : String, title : String, description : String, content : String, rawHtml : String }
    | ReceiveCreateWebpage (Result String Webpage)


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


websiteDecoder : Decoder Website
websiteDecoder =
    Decode.succeed Website
        |> required "ID" Decode.int
        |> required "CreatedAt" Decode.string
        |> required "UpdatedAt" Decode.string
        |> required "Domain" Decode.string
        |> required "Name" Decode.string


webpageDecoder : Decoder Webpage
webpageDecoder =
    Decode.succeed Webpage
        |> required "ID" Decode.int
        |> required "CreatedAt" Decode.string
        |> required "UpdatedAt" Decode.string
        |> required "WebsiteID" Decode.int
        |> required "URL" Decode.string
        |> required "Title" Decode.string
        |> required "Description" Decode.string
        |> required "Content" Decode.string
        |> required "RawHTML" Decode.string
        |> required "Hash" Decode.string
        |> required "LastIndexed" Decode.string


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


getWebsites : Cmd Msg
getWebsites =
    Http.get
        { url = apiUrl ++ "/api/websites"
        , expect =
            Http.expectJson
                (ReceiveWebsites << Result.mapError httpErrorToString)
                (Decode.list websiteDecoder)
        }


encodeCreateWebsite : { domain : String, name : String } -> Encode.Value
encodeCreateWebsite req =
    Encode.object
        [ ( "domain", Encode.string req.domain )
        , ( "name", Encode.string req.name )
        ]


createWebsite : { domain : String, name : String } -> Cmd Msg
createWebsite req =
    Http.post
        { url = apiUrl ++ "/api/websites"
        , body = Http.jsonBody (encodeCreateWebsite req)
        , expect =
            Http.expectJson
                (ReceiveCreateWebsite << Result.mapError httpErrorToString)
                websiteDecoder
        }


deleteWebsite : Int -> Cmd Msg
deleteWebsite id =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = apiUrl ++ "/api/websites/" ++ String.fromInt id
        , body = Http.emptyBody
        , expect =
            Http.expectJson
                (ReceiveDeleteWebsite id << Result.mapError httpErrorToString)
                (Decode.field "message" Decode.string)
        , timeout = Nothing
        , tracker = Nothing
        }


getWebpages : Int -> Cmd Msg
getWebpages id =
    Http.get
        { url = apiUrl ++ "/api/websites/" ++ String.fromInt id ++ "/webpages"
        , expect =
            Http.expectJson
                (ReceiveWebpages id << Result.mapError httpErrorToString)
                (Decode.list webpageDecoder)
        }


encodeCreateWebpage : { websiteId : Int, url : String, title : String, description : String, content : String, rawHtml : String } -> Encode.Value
encodeCreateWebpage req =
    Encode.object
        [ ( "website_id", Encode.int req.websiteId )
        , ( "url", Encode.string req.url )
        , ( "title", Encode.string req.title )
        , ( "description", Encode.string req.description )
        , ( "content", Encode.string req.content )
        , ( "raw_html", Encode.string req.rawHtml )
        ]


createWebpage : { websiteId : Int, url : String, title : String, description : String, content : String, rawHtml : String } -> Cmd Msg
createWebpage req =
    Http.post
        { url = apiUrl ++ "/api/webpages"
        , body = Http.jsonBody (encodeCreateWebpage req)
        , expect =
            Http.expectJson
                (ReceiveCreateWebpage << Result.mapError httpErrorToString)
                webpageDecoder
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
            "Failed to process the response body: " ++ msg
