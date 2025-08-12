#!/usr/bin/env osascript

tell application "System Events"
    display dialog "If you see this dialog, GUI apps can run on your system.\n\nNow testing if Parchment window appears..."
end tell

do shell script "open -a /Users/corey/Markdown/corey-md-swift/Parchment.app"

delay 2

tell application "System Events"
    set appList to name of every application process
    if "Parchment" is in appList then
        display dialog "Parchment is running!"
    else
        display dialog "Parchment is not showing in process list"
    end if
end tell