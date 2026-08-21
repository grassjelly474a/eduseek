module Main exposing (main)

import Browser
import Html exposing (Html, a, button, div, h1, h2, h3, h4, hr, input, label, p, span, table, tbody, td, text, textarea, th, thead, tr)
import Html.Attributes exposing (class, cols, disabled, href, placeholder, rows, target, type_, value)
import Html.Events exposing (onClick, onInput)
import Search
import Styles


type Tab
    = SearchTab
    | AdminTab


type SearchStatus
    = SearchIdle
    | SearchLoading
    | SearchSuccess Search.Response
    | SearchFailure String


type WebsitesStatus
    = WebsitesNotLoaded
    | WebsitesLoading
    | WebsitesSuccess (List Search.Website)
    | WebsitesFailure String


type WebpagesStatus
    = WebpagesNotLoaded
    | WebpagesLoading
    | WebpagesSuccess (List Search.Webpage)
    | WebpagesFailure String


type FormStatus
    = FormIdle
    | FormSubmitting
    | FormSuccess String
    | FormFailure String


type alias Model =
    { activeTab : Tab
    , inputBuffer : String
    , searchStatus : SearchStatus
    -- Admin Tab States
    , websitesStatus : WebsitesStatus
    , selectedWebsite : Maybe Search.Website
    , webpagesStatus : WebpagesStatus
    , confirmingDeleteWebsiteId : Maybe Int
    -- New Website Form States
    , newWebsiteName : String
    , newWebsiteDomain : String
    , newWebsiteStatus : FormStatus
    -- New Webpage Form States
    , newWebpageUrl : String
    , newWebpageTitle : String
    , newWebpageDescription : String
    , newWebpageContent : String
    , newWebpageRawHtml : String
    , newWebpageStatus : FormStatus
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { activeTab = SearchTab
      , inputBuffer = ""
      , searchStatus = SearchIdle
      , websitesStatus = WebsitesNotLoaded
      , selectedWebsite = Nothing
      , webpagesStatus = WebpagesNotLoaded
      , confirmingDeleteWebsiteId = Nothing
      , newWebsiteName = ""
      , newWebsiteDomain = ""
      , newWebsiteStatus = FormIdle
      , newWebpageUrl = ""
      , newWebpageTitle = ""
      , newWebpageDescription = ""
      , newWebpageContent = ""
      , newWebpageRawHtml = ""
      , newWebpageStatus = FormIdle
      }
    , Cmd.none
    )


type Msg
    = SetTab Tab
    | UpdateInputBuffer String
    | TriggerSearch
    | ClearSearch
    -- Admin Msg
    | FetchWebsites
    | SelectWebsite Search.Website
    | DeselectWebsite
    | RequestDeleteWebsite Int
    | CancelDeleteWebsite
    | ConfirmDeleteWebsite Int
    -- Form Inputs - Website
    | UpdateNewWebsiteName String
    | UpdateNewWebsiteDomain String
    | SubmitNewWebsite
    -- Form Inputs - Webpage
    | UpdateNewWebpageUrl String
    | UpdateNewWebpageTitle String
    | UpdateNewWebpageDescription String
    | UpdateNewWebpageContent String
    | UpdateNewWebpageRawHtml String
    | SubmitNewWebpage Int
    -- Submodule Msg
    | GotSearchMsg Search.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetTab tab ->
            let
                cmd =
                    if tab == AdminTab then
                        Cmd.map GotSearchMsg Search.getWebsites

                    else
                        Cmd.none

                newWebsitesStatus =
                    if tab == AdminTab then
                        WebsitesLoading

                    else
                        model.websitesStatus
            in
            ( { model
                | activeTab = tab
                , websitesStatus = newWebsitesStatus
                , confirmingDeleteWebsiteId = Nothing
                , selectedWebsite = Nothing
                , webpagesStatus = WebpagesNotLoaded
              }
            , cmd
            )

        UpdateInputBuffer content ->
            ( { model | inputBuffer = content }, Cmd.none )

        TriggerSearch ->
            if String.isEmpty (String.trim model.inputBuffer) then
                ( model, Cmd.none )

            else
                let
                    searchCmd =
                        Search.sendRequest { input = model.inputBuffer }
                in
                ( { model | searchStatus = SearchLoading }, Cmd.map GotSearchMsg searchCmd )

        ClearSearch ->
            ( { model | inputBuffer = "", searchStatus = SearchIdle }, Cmd.none )

        FetchWebsites ->
            ( { model | websitesStatus = WebsitesLoading, confirmingDeleteWebsiteId = Nothing }
            , Cmd.map GotSearchMsg Search.getWebsites
            )

        SelectWebsite site ->
            ( { model
                | selectedWebsite = Just site
                , webpagesStatus = WebpagesLoading
                , newWebpageUrl = ""
                , newWebpageTitle = ""
                , newWebpageDescription = ""
                , newWebpageContent = ""
                , newWebpageRawHtml = ""
                , newWebpageStatus = FormIdle
              }
            , Cmd.map GotSearchMsg (Search.getWebpages site.id)
            )

        DeselectWebsite ->
            ( { model | selectedWebsite = Nothing, webpagesStatus = WebpagesNotLoaded }, Cmd.none )

        RequestDeleteWebsite id ->
            ( { model | confirmingDeleteWebsiteId = Just id }, Cmd.none )

        CancelDeleteWebsite ->
            ( { model | confirmingDeleteWebsiteId = Nothing }, Cmd.none )

        ConfirmDeleteWebsite id ->
            ( { model | confirmingDeleteWebsiteId = Nothing }
            , Cmd.map GotSearchMsg (Search.deleteWebsite id)
            )

        UpdateNewWebsiteName name ->
            ( { model | newWebsiteName = name }, Cmd.none )

        UpdateNewWebsiteDomain domain ->
            ( { model | newWebsiteDomain = domain }, Cmd.none )

        SubmitNewWebsite ->
            if String.isEmpty (String.trim model.newWebsiteName) || String.isEmpty (String.trim model.newWebsiteDomain) then
                ( { model | newWebsiteStatus = FormFailure "Name and Domain are required fields" }, Cmd.none )

            else
                let
                    cmd =
                        Search.createWebsite { name = model.newWebsiteName, domain = model.newWebsiteDomain }
                in
                ( { model | newWebsiteStatus = FormSubmitting }, Cmd.map GotSearchMsg cmd )

        UpdateNewWebpageUrl url ->
            ( { model | newWebpageUrl = url }, Cmd.none )

        UpdateNewWebpageTitle title ->
            ( { model | newWebpageTitle = title }, Cmd.none )

        UpdateNewWebpageDescription desc ->
            ( { model | newWebpageDescription = desc }, Cmd.none )

        UpdateNewWebpageContent content ->
            ( { model | newWebpageContent = content }, Cmd.none )

        UpdateNewWebpageRawHtml rawHtml ->
            ( { model | newWebpageRawHtml = rawHtml }, Cmd.none )

        SubmitNewWebpage websiteId ->
            if String.isEmpty (String.trim model.newWebpageUrl) || String.isEmpty (String.trim model.newWebpageContent) then
                ( { model | newWebpageStatus = FormFailure "URL and Content are required fields" }, Cmd.none )

            else
                let
                    cmd =
                        Search.createWebpage
                            { websiteId = websiteId
                            , url = model.newWebpageUrl
                            , title = model.newWebpageTitle
                            , description = model.newWebpageDescription
                            , content = model.newWebpageContent
                            , rawHtml = model.newWebpageRawHtml
                            }
                in
                ( { model | newWebpageStatus = FormSubmitting }, Cmd.map GotSearchMsg cmd )

        GotSearchMsg searchMsg ->
            handleSearchMsg searchMsg model


handleSearchMsg : Search.Msg -> Model -> ( Model, Cmd Msg )
handleSearchMsg msg model =
    case msg of
        Search.SendRequest _ ->
            ( model, Cmd.none )

        Search.ReceiveResponse result ->
            case result of
                Err err ->
                    ( { model | searchStatus = SearchFailure err }, Cmd.none )

                Ok response ->
                    ( { model | searchStatus = SearchSuccess response }, Cmd.none )

        Search.GetWebsites ->
            ( model, Cmd.none )

        Search.ReceiveWebsites result ->
            case result of
                Err err ->
                    ( { model | websitesStatus = WebsitesFailure err }, Cmd.none )

                Ok sites ->
                    ( { model | websitesStatus = WebsitesSuccess sites }, Cmd.none )

        Search.CreateWebsite _ ->
            ( model, Cmd.none )

        Search.ReceiveCreateWebsite result ->
            case result of
                Err err ->
                    ( { model | newWebsiteStatus = FormFailure err }, Cmd.none )

                Ok site ->
                    ( { model
                        | newWebsiteName = ""
                        , newWebsiteDomain = ""
                        , newWebsiteStatus = FormSuccess ("Successfully registered website: " ++ site.name)
                      }
                    , Cmd.map GotSearchMsg Search.getWebsites
                    )

        Search.DeleteWebsite _ ->
            ( model, Cmd.none )

        Search.ReceiveDeleteWebsite deletedId result ->
            case result of
                Err err ->
                    ( { model | websitesStatus = WebsitesFailure ("Delete failed: " ++ err) }, Cmd.none )

                Ok _ ->
                    let
                        newSelected =
                            case model.selectedWebsite of
                                Just site ->
                                    if site.id == deletedId then
                                        Nothing

                                    else
                                        model.selectedWebsite

                                Nothing ->
                                    Nothing

                        newWebpagesStatus =
                            if newSelected == Nothing then
                                WebpagesNotLoaded

                            else
                                model.webpagesStatus
                    in
                    ( { model | selectedWebsite = newSelected, webpagesStatus = newWebpagesStatus }
                    , Cmd.map GotSearchMsg Search.getWebsites
                    )

        Search.GetWebpages _ ->
            ( model, Cmd.none )

        Search.ReceiveWebpages _ result ->
            case result of
                Err err ->
                    ( { model | webpagesStatus = WebpagesFailure err }, Cmd.none )

                Ok pages ->
                    ( { model | webpagesStatus = WebpagesSuccess pages }, Cmd.none )

        Search.CreateWebpage _ ->
            ( model, Cmd.none )

        Search.ReceiveCreateWebpage result ->
            case result of
                Err err ->
                    ( { model | newWebpageStatus = FormFailure err }, Cmd.none )

                Ok page ->
                    ( { model
                        | newWebpageUrl = ""
                        , newWebpageTitle = ""
                        , newWebpageDescription = ""
                        , newWebpageContent = ""
                        , newWebpageRawHtml = ""
                        , newWebpageStatus = FormSuccess ("Successfully indexed page: " ++ page.url)
                      }
                    , Cmd.map GotSearchMsg (Search.getWebpages page.websiteId)
                    )


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ Styles.css
        , h1 [] [ text "EduSeek" ]
        , renderTabs model
        , case model.activeTab of
            SearchTab ->
                renderSearchTab model

            AdminTab ->
                renderAdminTab model
        ]


renderTabs : Model -> Html Msg
renderTabs model =
    div [ class "tabs" ]
        [ button
            [ onClick (SetTab SearchTab)
            , disabled (model.activeTab == SearchTab)
            , class "tab-btn"
            ]
            [ text "Search Pages" ]
        , button
            [ onClick (SetTab AdminTab)
            , disabled (model.activeTab == AdminTab)
            , class "tab-btn"
            ]
            [ text "Manage Sites" ]
        ]


renderSearchTab : Model -> Html Msg
renderSearchTab model =
    div [ class "search-container" ]
        [ h2 [] [ text "Search Educational Pages" ]
        , div [ class "search-bar" ]
            [ input
                [ type_ "text"
                , placeholder "Type topic to study (e.g. physics, algebra, calculus)..."
                , onInput UpdateInputBuffer
                , value model.inputBuffer
                , class "search-input"
                ]
                []
            , button
                [ onClick TriggerSearch
                , disabled (String.isEmpty (String.trim model.inputBuffer) || model.searchStatus == SearchLoading)
                , class "btn btn-primary"
                ]
                [ text "Search" ]
            , button
                [ onClick ClearSearch
                , disabled (String.isEmpty model.inputBuffer && model.searchStatus == SearchIdle)
                , class "btn"
                ]
                [ text "Clear" ]
            ]
        , case model.searchStatus of
            SearchIdle ->
                p [ class "status-msg" ] [ text "Enter a search term above to begin searching." ]

            SearchLoading ->
                p [ class "status-msg" ] [ text "Searching database..." ]

            SearchFailure err ->
                p [ class "status-msg status-error" ] [ text ("Error: " ++ err) ]

            SearchSuccess results ->
                if List.isEmpty results then
                    p [ class "status-msg" ] [ text ("No results found matching \"" ++ model.inputBuffer ++ "\".") ]

                else
                    div []
                        [ p [] [ text ("Found " ++ String.fromInt (List.length results) ++ " result(s):") ]
                        , div [ class "results-container" ] (List.map renderSearchHit results)
                        ]
        ]


renderSearchHit : Search.ResponseItem -> Html Msg
renderSearchHit hit =
    div [ class "search-hit" ]
        [ h3 [ class "hit-title" ] [ a [ href hit.url, target "_blank" ] [ text hit.title ] ]
        , p [ class "hit-url" ] [ text hit.url ]
        , if String.isEmpty (String.trim hit.description) then
            text ""

          else
            p [ class "hit-description" ] [ text hit.description ]
        , if String.isEmpty (String.trim hit.snippet) then
            text ""

          else
            div [ class "hit-snippet-container" ]
                [ span [ class "hit-snippet-label" ] [ text "Snippet: " ]
                , span [] (renderSnippet hit.snippet)
                ]
        , p [ class "hit-meta" ]
            [ text ("Relevance rank: " ++ String.fromFloat hit.rank ++ " | Last Indexed: " ++ hit.lastIndexed) ]
        ]


renderSnippet : String -> List (Html msg)
renderSnippet snippetStr =
    renderSnippetHelper snippetStr []


renderSnippetHelper : String -> List (Html msg) -> List (Html msg)
renderSnippetHelper input acc =
    if String.isEmpty input then
        List.reverse acc

    else
        case String.indices "<mark>" input of
            [] ->
                List.reverse (text input :: acc)

            firstMarkIdx :: _ ->
                let
                    beforeMark =
                        String.left firstMarkIdx input

                    remainingAfterMark =
                        String.dropLeft (firstMarkIdx + 6) input
                in
                case String.indices "</mark>" remainingAfterMark of
                    [] ->
                        List.reverse (text input :: acc)

                    firstCloseIdx :: _ ->
                        let
                            markedText =
                                String.left firstCloseIdx remainingAfterMark

                            remainingAfterClose =
                                String.dropLeft (firstCloseIdx + 7) remainingAfterMark

                            newAcc =
                                Html.node "mark" [] [ text markedText ] :: text beforeMark :: acc
                        in
                        renderSnippetHelper remainingAfterClose newAcc


renderAdminTab : Model -> Html Msg
renderAdminTab model =
    div []
        [ h2 [] [ text "Website Administration" ]
        , div [ class "admin-section" ] [ renderWebsitesList model ]
        , div [ class "admin-section" ] [ renderAddWebsiteForm model ]
        , case model.selectedWebsite of
            Just site ->
                div [ class "admin-section" ] [ renderWebsiteDetails model site ]

            Nothing ->
                text ""
        ]


renderWebsitesList : Model -> Html Msg
renderWebsitesList model =
    div []
        [ h3 [] [ text "Registered Websites" ]
        , case model.websitesStatus of
            WebsitesNotLoaded ->
                button [ onClick FetchWebsites, class "btn btn-primary" ] [ text "Load Websites List" ]

            WebsitesLoading ->
                p [ class "status-msg" ] [ text "Loading websites..." ]

            WebsitesFailure err ->
                div [ class "status-msg status-error" ]
                    [ p [] [ text ("Error loading websites: " ++ err) ]
                    , button [ onClick FetchWebsites, class "btn btn-sm" ] [ text "Retry" ]
                    ]

            WebsitesSuccess sites ->
                if List.isEmpty sites then
                    p [ class "status-msg" ] [ text "No websites registered yet. Register one below." ]

                else
                    div [ class "table-container" ]
                        [ table []
                            [ thead []
                                [ tr []
                                    [ th [] [ text "ID" ]
                                    , th [] [ text "Name" ]
                                    , th [] [ text "Domain" ]
                                    , th [] [ text "Created At" ]
                                    , th [] [ text "Actions" ]
                                    ]
                                ]
                            , tbody []
                                (List.map (renderWebsiteRow model) sites)
                            ]
                        ]
        ]


renderWebsiteRow : Model -> Search.Website -> Html Msg
renderWebsiteRow model site =
    let
        isSelected =
            case model.selectedWebsite of
                Just s ->
                    s.id == site.id

                Nothing ->
                    False
    in
    tr []
        [ td [] [ text (String.fromInt site.id) ]
        , td [] [ text site.name ]
        , td [] [ text site.domain ]
        , td [] [ text site.createdAt ]
        , td []
            [ button [ onClick (SelectWebsite site), disabled isSelected, class "btn btn-sm" ] [ text "View Pages" ]
            , text " "
            , case model.confirmingDeleteWebsiteId of
                Just deleteId ->
                    if deleteId == site.id then
                        span [ class "confirm-prompt" ]
                            [ text "Are you sure? "
                            , button [ onClick (ConfirmDeleteWebsite site.id), class "btn btn-danger btn-sm" ] [ text "Yes, Delete" ]
                            , text " "
                            , button [ onClick CancelDeleteWebsite, class "btn btn-sm" ] [ text "Cancel" ]
                            ]

                    else
                        button [ onClick (RequestDeleteWebsite site.id), class "btn btn-danger btn-sm" ] [ text "Delete" ]

                Nothing ->
                    button [ onClick (RequestDeleteWebsite site.id), class "btn btn-danger btn-sm" ] [ text "Delete" ]
            ]
        ]


renderAddWebsiteForm : Model -> Html Msg
renderAddWebsiteForm model =
    div []
        [ h3 [] [ text "Register New Website" ]
        , div []
            [ div [ class "form-grid" ]
                [ div [ class "form-group" ]
                    [ label [] [ text "Website Name: " ]
                    , input
                        [ type_ "text"
                        , placeholder "MIT OpenCourseWare"
                        , onInput UpdateNewWebsiteName
                        , value model.newWebsiteName
                        , disabled (model.newWebsiteStatus == FormSubmitting)
                        , class "form-input"
                        ]
                        []
                    ]
                , div [ class "form-group" ]
                    [ label [] [ text "Website Domain: " ]
                    , input
                        [ type_ "text"
                        , placeholder "ocw.mit.edu"
                        , onInput UpdateNewWebsiteDomain
                        , value model.newWebsiteDomain
                        , disabled (model.newWebsiteStatus == FormSubmitting)
                        , class "form-input"
                        ]
                        []
                    ]
                ]
            , button
                [ onClick SubmitNewWebsite
                , disabled (model.newWebsiteStatus == FormSubmitting || String.isEmpty (String.trim model.newWebsiteName) || String.isEmpty (String.trim model.newWebsiteDomain))
                , class "btn btn-primary"
                ]
                [ text "Register Website" ]
            ]
        , case model.newWebsiteStatus of
            FormIdle ->
                text ""

            FormSubmitting ->
                p [ class "status-msg" ] [ text "Registering website..." ]

            FormSuccess msg ->
                p [ class "status-msg status-success" ] [ text msg ]

            FormFailure err ->
                p [ class "status-msg status-error" ] [ text ("Error: " ++ err) ]
        ]


renderWebsiteDetails : Model -> Search.Website -> Html Msg
renderWebsiteDetails model site =
    div []
        [ div [ class "admin-section-header" ]
            [ h3 [] [ text ("Webpages of " ++ site.name) ]
            , button [ onClick DeselectWebsite, class "btn btn-sm" ] [ text "Close Details" ]
            ]
        , renderWebpagesList model
        , hr [] []
        , renderIndexWebpageForm model site.id
        ]


renderWebpagesList : Model -> Html Msg
renderWebpagesList model =
    div []
        [ h4 [] [ text "Indexed Pages" ]
        , case model.webpagesStatus of
            WebpagesNotLoaded ->
                text ""

            WebpagesLoading ->
                p [ class "status-msg" ] [ text "Loading indexed pages..." ]

            WebpagesFailure err ->
                p [ class "status-msg status-error" ] [ text ("Error loading pages: " ++ err) ]

            WebpagesSuccess pages ->
                if List.isEmpty pages then
                    p [ class "status-msg" ] [ text "No webpages indexed for this website yet." ]

                else
                    div [ class "table-container" ]
                        [ table []
                            [ thead []
                                [ tr []
                                    [ th [] [ text "ID" ]
                                    , th [] [ text "Title" ]
                                    , th [] [ text "URL" ]
                                    , th [] [ text "Last Indexed" ]
                                    ]
                                ]
                            , tbody []
                                (List.map renderWebpageRow pages)
                            ]
                        ]
        ]


renderWebpageRow : Search.Webpage -> Html Msg
renderWebpageRow page =
    tr []
        [ td [] [ text (String.fromInt page.id) ]
        , td [] [ text page.title ]
        , td [] [ a [ href page.url, target "_blank" ] [ text page.url ] ]
        , td [] [ text page.lastIndexed ]
        ]


renderIndexWebpageForm : Model -> Int -> Html Msg
renderIndexWebpageForm model websiteId =
    div []
        [ h4 [] [ text "Index New Webpage" ]
        , div []
            [ div [ class "form-grid" ]
                [ div [ class "form-group" ]
                    [ label [] [ text "Page URL: " ]
                    , input
                        [ type_ "text"
                        , placeholder "https://ocw.mit.edu/courses/..."
                        , onInput UpdateNewWebpageUrl
                        , value model.newWebpageUrl
                        , disabled (model.newWebpageStatus == FormSubmitting)
                        , class "form-input"
                        ]
                        []
                    ]
                , div [ class "form-group" ]
                    [ label [] [ text "Title: " ]
                    , input
                        [ type_ "text"
                        , placeholder "Introduction to Computer Science"
                        , onInput UpdateNewWebpageTitle
                        , value model.newWebpageTitle
                        , disabled (model.newWebpageStatus == FormSubmitting)
                        , class "form-input"
                        ]
                        []
                    ]
                , div [ class "form-group form-group-full" ]
                    [ label [] [ text "Description: " ]
                    , input
                        [ type_ "text"
                        , placeholder "Free course materials for beginners."
                        , onInput UpdateNewWebpageDescription
                        , value model.newWebpageDescription
                        , disabled (model.newWebpageStatus == FormSubmitting)
                        , class "form-input"
                        ]
                        []
                    ]
                , div [ class "form-group form-group-full" ]
                    [ label [] [ text "Content (Searchable Text): " ]
                    , textarea
                        [ placeholder "Paste page body text here..."
                        , onInput UpdateNewWebpageContent
                        , value model.newWebpageContent
                        , disabled (model.newWebpageStatus == FormSubmitting)
                        , rows 6
                        , class "form-textarea"
                        ]
                        []
                    ]
                , div [ class "form-group form-group-full" ]
                    [ label [] [ text "Raw HTML (Optional): " ]
                    , textarea
                        [ placeholder "<html><body>... (Optional)"
                        , onInput UpdateNewWebpageRawHtml
                        , value model.newWebpageRawHtml
                        , disabled (model.newWebpageStatus == FormSubmitting)
                        , rows 4
                        , class "form-textarea"
                        ]
                        []
                    ]
                ]
            , button
                [ onClick (SubmitNewWebpage websiteId)
                , disabled (model.newWebpageStatus == FormSubmitting || String.isEmpty (String.trim model.newWebpageUrl) || String.isEmpty (String.trim model.newWebpageContent))
                , class "btn btn-primary"
                ]
                [ text "Index Webpage" ]
            ]
        , case model.newWebpageStatus of
            FormIdle ->
                text ""

            FormSubmitting ->
                p [ class "status-msg" ] [ text "Indexing webpage content..." ]

            FormSuccess msg ->
                p [ class "status-msg status-success" ] [ text msg ]

            FormFailure err ->
                p [ class "status-msg status-error" ] [ text ("Error: " ++ err) ]
        ]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }
