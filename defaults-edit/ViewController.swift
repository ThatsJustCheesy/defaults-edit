//
//  ViewController.swift
//  defaults-edit
//
//  Created by Ian Gregory on 05-03-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Cocoa

protocol DefaultsModifier {
    
    func add(_ item: PlistItem)
    func removeItems(for keys: Set<String>)
    func synchronize()
    
}

extension UserDefaults: DefaultsModifier {
    
    func add(_ item: PlistItem) {
        set(item.value ?? "", forKey: item.key)
    }
    
    func removeItems(for keys: Set<String>) {
        let nullMappings = keys.map { ($0, NSNull() as Any) }
        setValuesForKeys([String : Any](uniqueKeysWithValues: nullMappings))
    }
    
    func synchronize() {
        let _: Bool = synchronize()
    }
    
}

struct GlobalDefaults: DefaultsModifier {
    
    func add(_ item: PlistItem) {
        CFPreferencesSetValue(item.key as CFString, item.value as CFPropertyList, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
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

class ViewController: NSViewController {
    
    private var representedDomain: DefaultsDomain! {
        return representedObject as? DefaultsDomain
    }
    
    @objc dynamic var filterString: String? = nil {
        didSet {
            fetchVisibleDefaults()
        }
    }
    
    @objc class func keyPathsForValuesAffectingListedDefaults() -> Set<String> {
        return ["filterString"]
    }
    
    private var unfilteredListedDefaults: [String : Any] = [:] {
        didSet {
            guard let filterString = filterString else {
                listedDefaults = unfilteredListedDefaults
                return
            }
            
            let filterMatchPredicate = NSPredicate(format: "self CONTAINS[cd] %@", filterString)
            listedDefaults = unfilteredListedDefaults.filter { filterMatchPredicate.evaluate(with: $0.key) }
        }
    }
    
    @objc dynamic var listedDefaults: [String : Any] = [:] {
        didSet {
            plistEditVC?.representedObject = listedDefaults
        }
    }
    
    private var defaultsEffectiveInDomain: DefaultsModifier {
        switch representedDomain.domainName {
        case Bundle(for: ViewController.self).bundleIdentifier:
            // UserDefaults(suiteName:) does not work with own application bundle
            return UserDefaults.standard
        case UserDefaults.globalDomain:
            return GlobalDefaults()
        default:
            return UserDefaults(suiteName: representedDomain.domainName)!
        }
    }
    
    @objc dynamic var canShowEffectiveInDomain: Bool {
        return representedDomain?.domainName != UserDefaults.globalDomain
    }
    
    @objc class func keyPathsForValuesAffectingCanShowEffectiveInDomain() -> Set<String> {
        return ["representedDomain"]
    }
    
    @objc dynamic var showingDefaultsEffectiveInDomain: Bool = false {
        didSet {
            fetchVisibleDefaults()
        }
    }
    
    private func fetchVisibleDefaults() {
        if showingDefaultsEffectiveInDomain {
            fetchDefaultsEffectiveInDomain()
        } else {
            fetchDefaultsSetInDomain()
        }
    }
    
    private var cachedDefaultsSetInDomain: [String : Any]?
    
    private func fetchDefaultsSetInDomain() {
        if let cached = cachedDefaultsSetInDomain {
            unfilteredListedDefaults = cached
            return
        }
        
        plistEditVC?.startLoading()
        
        runAsynchronousDefaultsCommand(arguments: ["export", representedDomain.domainName!, "-"]) { process, data in
            if process.terminationStatus == 0 {
                self.unfilteredListedDefaults = try! PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String : Any]
            } else {
                self.unfilteredListedDefaults = [:]
            }
            self.plistEditVC?.stopLoading()
            self.cachedDefaultsSetInDomain = self.unfilteredListedDefaults
        }
    }
    
    private func fetchDefaultsEffectiveInDomain() {
        defaultsEffectiveInDomain.synchronize()
        unfilteredListedDefaults = (defaultsEffectiveInDomain as? UserDefaults)?.dictionaryRepresentation() ?? listedDefaults
    }
    
    private func clearCache() {
        cachedDefaultsSetInDomain = nil
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        showOpenSheet()
        NotificationCenter.default.addObserver(forName: NSWindow.didEndSheetNotification, object: view.window!, queue: nil) { [weak self] notification in
            if self?.representedObject == nil {
                // User canceled open sheet
                self?.view.window?.close()
            }
        }
    }
    
    override var representedObject: Any? {
        didSet {
            clearCache()
            fetchVisibleDefaults()
            
            (view.window?.windowController as? WindowController)?.representedDomain = representedDomain
            if !canShowEffectiveInDomain {
                showingDefaultsEffectiveInDomain = false
            }
            viewTypeSC.setEnabled(canShowEffectiveInDomain, forSegment: 1)
        }
    }
    
    @IBOutlet weak var viewTypeSC: NSSegmentedControl!
    
    @IBAction func openDocument(_ sender: Any?) {
        showOpenSheet()
    }
    
    @IBAction func openRecentItem(_ sender: Any?) {
        guard let sender = sender as? NSMenuItem else {
            return
        }
        representedObject = sender.representedObject
    }
    
    func showOpenSheet() {
        performSegue(withIdentifier: "ShowOpenSheet", sender: self)
    }
    
    private var plistEditVC: PlistEditViewController?
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        switch segue.destinationController {
            case let plistEditVC as PlistEditViewController:
                self.plistEditVC = plistEditVC
                plistEditVC.delegate = self
                // One-way stream (NSObject bind), self -> plist editor
                plistEditVC.bind(NSBindingName(rawValue: "representedObject"), to: self, withKeyPath: "listedDefaults", options: nil)
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
    
    func launchDefaultsCommand(arguments: [String]) -> Process {
        let process = Process()
        let processOut = Pipe()
        process.standardOutput = processOut
        
        let launchPath = "/usr/bin/defaults"
        if #available(macOS 10.13, *) {
            process.executableURL = URL(fileURLWithPath: launchPath)
        } else {
            process.launchPath = launchPath
        }
        process.arguments = arguments
        process.qualityOfService = .userInteractive
        
        if #available(macOS 10.13, *) {
            try! process.run()
        } else {
            process.launch()
        }
        return process
    }
    
    func loadExternalChanges() {
        clearCache()
        fetchVisibleDefaults()
    }
    
}
