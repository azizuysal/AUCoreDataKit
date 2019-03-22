//
//  DataKit.swift
//  DataKit
//
//  Created by Aziz Uysal on 3/22/17.
//  Copyright © 2017 Aziz Uysal. All rights reserved.
//

import Foundation
import CoreData

public protocol IDataKit where Self: (NSObject & NSFetchRequestResult) {
  associatedtype DataObject: (NSObject & NSFetchRequestResult)
  static func fetchController(in context: NSManagedObjectContext, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?, sectionNameKeyPath: String?, cacheName: String?) -> NSFetchedResultsController<DataObject>
  static func count(in context: NSManagedObjectContext, predicate: NSPredicate?) -> Int
  static func all(in context: NSManagedObjectContext, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> [DataObject]
  static func allAsync(in context: NSManagedObjectContext, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?, completion: @escaping NSPersistentStoreAsynchronousFetchResultCompletionBlock)
  static func new(in context: NSManagedObjectContext) -> Self
  func save(in context: NSManagedObjectContext, wait: Bool)
  static func saveAll(in context: NSManagedObjectContext, wait: Bool)
  func delete()
  static func deleteAll(in context: NSManagedObjectContext)
  static func execute(execute: @escaping (_ context: NSManagedObjectContext)->())
  static func executeAndWait(execute: @escaping (_ context: NSManagedObjectContext)->())
  static func fetchObjects(with ids: [NSManagedObjectID], in context: NSManagedObjectContext) -> [DataObject]
}

extension IDataKit {
  
  public static func fetchController(in context: NSManagedObjectContext = DataKit.mainContext, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> NSFetchedResultsController<DataObject> {
    let entityName = (NSStringFromClass(self) as NSString).pathExtension
    let fetch = NSFetchRequest<DataObject>(entityName: entityName)
    fetch.predicate = predicate
    fetch.sortDescriptors = sortDescriptors
    let controller = NSFetchedResultsController(fetchRequest: fetch, managedObjectContext: context, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    do {
      try controller.performFetch()
    } catch {
      assert(true, "Failed to perform fetch in context with error: \(error)")
    }
    return controller
  }
  
  public static func count(in context: NSManagedObjectContext = DataKit.mainContext, predicate: NSPredicate? = nil) -> Int {
    var result = 0
    context.performAndWait {
      let entityName = NSStringFromClass(self)
      let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
      request.predicate = predicate
      request.includesSubentities = false
      do {
        result = try context.count(for: request)
      } catch let error as NSError {
        assert(true, "Failed to get count from context with error: \(error)")
      }
    }
    return result
  }
  
  public static func all(in context: NSManagedObjectContext = DataKit.mainContext, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) -> [Self] {
    let entityName = NSStringFromClass(self)
    let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
    fetch.predicate = predicate
    fetch.sortDescriptors = sortDescriptors
    fetch.returnsObjectsAsFaults = false
    
    var results = [Self]()
    let query = { (context: NSManagedObjectContext) -> () in
      do {
        results = try context.fetch(fetch) as? [Self] ?? []
      } catch let error as NSError {
        assert(true, "Failed to fetch all records in context with error: \(error)")
        results = []
      }
    }
    
    context.performAndWait {
      query(context)
    }
    return results
  }
  
  public static func allAsync(in context: NSManagedObjectContext = DataKit.mainContext, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, completion: @escaping NSPersistentStoreAsynchronousFetchResultCompletionBlock) {
    let entityName = NSStringFromClass(self)
    let fetch: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
    fetch.predicate = predicate
    fetch.sortDescriptors = sortDescriptors
    fetch.returnsObjectsAsFaults = false
    
    let asyncFetch = NSAsynchronousFetchRequest(fetchRequest: fetch, completionBlock: completion)
    
    let query = { (context: NSManagedObjectContext) -> () in
      do {
        let _ = try context.execute(asyncFetch)
      } catch let error as NSError {
        assert(true, "Failed to asynchronously fetch all records in context with error: \(error)")
      }
    }
    
    context.perform {
      query(context)
    }
  }
  
  public static func new(in context: NSManagedObjectContext = DataKit.mainContext) -> Self {
    let entityName = NSStringFromClass(self)
    let new = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
    return new as! Self
  }
  
  public func save(in context: NSManagedObjectContext = DataKit.mainContext, wait: Bool = true) {
    context.saveAll(wait: wait)
  }
  
  public static func saveAll(in context: NSManagedObjectContext = DataKit.mainContext, wait: Bool = true) {
    context.saveAll(wait: wait)
  }
  
  public func delete() {
    if let me = self as? NSManagedObject {
      me.managedObjectContext?.delete(me)
    } else {
      assert(true, "Unable to cast self to managed object")
    }
  }
  
  public static func deleteAll(in context: NSManagedObjectContext = DataKit.mainContext) {
    all(in: context).forEach {
      let obj = $0
      context.performAndWait {
        context.delete(obj as! NSManagedObject)
      }
    }
  }
  
  public static func execute(execute: @escaping (_ context: NSManagedObjectContext)->()) {
    let moc = DataKit.newBackgroundContext()
    moc.perform {
      execute(moc)
    }
  }
  
  public static func executeAndWait(execute: @escaping (_ context: NSManagedObjectContext)->()) {
    let moc = DataKit.newBackgroundContext()
    moc.performAndWait {
      execute(moc)
    }
  }
  
  public static func fetchObjects(with ids: [NSManagedObjectID], in context: NSManagedObjectContext = DataKit.mainContext) -> [Self] {
    var results = [Self]()
    for id in ids {
      let object = context.object(with: id)
      context.refresh(object, mergeChanges: true)
      results.append(object as! Self)
    }
    return results
  }
}

extension NSManagedObjectContext {
  
  private func save(wait: Bool) {
    let save = { (context: NSManagedObjectContext) in
      do {
        if self.hasChanges {
          try context.save()
        } else {
//          print("Context did not have any changes to save")
        }
      } catch let error as NSError {
        assert(true, "Failed to save context with error: \(error)")
      }
    }
    
    if wait {
      performAndWait {
        save(self)
      }
    } else {
      perform {
        save(self)
      }
    }
  }
  
//  private func saveAll() {
//    save(wait: false)
//  }
//
//  func saveAllAndWait() {
//    save(wait: true)
//    if name == "background" {
//      DataKit.mainContext.saveAllAndWait()
//    } else if name == "main" {
//      DataKit.privateContext.saveAll()
//    }
//  }
  
  func saveAll(wait: Bool) {
    save(wait: wait)
  }
}

extension NSManagedObject: IDataKit { public typealias DataObject = NSManagedObject }

// MARK: -

public final class DataKit {
  
  public enum IdType {
    case int
    case string
  }
  
  public struct Configuration {
    public var dbUrl: URL?
    public var dbModel: NSManagedObjectModel?
    public var storeOptions: [AnyHashable:Any]?
    public var isExcludedFromCloudBackup: Bool?
    public var fileProtectionType: FileProtectionType?
    public init() {}
    public init(_ config: [AnyHashable:Any]) {
      self.init()
      dbUrl = config["dbUrl"] as? URL
      dbModel = config["dbModel"] as? NSManagedObjectModel
      storeOptions = config["storeOptions"] as? [AnyHashable:Any]
      isExcludedFromCloudBackup = config["isExcludedFromCloudBackup"] as? Bool
      fileProtectionType = config["fileProtectionType"] as? FileProtectionType
    }
  }
  
  public class func configure(_ configuration: Configuration) {
    configure { return configuration }
  }
  public class func configure(_ configuration: ()->Configuration) {
    let config = configuration()
    if let dbUrl = config.dbUrl {
      DataKit.dbUrl = dbUrl
    }
    if let dbModel = config.dbModel {
      DataKit.dbModel = dbModel
    }
    if let options = config.storeOptions {
      DataKit.storeOptions = options
    }
    if let excludedFromBackup = config.isExcludedFromCloudBackup {
      DataKit.excludedFromBackup = excludedFromBackup
    }
    if let protectionType = config.fileProtectionType {
      DataKit.fileProtectionType = protectionType
    }
  }
  
  private static var dbUrl = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent("\(Bundle.main.infoDictionary!["CFBundleName"]!).db")
  private static var dbModel = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "DataModel", withExtension: "momd")!)!
  private static var storeOptions: [AnyHashable:Any] = [NSMigratePersistentStoresAutomaticallyOption:true, NSInferMappingModelAutomaticallyOption:true]
  private static var excludedFromBackup = true
  private static var fileProtectionType: FileProtectionType = .completeUntilFirstUserAuthentication
  
  private static var _dbCoordinator: NSPersistentStoreCoordinator? = nil
  private static var dbCoordinator: NSPersistentStoreCoordinator {
    if _dbCoordinator == nil {
      _dbCoordinator = createPersistentStoreCoordinator()
    }
    return _dbCoordinator!
  }
  
  private static func createPersistentStoreCoordinator() -> NSPersistentStoreCoordinator {
    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: dbModel)
    do {
      try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbUrl, options: storeOptions)
      var resourceValues = URLResourceValues()
      resourceValues.isExcludedFromBackup = excludedFromBackup
      try dbUrl.setResourceValues(resourceValues)
      try FileManager.default.setAttributes([.protectionKey : fileProtectionType], ofItemAtPath: dbUrl.path)
    } catch let error as NSError {
      assert(true, "Failed to add persistent store with error: \(error)")
      if (error.code >= NSPersistentStoreInvalidTypeError && error.code <= NSPersistentStoreIncompatibleVersionHashError) || (error.code >= NSMigrationError && error.code <= NSExternalRecordImportError) {
//        print("Retrying...")
        deleteDB()
        return createPersistentStoreCoordinator()
      }
    }
    return coordinator
  }
  
  private static var _privateContext: NSManagedObjectContext? = nil
  fileprivate static var privateContext: NSManagedObjectContext {
    if _privateContext == nil {
      let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
      context.persistentStoreCoordinator = dbCoordinator
      context.name = "private"
      _privateContext = context
    }
    return _privateContext!
  }
  
  private static var _mainContext: NSManagedObjectContext? = nil
  public static var mainContext: NSManagedObjectContext {
    if _mainContext == nil {
      let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
      context.parent = privateContext
      context.name = "main"
      context.automaticallyMergesChangesFromParent = true
      _mainContext = context
    }
    return _mainContext!
  }
  
  fileprivate class func newBackgroundContext() -> NSManagedObjectContext {
    let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    context.parent = mainContext
    context.name = "background"
    context.automaticallyMergesChangesFromParent = true
    return context
  }
  
  public static func deleteDB() {
//    print("Deleting database")
    let db = dbUrl.deletingPathExtension()
    try? FileManager.default.removeItem(at: db.appendingPathExtension("db"))
    try? FileManager.default.removeItem(at: db.appendingPathExtension("db-shm"))
    try? FileManager.default.removeItem(at: db.appendingPathExtension("db-wal"))
    _dbCoordinator = nil
    _privateContext = nil
    _mainContext = nil
  }
}
