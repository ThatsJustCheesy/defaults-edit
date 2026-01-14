//
//  ViewController.swift
//  defaults edit
//
//  Created by Ian Gregory on 05-03-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Cocoa

/// An object capable of modifying a defaults domain.
protocol DefaultsModifier {
    
    /// Adds an item to the domain.
    ///
    /// - Parameter item: The item to add.
    func add(_ item: PlistItem)
    
    /// Removes the items with the specified keys from the domain.
    ///
    /// - Parameter keys: The keys to remove.
    func removeItems(for keys: Set<String>)
    
    /// Synchronizes the domain's state with the outside world.
    /// In particular, loads any external changes that have occurred.
    func synchronize()
    
}

struct UserDefaultsDomain: DefaultsModifier {
    let domainName: String
    private let userDefaults: UserDefaults
    
    init(domainName: String) {
        self.domainName = domainName
        self.userDefaults = UserDefaults(suiteName: domainName)!
    }
    
    func add(_ item: PlistItem) {
        let (key, value) = item.persistentRepresentation
        
        // Write using defaults command for immediate disk persistence
        writeValue(value, forKey: key)
        synchronize()
    }
    
    func removeItems(for keys: Set<String>) {
        for key in keys {
            deleteKey(key)
        }
        synchronize()
    }
    
    func synchronize() {
        // Flush cfprefsd cache to disk
        let appID = domainName as CFString
        CFPreferencesAppSynchronize(appID)
    }
    
    func dictionaryRepresentation() -> [String: Any] {
        return userDefaults.dictionaryRepresentation()
    }
    
    private func writeValue(_ value: Any?, forKey key: String) {
        guard let value = value else { return }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        
        var arguments = ["write", domainName, key]
        
        // Determine type and format value
        switch value {
        case let string as String:
            arguments += ["-string", string]
        case let number as NSNumber:
            if NSStringFromClass(type(of: number)).contains("Bool") {
                arguments += ["-bool", number.boolValue ? "true" : "false"]
            } else if NSString(string: number.stringValue).range(of: ".").location != NSNotFound {
                arguments += ["-float", number.stringValue]
            } else {
                arguments += ["-int", number.stringValue]
            }
        case let date as Date:
            arguments += ["-date", ISO8601DateFormatter().string(from: date)]
        case let data as Data:
            arguments += ["-data", data.base64EncodedString()]
        case let dict as [String: Any]:
            // For complex types, use UserDefaults then force sync
            userDefaults.set(dict, forKey: key)
            let _: Bool = userDefaults.synchronize()
            return
        case let array as [Any]:
            // For complex types, use UserDefaults then force sync
            userDefaults.set(array, forKey: key)
            let _: Bool = userDefaults.synchronize()
            return
        default:
            userDefaults.set(value, forKey: key)
            let _: Bool = userDefaults.synchronize()
            return
        }
        
        process.arguments = arguments
        try? process.run()
        process.waitUntilExit()
    }
    
    private func deleteKey(_ key: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["delete", domainName, key]
        try? process.run()
        process.waitUntilExit()
    }
}

extension UserDefaults: DefaultsModifier {
    
    func add(_ item: PlistItem) {
        let (key, value) = item.persistentRepresentation
        set(value, forKey: key)
        let _: Bool = self.synchronize()
    }
    
    func removeItems(for keys: Set<String>) {
        let nullMappings = keys.map { ($0, NSNull() as Any) }
        setValuesForKeys([String : Any](uniqueKeysWithValues: nullMappings))
        let _: Bool = self.synchronize()
    }
    
    func synchronize() {
        let _: Bool = self.synchronize()
    }
    
}

struct GlobalDefaults: DefaultsModifier {
    
    func add(_ item: PlistItem) {
        let (key, value) = item.persistentRepresentation
        CFPreferencesSetValue(key as CFString, value as CFPropertyList, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        synchronize()
    }
    
    func removeItems(for keys: Set<String>) {
        CFPreferencesSetMultiple(nil, Array(keys) as CFArray, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        synchronize()
    }
    
    func synchronize() {
        CFPreferencesSynchronize(kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
    }
    
}

/// Controls a defaults domain editor view.
class ViewController: NSViewController {
    
    /// The defaults domain represented by this editor view.
    private var representedDomain: DefaultsDomain! {
        return representedObject as? DefaultsDomain
    }
    
    /// The text typed into the filter box.
    @objc dynamic var filterString: String? = nil {
        didSet {
            refilterListedDefaults()
        }
    }
    
    /// The text typed in the filter box affects the listed defaults.
    @objc class func keyPathsForValuesAffectingListedDefaults() -> Set<String> {
        return ["filterString"]
    }
    
    /// The defaults that would appear in the listing if the filter box
    /// were blank.
    private var unfilteredListedDefaults: [String : Any] = [:] {
        didSet {
            refilterListedDefaults()
        }
    }
    
    /// Re-filters the listed defaults according to the current filter string
    /// and unfiltered list.
    private func refilterListedDefaults() {
        guard let filterString = filterString else {
            listedDefaults = unfilteredListedDefaults
            return
        }
        let filterMatchPredicate = NSPredicate(format: "self CONTAINS[cd] %@", filterString)
        listedDefaults = unfilteredListedDefaults.filter { filterMatchPredicate.evaluate(with: $0.key) }
    }
    
    /// The displayed listing of defaults.
    /// When set, this is passed to the property list editor for display.
    @objc dynamic var listedDefaults: [String : Any] = [:] {
        didSet {
            plistEditVC?.representedObject = listedDefaults
        }
    }
    
    /// An object that knows how to modify the defaults of the current domain.
    /// If the current value is an instance of `NSUserDefaults`, then that
    /// instance has a visibility of the current domain and can be used to get
    /// a list of all currently effective defaults in that domain, regardless
    /// of where they are set.
    private var defaultsEffectiveInDomain: DefaultsModifier {
        switch representedDomain.domainName {
        case Bundle(for: ViewController.self).bundleIdentifier:
            // UserDefaults(suiteName:) does not work with own application bundle
            return UserDefaults.standard
        case UserDefaults.globalDomain:
            return GlobalDefaults()
        default:
            return UserDefaultsDomain(domainName: representedDomain.domainName!)
        }
    }
    
    /// Whether the "Effective in Domain" toggle has any effect and thus
    /// should be enabled in the UI.
    @objc dynamic var canShowEffectiveInDomain: Bool {
        return representedDomain?.domainName != UserDefaults.globalDomain
    }
    
    /// The editor's represented domain affects whether the
    /// "Effective in Domain" view is available.
    @objc class func keyPathsForValuesAffectingCanShowEffectiveInDomain() -> Set<String> {
        return ["representedDomain"]
    }
    
    /// Whether the current listing shows all defaults effective in the domain,
    /// or only those set in the domain.
    @objc dynamic var showingDefaultsEffectiveInDomain: Bool = false {
        didSet {
            fetchVisibleDefaults()
        }
    }
    
    /// Re-fetches defaults from the current source.
    /// The source depends on the view mode, "Set in Domain", or
    /// "Effective in Domain".
    private func fetchVisibleDefaults() {
        if showingDefaultsEffectiveInDomain {
            fetchDefaultsEffectiveInDomain()
        } else {
            fetchDefaultsSetInDomain()
        }
    }
    
    /// A cache of defaults fetched for the "Set in Domain" view.
    private var cachedDefaultsSetInDomain: [String : Any]?
    
    /// Attempts to deserialize Data objects that contain structured data (JSON/plist)
    private func deserializeDataIfPossible(_ value: Any) -> Any {
        guard let data = value as? Data else {
            return value
        }
        
        // Try to deserialize as property list first
        if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) {
            return deserializeNestedData(plist)
        }
        
        // Try to deserialize as JSON
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            return deserializeNestedData(json)
        }
        
        // Return original data if deserialization failed
        return data
    }
    
    /// Recursively deserializes Data objects in nested structures
    private func deserializeNestedData(_ value: Any) -> Any {
        switch value {
        case let dict as [String: Any]:
            return dict.mapValues { deserializeDataIfPossible($0) }
        case let array as [Any]:
            return array.map { deserializeDataIfPossible($0) }
        default:
            return deserializeDataIfPossible(value)
        }
    }
    
    /// Re-fetches defaults for the "Set in Domain" view.
    /// This is currently accomplished with a `defaults export` command.
    private func fetchDefaultsSetInDomain() {
        if let cached = cachedDefaultsSetInDomain {
            unfilteredListedDefaults = cached
            return
        }
        
        plistEditVC?.startProgressIndicator()
        
        runAsynchronousDefaultsCommand(arguments: ["export", representedDomain.domainName!, "-"]) { process, data in
            if process.terminationStatus == 0 {
                let rawDefaults = try! PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String : Any]
                // Deserialize any Data values that contain structured data
                self.unfilteredListedDefaults = rawDefaults.mapValues { self.deserializeDataIfPossible($0) }
            } else {
                self.unfilteredListedDefaults = [:]
            }
            self.plistEditVC?.stopProgressIndicator()
            self.cachedDefaultsSetInDomain = self.unfilteredListedDefaults
        }
    }
    
    /// Re-fetches defaults for the "Effective in Domain" view.
    private func fetchDefaultsEffectiveInDomain() {
        defaultsEffectiveInDomain.synchronize()
        let rawDefaults: [String: Any]
        if let userDefaults = defaultsEffectiveInDomain as? UserDefaults {
            rawDefaults = userDefaults.dictionaryRepresentation()
        } else if let userDefaultsDomain = defaultsEffectiveInDomain as? UserDefaultsDomain {
            rawDefaults = userDefaultsDomain.dictionaryRepresentation()
        } else {
            rawDefaults = listedDefaults
        }
        // Deserialize any Data values that contain structured data
        unfilteredListedDefaults = rawDefaults.mapValues { self.deserializeDataIfPossible($0) }
    }
    
    /// Clears cached defaults so that they must be reloaded from source.
    private func clearCache() {
        cachedDefaultsSetInDomain = nil
    }
    
    /// Whether the selected domain is for an application.
    @objc dynamic var isAppDomain: Bool = false
    
    /// Updates `isAppDomain` to reflect the currently selected domain.
    private func computeIsAppDomain() {
        guard let domainName = representedDomain.domainName else {
            isAppDomain = false
            return
        }
        
        isAppDomain = (NSWorkspace.shared.urlForApplication(withBundleIdentifier: domainName) != nil)
    }
    
    private var observedApp: NSRunningApplication?
    private var terminationObservation: NSKeyValueObservation?
    
    /// When the selected domain is for an application, attempts to relaunch
    /// that application.
    @IBAction func relaunchApp(_ sender: Any?) {
        guard let domainName = representedDomain.domainName else {
            return
        }
        
        let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: domainName).first
        if let runningApp = runningApp, !runningApp.isTerminated {
            observedApp = runningApp
            terminationObservation = runningApp.observe(\.isTerminated, changeHandler: { [weak self] _, change in
                self?.terminationObservation?.invalidate()
                self?.launchApp(bundleID: domainName)
            })
            runningApp.terminate()
        } else {
            launchApp(bundleID: domainName)
        }
    }
    
    private func launchApp(bundleID: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
    
    /// Opens Finder to show the folder containing the .plist file for the current domain.
    @IBAction func revealPlistInFinder(_ sender: Any?) {
        guard let plistURL = representedDomain.preferenceFileURL else {
            let alert = NSAlert()
            alert.messageText = "Couldn't find a .plist file for this domain."
            alert.runModal()
            return
        }
        
        guard NSWorkspace.shared.selectFile(plistURL.path, inFileViewerRootedAtPath: plistURL.deletingLastPathComponent().path) else {
            let alert = NSAlert()
            alert.messageText = "Couldn't reveal in Finder."
            alert.informativeText = "Path: \(plistURL.path)"
            alert.runModal()
            return
        }
    }
    
    /// Text field for filtering the list of defaults.
    @IBOutlet weak var filterTextField: NSTextField!
    
    /// Shows the Open Defaults Domain sheet on the view's window, and closes
    /// the window if the user cancels the sheet.
    override func viewWillAppear() {
        super.viewWillAppear()
        showOpenSheet()
        NotificationCenter.default.addObserver(forName: NSWindow.didEndSheetNotification, object: view.window!, queue: nil) { [weak self] notification in
            if self?.representedObject == nil {
                // User canceled open sheet
                self?.view.window?.close()
            } else {
                self?.view.window?.makeFirstResponder(self?.filterTextField)
            }
        }
    }
    
    /// Changing the represented defaults domain via this property reloads
    /// applicable data.
    override var representedObject: Any? {
        didSet {
            clearCache()
            fetchVisibleDefaults()
            
            (view.window?.windowController as? WindowController)?.representedDomain = representedDomain
            if !canShowEffectiveInDomain {
                showingDefaultsEffectiveInDomain = false
            }
            viewTypeSC.setEnabled(canShowEffectiveInDomain, forSegment: 1)
            
            computeIsAppDomain()
        }
    }
    
    /// The segmented control used to change the view type.
    @IBOutlet weak var viewTypeSC: NSSegmentedControl!
    
    /// Responds to the "Open…" menu item by showing the Open Defaults Domain
    /// sheet.
    ///
    /// - Parameter sender: Action sender.
    @IBAction func openDocument(_ sender: Any?) {
        showOpenSheet()
    }
    
    /// Opens the recent domain specified by the sending menu item's
    /// represented object.
    ///
    /// - Parameter sender: Action sender. Should be an `NSMenuItem`.
    @IBAction func openRecentItem(_ sender: Any?) {
        guard let sender = sender as? NSMenuItem else {
            return
        }
        representedObject = sender.representedObject
    }
    
    /// Shows the Open Defaults Domain sheet over the view's window.
    func showOpenSheet() {
        performSegue(withIdentifier: "ShowOpenSheet", sender: self)
    }
    
    /// Controller for a property list editor, which implements the actual
    /// GUI. Listed defaults are forwarded to it for display. Also, this
    /// view controller is set up as its delegate for the purposes of
    /// persisting editing operations.
    private var plistEditVC: PlistEditViewController?
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        switch segue.destinationController {
            case let plistEditVC as PlistEditViewController:
                self.plistEditVC = plistEditVC
                plistEditVC.delegate = self
            case let openSheetVC as OpenSheetViewController:
                guard let representedDomain = representedDomain else { return }
                openSheetVC.previousSelection = representedDomain
            default:
                fatalError()
        }
    }
    
}

extension ViewController: PlistEditDelegate {
    
    func add(_ item: PlistItem) {
        defaultsEffectiveInDomain.add(item)
        loadExternalChanges()
    }
    
    func removeItems(for keys: Set<String>) {
        defaultsEffectiveInDomain.removeItems(for: keys)
        loadExternalChanges()
    }
    
    func itemType(for key: String) -> PlistType? {
        guard let output = runSynchronousDefaultsCommand(arguments: ["read-type", representedDomain.domainName!, key]) else {
            return nil
        }
        let mappings: [String : PlistType] = [
            "string": .string,
            "boolean": .boolean,
            "integer": .integer,
            "float": .real,
            "date": .date,
            "data": .data,
            "dictionary": .dictionary,
            "array": .array
        ]
        return mappings.first { output.contains($0.key) }?.value
    }
    
    @discardableResult
    func runSynchronousDefaultsCommand(arguments: [String]) -> String? {
        let process = launchDefaultsCommand(arguments: arguments)
        process.waitUntilExit()
        return String(data: (process.standardOutput! as AnyObject).fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
    }
    
    func runAsynchronousDefaultsCommand(arguments: [String], completion: @escaping (Process, Data) -> Void) {
        let process = launchDefaultsCommand(arguments: arguments)
        let notificationCenter = NotificationCenter.default
        var observation: Any?
        observation = notificationCenter.addObserver(forName: .NSFileHandleReadToEndOfFileCompletion, object: nil, queue: nil) { notification in
            notificationCenter.removeObserver(observation!)
            let readData = notification.userInfo![NSFileHandleNotificationDataItem] as! NSData as Data
            completion(process, readData)
        }
        (process.standardOutput! as AnyObject).fileHandleForReading.readToEndOfFileInBackgroundAndNotify()
    }
    
    /// Launches a `defaults` command with the given arguments, and returns the
    /// running process object.
    ///
    /// - Parameter arguments: The arguments to pass to the command.
    /// - Returns: The resulting (running) process.
    func launchDefaultsCommand(arguments: [String]) -> Process {
        let process = Process()
        let processOut = Pipe()
        process.standardOutput = processOut
        
        let launchPath = "/usr/bin/defaults"
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        process.qualityOfService = .userInteractive
        
        try! process.run()
        return process
    }
    
    func loadExternalChanges() {
        clearCache()
        fetchVisibleDefaults()
    }
    
}
