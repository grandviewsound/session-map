# Session Map

![Main Window](https://i.imgur.com/iCHDrFj.png)

### The Idea
- A companion app for Pro Tools that fetches current UI status for various elements such as the currently selected track.  
- Designed to run background applescripts at a set interval so when user interaction is needed, the information is available has less of a delay in larger sessions.

### Current Features
- Can determine which Pro Tools track is selected while sitting in the background using minimal CPU.  
- Adjustable script timer to determine how often the background script gets called. 
- Button for opening pan window of currently selected track
- Switch to auto-open the pan which when the track selection changes.

### Roadmap to v0.3
- [ ] Add scriptability to app, so it can be directly addressed by applescript, instead of going through System Events
- [ ] Slots for tracks you'd like to save to directly address (mute, solo, inserts, sends, pan)
- [ ] Plist support for basic persistence

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
