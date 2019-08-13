//
//  OpenSheetViewController.swift
//  defaults-edit
//
//  Created by Ian Gregory on 05-03-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Cocoa

class OpenSheetViewController: NSViewController {
    
    /// Enables termination while this controller is presented as a sheet.
    /// Closes all Open sheets in the application, then attempts to really
    /// terminate.
    ///
    /// - Parameter sender: Action sender.
    @IBAction func terminate(_ sender: Any?) {
        let application = NSApplication.shared
        guard (application.delegate?.applicationShouldTerminate?(application) ?? .terminateNow) == .terminateNow else {
            return
        }
        
        for window in NSApplication.shared.orderedWindows {
            if
                let sheet = window.attachedSheet,
                sheet.contentViewController is OpenSheetViewController
            {
                window.endSheet(sheet)
            }
        }
        NSApplication.shared.terminate(sender)
    }
    
    @objc dynamic var filterString: String?
    
    @objc dynamic var appDomains: Set<DefaultsDomain> = [] {
        didSet {
            let domainsToMerge = appDomains.filter { !domains.contains($0) }
            domains.formUnion(domainsToMerge)
        }
    }
    @objc dynamic var domains: Set<DefaultsDomain> = [.init(globalDomain: ())] {
        didSet {
            selectPreviousSelection()
        }
    }
    @IBOutlet var domainsAC: NSArrayController!
    @IBOutlet var tableView: NSTableView!
    
    @objc dynamic var previousSelection: DefaultsDomain?
    
    override func viewDidLoad() {
        bindQueryResults()
        query.start()
        fetchOtherDomains()
    }
    
    override func viewWillAppear() {
        tableView.reloadData()
    }
    
    @IBAction func ok(_ sender: Any?) {
        open(domain: domainsAC.selectedObjects?.first as! DefaultsDomain)
    }
    
    @IBAction func openRecentItem(_ sender: Any?) {
        guard let sender = sender as? NSMenuItem else {
            return
        }
        open(domain: sender.representedObject as! DefaultsDomain)
    }
    
    private func open(domain: DefaultsDomain) {
        (presentingViewController as? ViewController)?.representedObject = domain
        dismiss(self)
    }
    
    deinit {
        query.stop()
    }
    
    private class QueryDelegate: NSObject, NSMetadataQueryDelegate {
        func metadataQuery(_ query: NSMetadataQuery, replacementObjectForResultObject result: NSMetadataItem) -> Any {
            let path = result.value(forAttribute: NSMetadataItemPathKey) as! String
            return DefaultsDomain(bundle: Bundle(path: path) ?? Bundle(for: OpenSheetViewController.self))
        }
    }
    private static let queryDelegate = QueryDelegate()
    
    private static func makeDefaultQuery() -> NSMetadataQuery {
        let query = NSMetadataQuery()
        query.delegate = queryDelegate
        query.searchScopes = FileManager.default.urls(for: .allApplicationsDirectory, in: .allDomainsMask)
        query.predicate = NSPredicate(format: "kMDItemKind == 'Application'")
        return query
    }
    
    @objc dynamic let query: NSMetadataQuery! = makeDefaultQuery()
    
    private func bindQueryResults() {
        class ArrayToSetTransformer: ValueTransformer {
            override func transformedValue(_ value: Any?) -> Any? {
                guard let array = value as? Array<AnyHashable> else {
                    return value
                }
                return Set<AnyHashable>(array)
            }
        }
        
        bind(NSBindingName(rawValue: #keyPath(OpenSheetViewController.appDomains)), to: query!, withKeyPath: #keyPath(NSMetadataQuery.results), options: [NSBindingOption.valueTransformerName: NSStringFromClass(ArrayToSetTransformer.self)])
    }
    
    private func fetchOtherDomains() {
        let process = Process()
        let processOut = Pipe()
        process.standardOutput = processOut
        let launchPath = "/usr/bin/defaults"
        if #available(macOS 10.13, *) {
            process.executableURL = URL(fileURLWithPath: launchPath)
        } else {
            process.launchPath = launchPath
        }
        process.arguments = ["domains"]
        process.qualityOfService = .userInitiated
        if #available(macOS 10.13, *) {
            try! process.run()
        } else {
            process.launch()
        }
        process.waitUntilExit()
        if process.terminationStatus == 0 {
            domains.formUnion(String(data: processOut.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)!.components(separatedBy: ", ").map { DefaultsDomain(domainName: String($0)) })
        }
    }
    
    private func selectPreviousSelection() {
        guard
            let previousSelection = previousSelection,
            let arrangedDomains = [DefaultsDomain]?((domainsAC.arrangedObjects as! NSArray) as! [DefaultsDomain]),
            let index = arrangedDomains.firstIndex(where: { $0.bundlePath == previousSelection.bundlePath })
        else {
            return
        }
        domainsAC.setSelectionIndex(arrangedDomains.distance(from: arrangedDomains.startIndex, to: index))
    }
    
    @objc class func keyPathsForValuesAffectingDomainsFilterPredicate() -> Set<String> {
        return ["filterString"]
    }
    
    private func makeIsDomainPredicate() -> NSPredicate {
        return NSPredicate(block: { (object, _) -> Bool in
            return object is DefaultsDomain
        })
    }
    private func makeFilterMatchPredicate() -> NSPredicate {
        guard let filterString = filterString, filterString != "" else {
            return NSPredicate(value: true)
        }
        return NSPredicate(format: "domainName CONTAINS[cd] %@ || localizedName CONTAINS[cd] %@", filterString, filterString)
    }
    
    @objc dynamic var domainsFilterPredicate: NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [makeIsDomainPredicate(), makeFilterMatchPredicate()])
    }
    @objc dynamic var domainsSortDescriptors: [NSSortDescriptor] {
        return [
            NSSortDescriptor(key: #keyPath(DefaultsDomain.domainName), ascending: false, comparator: { (name1, name2) -> ComparisonResult in
                switch (name1 as! String, name2 as! String) {
                    case (UserDefaults.globalDomain, _):
                        return .orderedDescending
                    case (_, UserDefaults.globalDomain):
                        return .orderedAscending
                    default:
                        return .orderedSame
                }
            }),
            NSSortDescriptor(key: #keyPath(DefaultsDomain.localizedName), ascending: true),
            NSSortDescriptor(key: "infoDictionary.CFBundleShortVersionString", ascending: false),
            NSSortDescriptor(key: "infoDictionary.CFBundleVersion", ascending: false)]
    }
    
}
