# Session Map

![Main Window](https://i.imgur.com/6ICrgAc.png)

### The Idea
- A companion app for Pro Tools that fetches current UI status for various elements such as the currently selected track.  
- Designed to run background observers on UI elements in Pro Tools.

### Current Features
- Can determine which Pro Tools track is selected while sitting in the background using minimal CPU.
- Button to open/close pan window of currently selected track, as well a toggle to auto-open the pan when the track selection changes
- Button to open/close a specific insert of currently selected track, as well a toggle to auto-open the insert when the track selection changes

### Roadmap to v0.3
- [x] Fix icon vertical placement
- [ ] Automatic disconnect and reconnect to Pro Tools when it opens and closes, or when edit window is closed/opened
- [x] Lock selection
- [ ] Slots for tracks you'd like to save to directly address (mute, solo, inserts, sends, pan)
- [ ] Plist support for basic persistence
- [ ] Add scriptability to app, so it can be directly addressed by applescript, instead of going through System Events

---
### Applescript Examples
- Set the clipboard to the current track title 
```      
tell application "System Events"
	tell window "Session Map" of process "Session Map"
		tell (static text 1 whose title is "Current Track")
			set currentTrack to value
			set the clipboard to currentTrack
		end tell
	end tell
end tell
```
