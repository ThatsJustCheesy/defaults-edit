//
//  OpenSheetViewController.swift
//  defaults-edit
//
//  Created by Ian Gregory on 05-03-2019.
//  Copyright © 2019 Ian Gregory. All rights reserved.
//

import Cocoa

class OpenSheetViewController: NSViewController {
    
    @objc dynamic var filterString: String?
    
    @objc dynamic var appDomains: Set<DefaultsDomain> = [] {
        didSet {
            domains.formUnion(appDomains)
        }
    }
    @objc dynamic var domains: Set<DefaultsDomain> = [] {
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
        tableView.reloadData()
    }
    
    @IBAction func ok(_ sender: Any?) {
        (presentingViewController as? ViewController)?.representedObject = domainsAC.selectedObjects?.first as! DefaultsDomain
        dismiss(sender)
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
        return NSPredicate(format: "bundleIdentifier CONTAINS[cd] %@ || name CONTAINS[cd] %@", filterString, filterString)
    }
    
    @objc dynamic var domainsFilterPredicate: NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [makeIsDomainPredicate(), makeFilterMatchPredicate()])
    }
    @objc dynamic var domainsSortDescriptors: [NSSortDescriptor] {
        return [
            NSSortDescriptor(key: #keyPath(DefaultsDomain.name), ascending: true),
            NSSortDescriptor(key: "infoDictionary.CFBundleShortVersionString", ascending: false),
            NSSortDescriptor(key: "infoDictionary.CFBundleVersion", ascending: false)]
    }
    
}
