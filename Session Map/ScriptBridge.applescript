

script ScriptBridge
    
    property parent : class "NSObject"
    
    
    to isRunning() -- () -> NSNumber (Bool)
        -- AppleScript will automatically launch apps before sending Apple events;
        -- if that is undesirable, check the app object's `running` property first
        return running of application "Podcasts"
    end isRunning
    
    
    to playerState() -- () -> NSNumber (PlayerState)
        tell application "Podcasts"
            if running then
                set currentState to playerState
                -- ASOC does not bridge AppleScript's 'type class' and 'constant' values
                set i to 1
                repeat with stateEnumRef in {stopped, playing, paused, fastForwarding, rewinding}
                    if currentState is equal to contents of stateEnumRef then return i
                    set i to i + 1
                end repeat
            end if
            return 0 -- 'unknown'
        end tell
    end playerState
    
    
    to trackInfo() -- () -> ["trackName":NSString, "trackArtist":NSString, "trackAlbum":NSString]?
        tell application "Podcasts"
            try
                return {trackName:name, trackArtist:artist, trackAlbum:album} of currentTrack
            on error number -1728 -- current track is not available
                return missing value -- nil
            end try
        end tell
    end trackInfo
    
    to trackDuration() -- () -> NSNumber (Double, >=0)
        tell application "Podcasts"
            return duration of currentTrack
        end tell
    end trackDuration
    
    
    to soundVolume() -- () -> NSNumber (Int, 0...100)
        tell application "Podcasts"
            return sound volume -- ASOC will convert returned integer to NSNumber
        end tell
    end soundVolume
    
    to setSoundVolume:newVolume -- (NSNumber) -> ()
        -- ASOC does not convert NSObject parameters to AS types automatically…
        tell application "Podcasts"
            -- …so be sure to coerce NSNumber to native integer before using it in Apple event
            set sound volume to newVolume as integer
        end tell
    end setSoundVolume:
    
    
    to playPause()
        tell application "Podcasts" to playPause
    end playPause
    
    to gotoNextTrack()
        tell application "Podcasts" to nextTrack
    end gotoNextTrack
    
    to gotoPreviousTrack()
        tell application "Podcasts" to previousTrack
    end gotoPreviousTrack


    to currentTrack()
        tell application "System Events"
            
            if exists (process "Pro Tools") then
                
                tell process "Pro Tools"
                    --set frontmost to true
                    tell (1st window whose title contains "Edit: ")
                        
                        set selectedTrack to title of button of UI element 2 of (1st row of table "Track List" whose selected is true)
                        
                        set formattedString to text of selectedTrack as string
                        set AppleScript's text item delimiters to "Selected. "
                        set theTextItems to every text item of formattedString
                        set AppleScript's text item delimiters to ""
                        set formattedString to theTextItems as string
                        --set the clipboard to formattedString
                        return formattedString
                        
                    end tell
                end tell
            end if
        end tell
    end currentTrack




    
end script
