//
//  ViewController.swift
//  Session Map
//
//  Created by Kevin Peters on 2/11/21.
//

import Cocoa
import PFAssistive

class ViewController: NSViewController, PFObserverDelegate {

    @IBOutlet weak var currentTrackLabel: NSTextField!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var refreshRateLabel: NSTextField!
    @IBOutlet weak var refreshRateSlider: NSSlider!
    @IBOutlet weak var cpuUsageLabel: NSTextField!
    @IBOutlet weak var autoPanToggle: NSButton!
    @IBOutlet weak var runLoopButton: NSButton!
    @IBOutlet weak var accessibilityStatusLabel: NSTextField!
    
    var currentTrackTitle = ""
    var proToolsStatus = false
    var refreshRate = 1.0
    var runLoopTimer: Timer?
    var checkProToolsStatusScript = ""
    var identifyCurrentTrackScript = ""
    var accessibilityEnabled = false
    
    var proToolsObserver: PFObserver?
    var proToolsApp: PFApplicationUIElement?
    var editWindow: PFUIElement?
    var trackList: PFUIElement?
    var totalTracks = 0
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.currentTrackLabel.setAccessibilityTitle("Current Track")
        
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

    
    func checkProToolsStatus() {
        
        if let app = PFApplicationUIElement.init(bundleIdentifier: "com.avid.ProTools", delegate: self) {
            //print("LOCKED ONTO TARGET")
            self.proToolsApp = app
            self.proToolsObserver = PFObserver.init(bundleIdentifier: "com.avid.ProTools")
            self.proToolsObserver?.setDelegate(self)
            //self.proToolsObserver?.register(forNotification: "AXUIElementDestroyed", from: self.proToolsApp, contextInfo: nil)
            if let children = self.proToolsApp?.axChildren as [PFUIElement]? {
                for child in children {
                    if let title = child.axTitle as String? {
                        if title.contains("Edit: ") {
                            self.editWindow = child as PFUIElement
                            self.statusLabel.stringValue = title
                            //self.proToolsObserver?.register(forNotification: "AXWindowMiniaturized", from: self.editWindow, contextInfo: nil)
                            if let children = self.editWindow?.axChildren as [PFUIElement]? {
                                for child in children {
                                    if let title = child.axTitle as String? {
                                        if title.contains("Track List") {
                                            self.trackList = child as PFUIElement
                                            self.proToolsObserver?.register(forNotification: "AXRowCountChanged", from: self.trackList, contextInfo: nil)
                                            self.getTrackCount()
                                        } else if title.contains("Counter Display Cluster") {
                                            if let children = child.axChildren as [PFUIElement]? {
                                                for child in children {
                                                    if let title = child.axTitle as String? {
                                                        if title.contains("Edit Selection Start") {
                                                            let editStartCursor = child as PFUIElement
                                                            self.proToolsObserver?.register(forNotification: "AXValueChanged", from: editStartCursor, contextInfo: nil)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            print("Could not find Pro Tools app")
        }
    }
    
    func identifyChild(element: PFUIElement?, containsString searchString: String) -> PFUIElement? {
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
                                    self.currentTrackLabel.stringValue = value.replacingOccurrences(of: "Selected. ", with: "")
                                    self.currentTrackTitle = value.replacingOccurrences(of: "Selected. ", with: "")
                                    if self.autoPanToggle.state.rawValue == 1 {
                                        self.openPanWindow()
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
    
    
    func resolveTracks() {
        if let element = self.identifyChild(element: self.editWindow, containsString: "Track List") {
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
                self.resolveTracks()
            }
        }
    }
    
    
    
    func setupScripts() {
        
        self.checkProToolsStatusScript = """

        tell application "System Events"
            if exists (process "Pro Tools") then
                tell process "Pro Tools"
                    if exists (1st window whose title contains "Edit: ") then
                        return "true"
                    else
                        return "false"
                    end if
                end tell
            else
                return "false"
            end if
        end tell

        """
        
        self.identifyCurrentTrackScript = """

        tell application "System Events"
            tell process "Pro Tools"
                --set frontmost to true
                tell (1st window whose title contains "Edit: ")
                    set selectedTrack to title of button of UI element 2 of (1st row of table "Track List" whose selected is true)
                    set formattedString to text of selectedTrack as string
                    set AppleScript's text item delimiters to "Selected. "
                    set theTextItems to every text item of formattedString
                    set AppleScript's text item delimiters to ""
                    set formattedString to theTextItems as string
                    return formattedString
                end tell
            end tell
        end tell

        """
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

    func setTimer(interval: Double) {
        self.runLoopTimer = Timer(timeInterval: interval, target: self, selector: #selector(backgroundLoop), userInfo: nil, repeats: true)
        if let timer = self.runLoopTimer {
            timer.tolerance = 0.3
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    @objc func backgroundLoop() {
        
        DispatchQueue.global(qos: .background).async {
            
            if self.accessibilityEnabled {
                
                var error: NSDictionary?
                
                // Checks if Pro Tools is running
                if let scriptObject = NSAppleScript(source: self.checkProToolsStatusScript) {
                    if let scriptResult = scriptObject.executeAndReturnError(&error).stringValue {
                        //print(scriptResult)
                        if scriptResult == "true" {
                            self.proToolsStatus = true
                            DispatchQueue.main.async {
                                self.statusLabel.stringValue = "Scanning..."
                            }
                        } else {
                            self.proToolsStatus = false
                        }
                    } else if (error != nil) {
                        print("error: ", error!)
                        self.proToolsStatus = false
                    }
                }
                
                if self.proToolsStatus == true {
                    // Triggers Identify Current Track Script
                    if let scriptObject = NSAppleScript(source: self.identifyCurrentTrackScript) {
                        if let scriptResult = scriptObject.executeAndReturnError(&error).stringValue {
                            //print(scriptResult)
                            if scriptResult != self.currentTrackTitle {
                                self.currentTrackTitle = scriptResult
                                DispatchQueue.main.async {
                                    self.currentTrackLabel.stringValue = self.currentTrackTitle
                                    if self.autoPanToggle.state.rawValue == 1 {
                                        self.openPanWindow()
                                    }
                                }
                            }
                        } else if (error != nil) {
                            //print("error: ", error!)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.statusLabel.stringValue = "Pro Tools Edit Window Is Not Open"
                    }
                }
            }
        }
    }

    
    @IBAction func refreshRateChanged(_ sender: Any) {
        self.refreshRate = self.refreshRateSlider.doubleValue
        self.refreshRateLabel.stringValue = String(format: "%.2f", self.refreshRate)
    }
    
    @IBAction func updateTimer(_ sender: Any) {
        if let timer = self.runLoopTimer {
            timer.invalidate()
            self.setTimer(interval: self.refreshRate)
            self.runLoopButton.title = "Update Run Loop"
        }
    }
    
    @IBAction func stopTimer(_ sender: Any) {
        if let timer = self.runLoopTimer {
            timer.invalidate()
            self.statusLabel.stringValue = "Stopped"
            self.runLoopButton.title = "Start Run Loop"
        }
    }
    
    @IBAction func openPanButtonPressed(_ sender: Any) {
        //self.openPanWindow()
        self.checkAccessibilityStatus()
    }
    

    func openPanWindow() {
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
    
    fileprivate func cpuUsage() -> Double {
        var kr: kern_return_t
        var task_info_count: mach_msg_type_number_t

        task_info_count = mach_msg_type_number_t(TASK_INFO_MAX)
        var tinfo = [integer_t](repeating: 0, count: Int(task_info_count))

        kr = task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), &tinfo, &task_info_count)
        if kr != KERN_SUCCESS {
            return -1
        }
        // This threw a method so I used the below.  It doesn't seem to effect it though it is a different value
        //var thread_list: thread_act_array_t? = UnsafeMutablePointer(mutating: [thread_act_t]())
        //print(thread_list)
        var bytes = [thread_act_t]()
        var thread_list: thread_act_array_t? = UnsafeMutablePointer<UInt32>.allocate(capacity: bytes.count)
        thread_list?.initialize(from: &bytes, count: bytes.count)
        //print(thread_listx)
        
        var thread_count: mach_msg_type_number_t = 0
        defer {
            if let thread_list = thread_list {
                vm_deallocate(mach_task_self_, vm_address_t(UnsafePointer(thread_list).pointee), vm_size_t(thread_count))
            }
        }

        kr = task_threads(mach_task_self_, &thread_list, &thread_count)

        if kr != KERN_SUCCESS {
            return -1
        }

        var tot_cpu: Double = 0

        if let thread_list = thread_list {

            for j in 0 ..< Int(thread_count) {
                var thread_info_count = mach_msg_type_number_t(THREAD_INFO_MAX)
                var thinfo = [integer_t](repeating: 0, count: Int(thread_info_count))
                kr = thread_info(thread_list[j], thread_flavor_t(THREAD_BASIC_INFO),
                                 &thinfo, &thread_info_count)
                if kr != KERN_SUCCESS {
                    return -1
                }

                let threadBasicInfo = convertThreadInfoToThreadBasicInfo(thinfo)

                if threadBasicInfo.flags != TH_FLAGS_IDLE {
                    tot_cpu += (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE)) * 100.0
                }
            } // for each thread
        }

        return tot_cpu
    }

    fileprivate func convertThreadInfoToThreadBasicInfo(_ threadInfo: [integer_t]) -> thread_basic_info {
        var result = thread_basic_info()

        result.user_time = time_value_t(seconds: threadInfo[0], microseconds: threadInfo[1])
        result.system_time = time_value_t(seconds: threadInfo[2], microseconds: threadInfo[3])
        result.cpu_usage = threadInfo[4]
        result.policy = threadInfo[5]
        result.run_state = threadInfo[6]
        result.flags = threadInfo[7]
        result.suspend_count = threadInfo[8]
        result.sleep_time = threadInfo[9]

        return result
    }
    
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
