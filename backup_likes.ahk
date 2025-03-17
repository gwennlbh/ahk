#Include %A_ScriptDir%\HTTP.ahk ; HTTP Requests
#Include %A_ScriptDir%\_JXON.ahk ; JSON parsing 

BackupLikes() {
	ToolTip "Backing up tracks to github"
	; Last update to library.tsv was not today, run the backup
	; See https://github.com/gwennlbh/music-library/tree/main/backup.py
	Run "uv run backup.py", "E:\music", "Hide" 
	ToolTip "Backed up tracks to github"
	Sleep 200
	ToolTip
}

WasLibraryUpdatedYesterday() {
	response := HttpGet("https://api.github.com/repos/gwennlbh/music-library/commits?path=library.tsv&page=1&per_page=1")
	data := Jxon_Load(&response)
	datetimestring := data[1]["commit"]["committer"]["date"]
	dateparts := StrSplit(datetimestring, "T")
	datepart := dateparts[1]

	if (StrCompare(GetToday(), datepart) != 0) {
		return 1
	}
	return 0
}

GetToday() {
	return A_YYYY "-" A_MM "-" A_DD
}
