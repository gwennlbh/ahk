#SingleInstance Force
#Include %A_ScriptDir%\_JXON.ahk  ; JSON parser
#Include %A_ScriptDir%\HTTP.ahk ; HTTP Requests
#Include %A_ScriptDir%\backup_likes.ahk ; Likes backup every day at most, on a like 

global spotify_access_token := ""
global credentials := LoadCredentials()

Media_Stop::LikeCurrentTrack()

LikeCurrentTrack(retrying := "no") {
    global spotify_access_token

    if (spotify_access_token = "" || retrying = "yes") {
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
    ; MsgBox "Response: " response

    track := Jxon_Load(&response)
    
    ; Debugging: Output the track structure

    if !track.Has("item") {
	if (retrying = "yes") {
	        MsgBox "No 'item' property found in the response. Response: " response
	} else {
		LikeCurrentTrack("yes")
	}
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

    ToolTip "❤️ " track["item"]["name"] " by " JoinArtists(track["item"]["artists"])
    Sleep 2000
    ToolTip

    if (WasLibraryUpdatedYesterday() == 1) {
         BackupLikes()
    }
}

JoinArtists(array, separator := ", ") {
    output := ""
    Loop array.length
	if (A_Index > 1) {
		output := output separator array[A_Index]["name"]
	} else {
		output := output array[A_Index]["name"]
	}
    return output
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

    return creds
}

RefreshAccessToken() {
    global credentials := LoadCredentials()

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

