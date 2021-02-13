//
//  ViewController.swift
//  Session Map
//
//  Created by Kevin Peters on 2/11/21.
//

import Cocoa
import AppleScriptObjC

class ViewController: NSViewController {

    @IBOutlet weak var currentTrackLabel: NSTextField!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var refreshRateLabel: NSTextField!
    @IBOutlet weak var refreshRateSlider: NSSlider!
    
    var currentTrackTitle = ""
    var proToolsStatus = false
    var refreshRate = 1.0
    var runLoopTimer: Timer?
    var checkProToolsStatusScript = ""
    var identifyCurrentTrackScript = ""
    
    // AppleScriptObjC object for communicating with iTunes
    var scriptBridge: ScriptBridge?
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.refreshRateSlider.doubleValue = self.refreshRate
        self.refreshRateLabel.stringValue = String(format: "%.2f", self.refreshRate)
        
        // AppleScriptObjC setup
        Bundle.main.loadAppleScriptObjectiveCScripts()
        // create an instance of ScriptBridge script object for Swift code to use
        let scriptBridgeClass: AnyClass = NSClassFromString("ScriptBridge")!
        self.scriptBridge = scriptBridgeClass.alloc() as? ScriptBridge
        
        self.setupScripts()
        
        self.setTimer(interval: self.refreshRate)
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
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

    func setTimer(interval: Double) {
        self.runLoopTimer = Timer(timeInterval: interval, target: self, selector: #selector(backgroundLoop), userInfo: nil, repeats: true)
        if let timer = self.runLoopTimer {
            timer.tolerance = 0.1
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    @objc func backgroundLoop() {
        
        DispatchQueue.global(qos: .background).async {
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
            let accessEnabled = AXIsProcessTrustedWithOptions(options)
            
            if !accessEnabled {
                
                print("Access Not Enabled")
                
            } else {
                
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
        }
    }
    
    @IBAction func stopTimer(_ sender: Any) {
        if let timer = self.runLoopTimer {
            timer.invalidate()
            self.statusLabel.stringValue = "Stopped"
        }
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
