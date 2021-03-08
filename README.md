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
- [x] Lock track selection
- [ ] Automatic disconnect and reconnect to Pro Tools when it opens and closes, or when edit window is closed/opened
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

---
### Enabling Accessibility Access
1. Upon first opening the app, you will be given a prompt to enable Accessibility Access so Session Map can read the UI of Pro Tools.

![Initial Prompt](https://i.imgur.com/SZ8SvjM.png)

2. Clicking "Open System Preferences" should bring you to System Preferences -> Security and Privacy -> Accessibility.  Unlock the settings with you administrator password and make sure Session Map is checked as seen below:

![Settings](https://i.imgur.com/oZvnqCa.png)

3. To confirm access is enabled, click the "Check Status" button in Session Map.  The status label will change to "Enabled" when everything is setup correctly

![Enabled](https://i.imgur.com/u3r6HSp.png)

4. The first time you click either of the toggle buttons or use the auto open functionality, you will receive another prompt.  Click OK to allow Session Map to trigger applescripts to open and close the pan and insert windows.  You can remove access by removing Session Map in System Preferences -> Security and Privacy -> Accessibility

![Prompt-2](https://i.imgur.com/vDBumQr.png)
