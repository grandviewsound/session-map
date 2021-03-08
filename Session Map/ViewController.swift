//
//  ViewController.swift
//  Session Map
//
//  Created by Kevin Peters on 2/11/21.
//

import Cocoa
import PFAssistive

class ViewController: NSViewController, PFObserverDelegate {

    @IBOutlet weak var editSessionLabel: NSTextField!
    @IBOutlet weak var currentTrackLabel: NSTextField!
    @IBOutlet weak var autoPanToggle: NSButton!
    @IBOutlet weak var autoInsertToggle: NSButton!
    @IBOutlet weak var insertPopUpButton: NSPopUpButton!
    @IBOutlet weak var lockSelectionToggle: NSButton!
    @IBOutlet weak var accessibilityStatusLabel: NSTextField!
    
    var currentTrackTitle = ""
    var proToolsStatus = false
    var autoPanActivated = false
    var autoInsertActivated = false
    var selectionLocked = false
    var refreshRate = 1.0
    var runLoopTimer: Timer?
    var checkProToolsStatusScript = ""
    var identifyCurrentTrackScript = ""
    var accessibilityEnabled = false
    var currentInsert = ""
    
    var proToolsObserver: PFObserver?
    var proToolsApp: PFApplicationUIElement?
    var editWindow: PFUIElement?
    var trackList: PFUIElement?
    var totalTracks = 0
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.currentTrackLabel.setAccessibilityTitle("Current Track")
        self.currentInsert = self.insertPopUpButton.title
        
        //self.setupScripts()
        self.checkAccessibilityStatus()
        
        //self.setTimer(interval: self.refreshRate)
        
        //let cpuTimer = Timer(timeInterval: 4.0, target: self, selector: #selector(setCPULabel), userInfo: nil, repeats: true)
        //cpuTimer.tolerance = 1.0
        //RunLoop.current.add(cpuTimer, forMode: .common)
        
        self.checkProToolsStatus()
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func checkAccessibilityStatusButtonPressed(_ sender: Any) {
        self.checkAccessibilityStatus()
    }
    
    func checkAccessibilityStatus() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        if !accessEnabled {
            self.accessibilityStatusLabel.stringValue = "Access Not Enabled. Restart App"
            self.accessibilityEnabled = false
        } else {
            self.accessibilityStatusLabel.stringValue = "Enabled"
            self.accessibilityEnabled = true
        }
    }
    
    
    @IBAction func reconnectPTButtonTriggered(_ sender: Any) {
        self.checkProToolsStatus()
    }
    
    func checkProToolsStatus() {
        // Find Pro Tools app and set it as main observer object
        if let app = PFApplicationUIElement.init(bundleIdentifier: "com.avid.ProTools", delegate: self) {
            //print("LOCKED ONTO TARGET")
            self.proToolsApp = app
            self.proToolsObserver = PFObserver.init(bundleIdentifier: "com.avid.ProTools")
            self.proToolsObserver?.setDelegate(self)
            //self.proToolsObserver?.register(forNotification: "AXUIElementDestroyed", from: self.proToolsApp, contextInfo: nil)
            // Get the current Edit Window Element
            if let editWindowElement = self.identifyChildByTitle(element: self.proToolsApp, containsString: "Edit: ") {
                self.editWindow = editWindowElement as PFUIElement
                if let title = editWindowElement.axTitle as String? {
                    let formattedString = title.replacingOccurrences(of: "Edit: ", with: "")
                    self.editSessionLabel.stringValue = formattedString
                }
                // Set an observer object to check when track list row count changes, and get current track selected
                if let trackListElement = self.identifyChildByTitle(element: self.editWindow, containsString: "Track List") {
                    self.trackList = trackListElement as PFUIElement
                    self.proToolsObserver?.register(forNotification: "AXRowCountChanged", from: self.trackList, contextInfo: nil)
                    self.getTrackCount()
                }
                // Set an observer object for the "Edit Selection Start" value change
                if let counterDisplayElement = self.identifyChildByTitle(element: self.editWindow, containsString: "Counter Display Cluster") {
                    if let editSelectionStartElement = self.identifyChildByTitle(element: counterDisplayElement, containsString: "Edit Selection Start") {
                        self.proToolsObserver?.register(forNotification: "AXValueChanged", from: editSelectionStartElement, contextInfo: nil)
                    }
                }
            }
        } else {
            print("Could not find Pro Tools app")
            self.editSessionLabel.stringValue = "Could not find Pro Tools session"
            self.currentTrackTitle = ""
            self.currentTrackLabel.stringValue = self.currentTrackTitle
        }
    }
    
    // Utility function to find child by title
    func identifyChildByTitle(element: PFUIElement?, containsString searchString: String) -> PFUIElement? {
        if let children = element!.axChildren as [PFUIElement]? {
            for child in children {
                if let title = child.axTitle as String? {
                    if title.contains(searchString) {
                        let targetedElement = child as PFUIElement
                        return targetedElement
                    }
                }
            }
        }
        return nil
    }
    
    func getTrackCount() {
        var trackCount = 0
        if let tracks = self.trackList?.axChildren as [PFUIElement]? {
            for track in tracks {
                if track.axRole == "AXRow" {
                    trackCount += 1
                    if let cells = track.axChildren as [PFUIElement]? {
                        if let element = cells[1].axChildren as [PFUIElement]? {
                            if let value = element[0].axTitle as String? {
                                //self.proToolsObserver?.register(forNotification: "AXTitleChanged", from: element[0], contextInfo: nil)
                                if value.contains("Selected") {
                                    if !selectionLocked {
                                        let formattedString = value.replacingOccurrences(of: "Selected. ", with: "")
                                        if self.currentTrackTitle != formattedString {
                                            self.currentTrackTitle = formattedString
                                            if self.autoPanActivated {
                                                self.togglePanWindow()
                                            }
                                            if self.autoInsertActivated {
                                                self.toggleInsertWindow()
                                            }
                                            DispatchQueue.main.async {
                                                self.currentTrackLabel.stringValue = self.currentTrackTitle
                                                
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            self.totalTracks = trackCount
            //print("Track Count: \(self.totalTracks)")
        }
    }
    
    
    func findSelectedTrack() {
        if let element = self.identifyChildByTitle(element: self.editWindow, containsString: "Track List") {
            self.trackList = element as PFUIElement
            self.getTrackCount()
        } else {
            print("Could not find Track List")
        }
    }
    
    
    // Delegate Method for PFObserver
    func application(withIdentifier identifier: String, atPath fullPath: String, didPostAccessibilityNotification notification: String, fromObservedUIElement observedUIElement: PFUIElement, forAffectedUIElement affectedUIElement: PFUIElement) {
        //print("App Bundle ID: \(identifier)")
        //print("Full Path: \(fullPath)")
        //print("Notification: \(notification)")
        //print("Observed Element: \(observedUIElement)")
        //print("Affected Element: \(affectedUIElement)")
        if let title = affectedUIElement.axTitle as String? {
            if title == "Track List" {
                self.trackList = affectedUIElement
                //self.getTrackCount()
            }
            if title == "Edit Selection Start" {
                DispatchQueue.global(qos: .background).async {
                    self.findSelectedTrack()
                }
            }
        }
    }
    
    
    @IBAction func panButtonTriggered(_ sender: Any) {
        self.togglePanWindow()
    }
    
    @IBAction func autoPanToggleTriggered(_ sender: Any) {
        if self.autoPanToggle.state.rawValue == 1 {
            self.autoPanActivated = true
        } else {
            self.autoPanActivated = false
        }
    }
    
    func togglePanWindow() {
        
        DispatchQueue.global(qos: .background).async {
            
            if self.accessibilityEnabled {
                
                var error: NSDictionary?
                
                let script = """

                tell application "System Events"
                    tell process "Pro Tools"
                        tell (1st window whose title contains "Edit: ")
                            click button "Output Window button" of group "Audio IO" of group "\(self.currentTrackTitle)"
                        end tell
                    end tell
                end tell

                """
                
                // Checks if Pro Tools is running
                if let scriptObject = NSAppleScript(source: script) {
                    if let scriptResult = scriptObject.executeAndReturnError(&error).stringValue {
                        print(scriptResult)
                    } else if (error != nil) {
                        print("error: ", error!)
                    }
                }
            }
        }
    }

    
    @IBAction func insertToggleButtonTriggered(_ sender: Any) {
        self.toggleInsertWindow()
    }
    
    @IBAction func autoInsertToggleTriggered(_ sender: Any) {
        if self.autoInsertToggle.state.rawValue == 1 {
            self.autoInsertActivated = true
        } else {
            self.autoInsertActivated = false
        }
    }
    
    @IBAction func insertPopUpMenuTriggered(_ sender: Any) {
        self.currentInsert = self.insertPopUpButton.title
    }
    
    
    func toggleInsertWindow() {
        
        DispatchQueue.global(qos: .background).async {
            
            if self.accessibilityEnabled {
                
                var error: NSDictionary?
                
                let script = """

                tell application "System Events"
                    tell process "Pro Tools"
                        tell (1st window whose title contains "Edit: ")
                            tell group "\(self.currentTrackTitle)"
                                tell group "Inserts A-E"
                                    if description of button "Insert Assignment \(self.currentInsert)" is not equal to "" then
                                        click button "Insert Assignment \(self.currentInsert)"
                                    end if
                                end tell
                            end tell
                        end tell
                    end tell
                end tell

                """
                
                // Checks if Pro Tools is running
                if let scriptObject = NSAppleScript(source: script) {
                    if let scriptResult = scriptObject.executeAndReturnError(&error).stringValue {
                        print(scriptResult)
                    } else if (error != nil) {
                        print("error: ", error!)
                    }
                }
            }
        }
    }
    
    
    @IBAction func lockSelectionToggleTriggered(_ sender: Any) {
        if self.lockSelectionToggle.state.rawValue == 1 {
            self.selectionLocked = true
        } else {
            self.selectionLocked = false
        }
    }
    
    
    
    
    
    
    
    
    
//    func setupScripts() {
//
//        self.checkProToolsStatusScript = """
//
//        tell application "System Events"
//            if exists (process "Pro Tools") then
//                tell process "Pro Tools"
//                    if exists (1st window whose title contains "Edit: ") then
//                        return "true"
//                    else
//                        return "false"
//                    end if
//                end tell
//            else
//                return "false"
//            end if
//        end tell
//
//        """
//
//        self.identifyCurrentTrackScript = """
//
//        tell application "System Events"
//            tell process "Pro Tools"
//                --set frontmost to true
//                tell (1st window whose title contains "Edit: ")
//                    set selectedTrack to title of button of UI element 2 of (1st row of table "Track List" whose selected is true)
//                    set formattedString to text of selectedTrack as string
//                    set AppleScript's text item delimiters to "Selected. "
//                    set theTextItems to every text item of formattedString
//                    set AppleScript's text item delimiters to ""
//                    set formattedString to theTextItems as string
//                    return formattedString
//                end tell
//            end tell
//        end tell
//
//        """
//    }
//
//
//    func setTimer(interval: Double) {
//        self.runLoopTimer = Timer(timeInterval: interval, target: self, selector: #selector(backgroundLoop), userInfo: nil, repeats: true)
//        if let timer = self.runLoopTimer {
//            timer.tolerance = 0.3
//            RunLoop.current.add(timer, forMode: .common)
//        }
//    }
//
//
//    @objc func backgroundLoop() {
//
//        DispatchQueue.global(qos: .background).async {
//
//            if self.accessibilityEnabled {
//
//                var error: NSDictionary?
//
//                // Checks if Pro Tools is running
//                if let scriptObject = NSAppleScript(source: self.checkProToolsStatusScript) {
//                    if let scriptResult = scriptObject.executeAndReturnError(&error).stringValue {
//                        //print(scriptResult)
//                        if scriptResult == "true" {
//                            self.proToolsStatus = true
//                            DispatchQueue.main.async {
//                                //self.statusLabel.stringValue = "Scanning..."
//                            }
//                        } else {
//                            self.proToolsStatus = false
//                        }
//                    } else if (error != nil) {
//                        print("error: ", error!)
//                        self.proToolsStatus = false
//                    }
//                }
//
//                if self.proToolsStatus == true {
//                    // Triggers Identify Current Track Script
//                    if let scriptObject = NSAppleScript(source: self.identifyCurrentTrackScript) {
//                        if let scriptResult = scriptObject.executeAndReturnError(&error).stringValue {
//                            //print(scriptResult)
//                            if scriptResult != self.currentTrackTitle {
//                                self.currentTrackTitle = scriptResult
//                                DispatchQueue.main.async {
//                                    self.currentTrackLabel.stringValue = self.currentTrackTitle
//                                    if self.autoPanToggle.state.rawValue == 1 {
//                                        self.openPanWindow()
//                                    }
//                                }
//                            }
//                        } else if (error != nil) {
//                            //print("error: ", error!)
//                        }
//                    }
//                } else {
//                    DispatchQueue.main.async {
//                        //self.statusLabel.stringValue = "Pro Tools Edit Window Is Not Open"
//                    }
//                }
//            }
//        }
//    }

    
    
    

    
}


extension DispatchQueue {

    static func background(delay: Double = 0.0, background: (()->Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }

}
