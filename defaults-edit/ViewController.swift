//
//  ViewController.swift
//  defaults-edit
//
//  Created by Ian Gregory on 05-03-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @objc dynamic var filterString: String? {
        didSet {
            fetchDefaults()
        }
    }
    
    @objc class func keyPathsForValuesAffectingDefaults() -> Set<String> {
        return ["filterString"]
    }
    
    private var allDefaults: [String : Any] = [:] {
        didSet {
            guard let filterString = filterString else {
                defaults = allDefaults
                return
            }
            
            let filterMatchPredicate = NSPredicate(format: "self CONTAINS[cd] %@", filterString)
            defaults = allDefaults.filter { filterMatchPredicate.evaluate(with: $0.key) }
        }
    }
    
    @objc dynamic var defaults: [String : Any] = [:] {
        didSet {
            plistEditVC?.representedObject = defaults
        }
    }
    
    @objc dynamic var showingAllVisibleDefaults: Bool = false {
        didSet {
            fetchDefaults()
        }
    }
    
    private var representedDomain: DefaultsDomain! {
        return representedObject as? DefaultsDomain
    }
    
    private var appDefaults: UserDefaults {
        if representedDomain.bundleIdentifier == Bundle(for: ViewController.self).bundleIdentifier {
            // UserDefaults(suiteName:) does not work with own application bundle
            return UserDefaults.standard
        } else {
            return UserDefaults(suiteName: representedDomain.bundleIdentifier)!
        }
    }
    
    private func fetchDefaults() {
        if showingAllVisibleDefaults {
            fetchAllDefaults()
        } else {
            fetchDomainSpecificDefaults()
        }
    }
    
    private func clearCache() {
        cachedDomainSpecificDefaults = nil
    }
    
    private var domainSpecificDefaultsExportProcess: Process?
    private var cachedDomainSpecificDefaults: [String : Any]?
    
    private func fetchDomainSpecificDefaults() {
        if let cached = cachedDomainSpecificDefaults {
            allDefaults = cached
            return
        }
        
        plistEditVC?.startLoading()

        let process = Process()
        let processOut = Pipe()
        process.standardOutput = processOut
        let launchPath = "/usr/bin/defaults"
        if #available(macOS 10.13, *) {
            process.executableURL = URL(fileURLWithPath: launchPath)
        } else {
            process.launchPath = launchPath
        }
        process.arguments = ["export", representedDomain.bundleIdentifier!, "-"]
        process.qualityOfService = .userInteractive
        domainSpecificDefaultsExportProcess = process
        process.terminationHandler = { process in
            DispatchQueue.main.async {
                if process.terminationStatus == 0 {
                    self.allDefaults = try! PropertyListSerialization.propertyList(from: processOut.fileHandleForReading.readDataToEndOfFile(), options: [], format: nil) as! [String : Any]
                } else {
                    self.allDefaults = [:]
                }
                self.plistEditVC?.stopLoading()
                self.cachedDomainSpecificDefaults = self.allDefaults
            }
        }
        if #available(macOS 10.13, *) {
            try! process.run()
        } else {
            process.launch()
        }
    }
    
    private func fetchAllDefaults() {
        appDefaults.synchronize()
        allDefaults = appDefaults.dictionaryRepresentation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        showOpenSheet()
        NotificationCenter.default.addObserver(forName: NSWindow.didEndSheetNotification, object: view.window!, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            if !self.ensureHasRepresentedObject() { return }
            self.clearCache()
            self.fetchDefaults()
        }
    }
    
    private func ensureHasRepresentedObject() -> Bool {
        if representedObject == nil {
            view.window?.close()
            return false
        }
        return true
    }
    
    override var representedObject: Any? {
        didSet {
            (view.window?.windowController as? WindowController)?.representedDomain = representedDomain
            cachedDomainSpecificDefaults = nil
        }
    }
    
    @IBAction func openDocument(_ sender: Any?) {
        showOpenSheet()
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
                plistEditVC.bind(NSBindingName(rawValue: "representedObject"), to: self, withKeyPath: "defaults", options: nil)
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
        appDefaults.set(item.value ?? "", forKey: item.key)
        loadExternalChanges()
    }
    
    func removeItems(for keys: Set<String>) {
        let nullMappings = keys.map { ($0, NSNull() as Any) }
        appDefaults.setValuesForKeys([String : Any](uniqueKeysWithValues: nullMappings))
        loadExternalChanges()
    }
    
    func itemType(for key: String) -> PlistType? {
        let process = Process()
        let processOut = Pipe()
        process.standardOutput = processOut
        let launchPath = "/usr/bin/defaults"
        if #available(macOS 10.13, *) {
            process.executableURL = URL(fileURLWithPath: launchPath)
        } else {
            process.launchPath = launchPath
        }
        process.arguments = ["read-type", representedDomain.bundleIdentifier!, key]
        process.qualityOfService = .userInteractive
        if #available(macOS 10.13, *) {
            try! process.run()
        } else {
            process.launch()
        }
        process.waitUntilExit()
        
        guard let output = String(data: processOut.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) else {
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
    
    func loadExternalChanges() {
        clearCache()
        fetchDefaults()
    }
    
}
