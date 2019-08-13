//
//  AppDelegate.swift
//  defaults-edit
//
//  Created by Ian Gregory on 05-03-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        showWarningAlert()
    }
    
    private let suppressWarningAlertKey: String = "SuppressLaunchWarningAlert"
    
    private func showWarningAlert() {
        if UserDefaults.standard.bool(forKey: suppressWarningAlertKey) {
            return
        }
        
        let warningAlert = NSAlert()
        warningAlert.alertStyle = .warning
        warningAlert.messageText = "Welcome to defaults-edit. Please use with care."
        warningAlert.informativeText = "defaults-edit makes it easy to view and modify user defaults on your system. While such modification can be incredibly useful, it may also be dangerous. Most applications store preference information here, and their developers have not necessarily thought about or guarded against invalid values or combinations of values. If you aren’t sure what might happen when you make a preference change, keep note of its original value, and should the application behave abnormally, change it back."
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
    
}
