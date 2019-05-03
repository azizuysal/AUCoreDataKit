//
//  DataKit.swift
//  AUCoreDataKit
//
//  Created by Aziz Uysal on 4/30/19.
//  Copyright © 2019 Aziz Uysal. All rights reserved.
//

import CoreData

extension NSManagedObject: IDataKit { public typealias CoreDataObject = NSManagedObject }

public protocol IDataKit: NSFetchRequestResult where Self: NSObject {
  associatedtype CoreDataObject where CoreDataObject: NSFetchRequestResult
  static func fetchController(in context: NSManagedObjectContext, sortDescriptors: [NSSortDescriptor], predicate: NSPredicate?, sectionNameKeyPath: String?, cacheName: String?) -> NSFetchedResultsController<CoreDataObject>
  static func count(in context: NSManagedObjectContext, predicate: NSPredicate?) -> Int
  static func all(in context: NSManagedObjectContext, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> [CoreDataObject]
  static func allAsync(in context: NSManagedObjectContext, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?, completion: @escaping NSPersistentStoreAsynchronousFetchResultCompletionBlock)
  static func new(in context: NSManagedObjectContext) -> Self
  func save(in context: NSManagedObjectContext, wait: Bool)
  static func saveAll(in context: NSManagedObjectContext, wait: Bool)
  func delete()
  static func deleteAll(in context: NSManagedObjectContext)
  static func execute(in context: NSManagedObjectContext, execute: @escaping (_ context: NSManagedObjectContext)->())
  static func executeAndWait(in context: NSManagedObjectContext, execute: @escaping (_ context: NSManagedObjectContext)->())
  static func fetchObjects(with ids: [NSManagedObjectID], in context: NSManagedObjectContext) -> [CoreDataObject]
}

extension IDataKit {
  
  public static func fetchController(in context: NSManagedObjectContext = DataKit.mainContext, sortDescriptors: [NSSortDescriptor], predicate: NSPredicate? = nil, sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> NSFetchedResultsController<Self> {
    let entityName = NSStringFromClass(self)
    let fetch = NSFetchRequest<Self>(entityName: entityName)
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
      let request = NSFetchRequest<Self>(entityName: entityName)
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
    let fetch = NSFetchRequest<Self>(entityName: entityName)
    fetch.predicate = predicate
    fetch.sortDescriptors = sortDescriptors
    fetch.returnsObjectsAsFaults = false
    
    var results = [Self]()
    let query = { (context: NSManagedObjectContext) -> () in
      do {
        results = try context.fetch(fetch)
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
    
    context.performAndWait {
      query(context)
    }
  }
  
  public static func new(in context: NSManagedObjectContext = DataKit.mainContext) -> Self {
    let entityName = NSStringFromClass(self)
    let new = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
    return new as! Self
  }
  
  public func save(in context: NSManagedObjectContext = DataKit.mainContext, wait: Bool = true) {
    context.save(wait: wait)
  }
  
  public static func saveAll(in context: NSManagedObjectContext = DataKit.mainContext, wait: Bool = true) {
    context.save(wait: wait)
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
  
  public static func execute(in context: NSManagedObjectContext = DataKit.mainContext, execute: @escaping (_ context: NSManagedObjectContext)->()) {
    context.perform {
      execute(context)
    }
  }
  
  public static func executeAndWait(in context: NSManagedObjectContext = DataKit.mainContext, execute: @escaping (_ context: NSManagedObjectContext)->()) {
    context.performAndWait {
      execute(context)
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
  
  fileprivate func save(wait: Bool) {
    let save = { (context: NSManagedObjectContext) in
      do {
        if self.hasChanges {
          try context.save()
        } else {
          print("Context did not have any changes to save")
        }
      } catch let error as NSError {
        print("Failed to save context with error: \(error)")
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
}

// MARK: -

public final class DataKit: NSObject {
  
  private static var dbName = "\(Bundle.main.infoDictionary?["CFBundleName"] ?? "data").db"
  private static var dbUrl = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent(dbName)
  private static var dbModel = NSManagedObjectModel.mergedModel(from: nil)!
  private static var excludedFromBackup = true
  private static var fileProtectionType: FileProtectionType = .completeUntilFirstUserAuthentication
  private static var shouldMigrateStoreAutomatically = true
  private static var shouldInferMappingModelAutomatically = true
  private static var shouldAddStoreAsynchronously = true
  private static var isReadOnly = false
  
  public struct Configuration {
    public var dbUrl: URL?
    public var dbModel: NSManagedObjectModel?
    public var isExcludedFromCloudBackup: Bool?
    public var fileProtectionType: FileProtectionType?
    public var shouldMigrateStoreAutomatically: Bool?
    public var shouldInferMappingModelAutomatically: Bool?
    public var shouldAddStoreAsynchronously: Bool?
    public var isReadOnly: Bool?
    public init() {}
    public init(_ config: [AnyHashable:Any]) {
      self.init()
      dbUrl = config["dbUrl"] as? URL
      dbModel = config["dbModel"] as? NSManagedObjectModel
      isExcludedFromCloudBackup = config["isExcludedFromCloudBackup"] as? Bool
      fileProtectionType = config["fileProtectionType"] as? FileProtectionType
      shouldMigrateStoreAutomatically = config["shouldMigrateStoreAutomatically"] as? Bool
      shouldInferMappingModelAutomatically = config["shouldInferMappingModelAutomatically"] as? Bool
      shouldAddStoreAsynchronously = config["shouldAddStoreAsynchronously"] as? Bool
      isReadOnly = config["isReadOnly"] as? Bool
    }
  }
  
  public class func configure(_ configuration: Configuration) {
    configure { return configuration }
  }
  public class func configure(_ configuration: @escaping ()->Configuration) {
    let config = configuration()
    if let dbUrl = config.dbUrl {
      DataKit.dbUrl = dbUrl
    }
    if let dbModel = config.dbModel {
      DataKit.dbModel = dbModel
    }
    if let excludedFromBackup = config.isExcludedFromCloudBackup {
      DataKit.excludedFromBackup = excludedFromBackup
    }
    if let fileProtectionType = config.fileProtectionType {
      DataKit.fileProtectionType = fileProtectionType
    }
    if let shouldMigrateStoreAutomatically = config.shouldMigrateStoreAutomatically {
      DataKit.shouldMigrateStoreAutomatically = shouldMigrateStoreAutomatically
    }
    if let shouldInferMappingModelAutomatically = config.shouldInferMappingModelAutomatically {
      DataKit.shouldInferMappingModelAutomatically = shouldInferMappingModelAutomatically
    }
    if let shouldAddStoreAsynchronously = config.shouldAddStoreAsynchronously {
      DataKit.shouldAddStoreAsynchronously = shouldAddStoreAsynchronously
    }
    if let isReadOnly = config.isReadOnly {
      DataKit.isReadOnly = isReadOnly
    }
  }
  
  private static var _persistentContainer: NSPersistentContainer? = nil
  private static var persistentContainer: NSPersistentContainer {
    if _persistentContainer == nil {
      _persistentContainer = createPersistentContainer()
    }
    return _persistentContainer!
  }
  
  private static func createPersistentContainer() -> NSPersistentContainer {
    let description = NSPersistentStoreDescription(url: dbUrl)
    description.shouldMigrateStoreAutomatically = shouldMigrateStoreAutomatically
    description.shouldInferMappingModelAutomatically = shouldInferMappingModelAutomatically
    description.shouldAddStoreAsynchronously = shouldAddStoreAsynchronously
    description.isReadOnly = isReadOnly
    description.setOption(fileProtectionType as NSObject, forKey: NSPersistentStoreFileProtectionKey)

    let container = NSPersistentContainer(name: dbName, managedObjectModel: dbModel)
    container.persistentStoreDescriptions = [description]
    return container
  }
  
  public static func loadStores(_ completion: @escaping (Error?) -> ()) {
    persistentContainer.loadPersistentStores { (description, error) in
      if let error = error as NSError? {
        if (error.code >= NSPersistentStoreInvalidTypeError && error.code <= NSPersistentStoreIncompatibleVersionHashError) || (error.code >= NSMigrationError && error.code <= NSExternalRecordImportError) {
          print("Failed to load persistent store with error: \(error)\nRetrying after deleting existing store ...")
          do {
            try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: description.url!, ofType: NSSQLiteStoreType, options: nil)
            return loadStores(completion)
          } catch let error {
            print("Failed to load persistent store with error: \(error)")
          }
        }
      } else {
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = excludedFromBackup
        try? description.url?.setResourceValues(resourceValues)
      }
      completion(error)
    }
  }
  
  public static var mainContext: NSManagedObjectContext {
    return persistentContainer.viewContext
  }
  
  static func newPrivateContext() -> NSManagedObjectContext {
    return persistentContainer.newBackgroundContext()
  }
  
  static func performBackgroundTask(block: @escaping (NSManagedObjectContext) -> Void) {
    persistentContainer.performBackgroundTask(block)
  }
}
