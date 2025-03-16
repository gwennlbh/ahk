HttpGet(url, token := "") {
    http := ComObject("WinHttp.WinHttpRequest.5.1")
    http.Open("GET", url, false)
    if (token != "") {
    	http.SetRequestHeader("Authorization", "Bearer " . token)
    }
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

