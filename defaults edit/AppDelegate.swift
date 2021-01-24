//
//  AppDelegate.swift
//  defaults edit
//
//  Created by Ian Gregory on 05-03-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Cocoa

/// Application delegate.
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        showWarningAlert()
    }
    
    /// Defaults key for whether the warning alert presented at first launch
    /// should be suppressed.
    private let suppressWarningAlertKey: String = "SuppressLaunchWarningAlert"
    
    /// Shows a warning alert reminding the user to be careful about modifying
    /// user defaults.
    private func showWarningAlert() {
        if UserDefaults.standard.bool(forKey: suppressWarningAlertKey) {
            return
        }
        
        let warningAlert = NSAlert()
        warningAlert.alertStyle = .warning
        warningAlert.messageText = "Welcome to defaults edit. Please use with care."
        warningAlert.informativeText = "defaults edit makes it easy to view and modify user defaults on your system. While such modification can be incredibly useful, it may also be dangerous. Most applications store preference information here, and their developers have not necessarily thought about or guarded against invalid values or combinations of values. If you aren’t sure what might happen when you make a preference change, keep note of its original value, and should the application behave abnormally, change it back."
        warningAlert.showsSuppressionButton = true
        warningAlert.layout()
        warningAlert.suppressionButton?.title = "I understand, do not show again"
        warningAlert.suppressionButton?.controlSize = .small
        warningAlert.runModal()
        if let state = warningAlert.suppressionButton?.state, state == .on {
            UserDefaults.standard.set(true, forKey: suppressWarningAlertKey)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return NSStoryboard(name: "Main", bundle: nil).instantiateInitialController() != nil
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            guard
                let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                components.scheme == "defaults-edit",
                var domain = url.host,
                let key = url.pathComponents.indices.contains(1) ? url.pathComponents[1] : nil,
                let method = url.pathComponents.indices.contains(2) ? url.pathComponents[2] : nil
            else {
                continue
            }
            
            guard
                let modifier = { () -> DefaultsModifier? in
                    switch domain {
                    case "-g", "NSGlobalDomain", "kCFPreferencesAnyApplication":
                        domain = "(global domain)"
                        return GlobalDefaults()
                    default:
                        return UserDefaults(suiteName: domain)
                    }
                }()
            else {
                continue
            }
            
            switch method {
            case "write":
                guard
                    let query = components.queryItems,
                    let typeParam = query.first(where: { $0.name == "type" })?.value,
                    let valueParam = query.first(where: { $0.name == "value" })?.value
                else {
                    break
                }
                
                confirmURLAction(editMessage: "Set ‘\(key)’ to \(valueParam) in domain \(domain)") {
                    guard
                        let type = PlistType(string: typeParam),
                        let value: AnyObject = {
                            switch type {
                            case .string:
                                return valueParam as NSString
                            case .boolean:
                                return (valueParam as NSString).boolValue as NSNumber
                            case .integer:
                                return (valueParam as NSString).integerValue as NSNumber
                            case .real:
                                return (valueParam as NSString).doubleValue as NSNumber
                            case .date:
                                // Unimplemented
                                return nil
                            case .data:
                                return NSData(hexString: valueParam)
                            case .dictionary, .array:
                                // Unimplemented
                                return nil
                            }
                        }()
                    else {
                        return
                    }
                    
                    let item = PlistItem()
                    item.key = key
                    item.type = type
                    item.value = value
                    modifier.add(item)
                    promptRestart(domain: domain)
                }
            case "delete":
                confirmURLAction(editMessage: "Delete ‘\(key)’ from domain \(domain)") {
                    modifier.removeItems(for: [key])
                    promptRestart(domain: domain)
                }
            default:
                break
            }
        }
    }
    
}

private func confirmURLAction(editMessage: String, onSuccess: @escaping () -> Void) {
    DispatchQueue.main.async {
        let alert = NSAlert()
        alert.messageText = "The following change was proposed via URL:\n\n\(editMessage)\n"
        alert.informativeText = "Only allow this if you trust the source."
        alert.addButton(withTitle: "Allow")
        alert.addButton(withTitle: "Deny")
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            onSuccess()
        default:
            break
        }
    }
}

private var terminatedObservation: NSKeyValueObservation?
private var observedApp: NSRunningApplication?
private var appTerminationQueue = DispatchQueue(label: "App termination")
private func promptRestart(domain: String) {
    DispatchQueue.main.async {
        let alert = NSAlert()
        alert.messageText = "The edit to \(domain) was successful."
        
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == domain }) {
            alert.informativeText = "Would you like to restart \(app.localizedName ?? domain) for the changes to take effect?"
            alert.addButton(withTitle: "Restart")
            alert.addButton(withTitle: "Later")
            switch alert.runModal() {
            case .alertFirstButtonReturn:
                appTerminationQueue.async {
                    let sema = DispatchSemaphore(value: 0)
                    defer {
                        sema.wait()
                    }
                    
                    observedApp = app
                    terminatedObservation = app.observe(\.isTerminated) { (app, change) in
                        terminatedObservation?.invalidate()
                        
                        if let appURL = app.bundleURL {
                            _ = try? NSWorkspace.shared.launchApplication(at: appURL, options: [.withoutActivation, .withErrorPresentation], configuration: [:])
                        } else {
                            NSWorkspace.shared.launchApplication(withBundleIdentifier: domain, options: [.withoutActivation, .withErrorPresentation], additionalEventParamDescriptor: nil, launchIdentifier: nil)
                        }
                        
                        sema.signal()
                    }
                    app.terminate()
                }
            default:
                break
            }
        } else {
            alert.runModal()
        }
    }
}
