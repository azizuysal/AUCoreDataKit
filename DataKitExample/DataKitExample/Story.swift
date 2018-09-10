//
//  Story.swift
//  DataKitExample
//
//  Created by Aziz Uysal on 4/23/18.
//  Copyright © 2018 Aziz Uysal. All rights reserved.
//

import Foundation
import DataKit

extension Story: JsonLoadable {
  public typealias LoadableObject = Story
  public func loadFromJson(_ json: [AnyHashable:Any]) {
    self.storyId = json["id"] as? Int32 ?? -1
    self.time = Date(jsonDate: json["time"]) ?? Date.distantPast
    self.title = json["title"] as? String ?? ""
    self.url = json["url"] as? String ?? ""
  }
}

fileprivate extension Date {
  init?(jsonDate: Any?) {
    guard let jsonDate = jsonDate as? Double else {
      return nil
    }
    self.init(timeIntervalSince1970: jsonDate)
  }
}
