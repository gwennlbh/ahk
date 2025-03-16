#SingleInstance Force
#Include %A_ScriptDir%\_JXON.ahk  ; JSON parser

global spotify_access_token := ""
global credentials := LoadCredentials()

Media_Stop::LikeCurrentTrack()

LikeCurrentTrack() {
    global spotify_access_token

    if (spotify_access_token = "") {
        spotify_access_token := RefreshAccessToken()
    }

    ; Get currently playing track
    url := "https://api.spotify.com/v1/me/player/currently-playing"
    response := HttpGet(url, spotify_access_token)

    if response = "" {
        MsgBox "No track is currently playing or unable to fetch the track data."
        return
    }

    ; Debugging: Show the response to understand its structure
    ; MsgBox % "Response: " response

    track := Jxon_Load(&response)
    
    ; Debugging: Output the track structure
    ; MsgBox % "Track Object: " track

    if !track.Has("item") {
        MsgBox "No 'item' property found in the response. Response: " response
        return
    }

    trackID := track["item"]["id"]
    if trackID = "" {
        MsgBox "Couldn't retrieve track ID."
        return
    }

    ; Like the track
    likeUrl := "https://api.spotify.com/v1/me/tracks?ids=" . trackID
    HttpPut(likeUrl, spotify_access_token)

    ToolTip "Track Liked! ❤️"
    Sleep 2000
    ToolTip
}

LoadCredentials() {
    creds := Map()
    filePath := A_ScriptDir "\spotify_credentials.txt"

    if !FileExist(filePath) {
        MsgBox "spotify_credentials.txt missing! Please create it with client_id, client_secret, and refresh_token."
        ExitApp
    }

    for line in StrSplit(FileRead(filePath), "`n", "`r") {
        if (line = "" || !InStr(line, "="))
            continue
        parts := StrSplit(line, "=")
	key := Trim(parts[1])
        creds[key] := Trim(parts[2])
    }

    ToolTip "Spotify credentials loaded"
    Sleep 2000
    ToolTip

    return creds
}

RefreshAccessToken() {
    global credentials

    if !(credentials.Has("client_id") && credentials.Has("client_secret") && credentials.Has("refresh_token")) {
        MsgBox "Missing credentials in spotify_credentials.txt"
        ExitApp
    }

    url := "https://accounts.spotify.com/api/token"
    postData := "grant_type=refresh_token&refresh_token=" . credentials["refresh_token"] 
                . "&client_id=" . credentials["client_id"] 
                . "&client_secret=" . credentials["client_secret"]

    response := HttpPost(url, postData, "application/x-www-form-urlencoded")

    if response = "" {
        MsgBox "Failed to refresh access token!"
        ExitApp
    }

    json := Jxon_Load(&response)
    if json.Has("access_token") {
        newToken := json["access_token"]
        return newToken
    }

    MsgBox "Failed to retrieve new access token!"
    ExitApp
}

HttpGet(url, token) {
    http := ComObject("WinHttp.WinHttpRequest.5.1")
    http.Open("GET", url, false)
    http.SetRequestHeader("Authorization", "Bearer " . token)
    http.Send()
    return http.ResponseText
}

HttpPut(url, token) {
    http := ComObject("WinHttp.WinHttpRequest.5.1")
    http.Open("PUT", url, false)
    http.SetRequestHeader("Authorization", "Bearer " . token)
    http.SetRequestHeader("Content-Length", "0")
    http.Send()
    return http.Status
}

HttpPost(url, postData, contentType := "application/x-www-form-urlencoded") {
    http := ComObject("WinHttp.WinHttpRequest.5.1")
    http.Open("POST", url, false)
    http.SetRequestHeader("Content-Type", contentType)
    http.Send(postData)
    return http.ResponseText
}
