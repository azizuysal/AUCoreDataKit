//
//  JsonLoadable.swift
//  DataKit
//
//  Created by Aziz Uysal on 3/22/19.
//  Copyright © 2019 Aziz Uysal. All rights reserved.
//

import Foundation
import CoreData

public protocol JsonLoadable: IDataKit where LoadableObject: JsonLoadable {
  associatedtype LoadableObject
  func loadFromJson(_ json: [AnyHashable:Any])
}

extension JsonLoadable {
  public static func insertOrUpdateOne<T: Hashable & Equatable & Comparable>(_ json: [AnyHashable:Any], in context: NSManagedObjectContext, idKey: String, idColumn: String, idType: T.Type) {
    context.performAndWait {
      let dictId = json[idKey] as! T
      let valArg = T.self is String.Type ? "@" : "d"
      let predicate = NSPredicate(format: "%K == %\(valArg)", idColumn, dictId as! CVarArg)
      var record = Self.all(in: context, predicate: predicate).first as? LoadableObject
      if record == nil {
        record = Self.new(in: context) as? LoadableObject
        record?.setValue(dictId, forKey: idColumn)
      }
      record?.loadFromJson(json)
      record?.save(in: context)
    }
  }
  
  public static func insertOrUpdateMany<T: Hashable & Equatable & Comparable>(_ json: [[AnyHashable:Any]], in context: NSManagedObjectContext, idKey: String, idColumn: String, idType: T.Type) {
    context.performAndWait {
      var input = json.sorted {
        return ($0[idKey] as! T) < ($1[idKey] as! T)
        }.makeIterator()
      var existing = Self.all(in: context, sortDescriptors: [NSSortDescriptor(key: idColumn, ascending: true)]).makeIterator()
      
      var inputDict = input.next()
      var record = existing.next()
      while let dict = inputDict {
        guard let dictId = dict[idKey] as? T else {
          inputDict = input.next()
          continue
        }
        let recordId = record?.value(forKey: idColumn) as? T
        if recordId == nil || dictId < recordId! {
          let newRecord = Self.new(in: context)
          newRecord.loadFromJson(dict)
          newRecord.save(in: context)
          inputDict = input.next()
        } else if dictId == recordId! {
          record?.loadFromJson(dict)
          record?.save(in: context)
          inputDict = input.next()
          record = existing.next()
        } else {
          record?.delete()
          record = existing.next()
        }
      }
      while let extraRecord = existing.next() {
        extraRecord.delete()
      }
    }
  }
}
