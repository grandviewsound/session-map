//
//  ViewController.swift
//  Session Map
//
//  Created by Kevin Peters on 2/11/21.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var currentTrackLabel: NSTextField!
    
    var currentTrackTitle = "hello world"
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    

    
    @IBAction func runAppleScript(_ sender: Any) {
        
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            
            print("Access Not Enabled")
            
        } else {
            
            var error: NSDictionary?
            
            //            let path = Bundle.main.path(forResource: "TC Script", ofType: "scpt")
            //            let url = URL(fileURLWithPath: path!)
            // If you wanted to us a script file instead
            //            if let appleScript = NSAppleScript(contentsOf: url, error: &error) {
            //                let outputString: NSAppleEventDescriptor = appleScript.executeAndReturnError(&error)
            //                print(outputString)
            //            }
            
            let appleScript = """

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
                            set the clipboard to formattedString

                        end tell
                    end tell
                end if
            end tell

            """
            
            
            if let scriptObject = NSAppleScript(source: appleScript) {
                if let outputString = scriptObject.executeAndReturnError(&error).stringValue {
                    print(outputString)
                } else if (error != nil) {
                    print("error: ", error!)
                }
            }
            
        }
        
        
        //self.setCurrentTrackLabel(appendedString: currentTrackTitle)
        //self.currentTrackTitle = String(NSPasteboard.general.string)
        let pasteboardString: String? = NSPasteboard.general.string(forType: .string)
        if let tempString = pasteboardString {
            self.currentTrackTitle = tempString
        }
        print(currentTrackTitle)
        DispatchQueue.main.async { [unowned self] in
            self.currentTrackLabel.stringValue = currentTrackTitle
        }
        
        
        
        
        
    }
    
    
    func setCurrentTrackLabel(appendedString: String) {
        
        self.currentTrackLabel.stringValue = appendedString
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
}

