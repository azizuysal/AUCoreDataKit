//
//  TableViewController.swift
//  DataKitExample
//
//  Created by Aziz Uysal on 4/19/18.
//  Copyright © 2018 Aziz Uysal. All rights reserved.
//

import UIKit
import DataKit
import CoreData

class TableViewController: UITableViewController {
  
  private let USE_FRC = false
  
  private let group = DispatchGroup()
  private let session = URLSession(configuration: .ephemeral)
  private var stories: [Story] = []
  
  private lazy var frc: NSFetchedResultsController<Story> = {
    print("creating frc")
    let sortDescriptor = NSSortDescriptor(key: "time", ascending: false)
    let frc = Story.fetchController(sortDescriptors: [sortDescriptor], cacheName: "TableViewController.storyCache")
    frc.delegate = self
    return frc
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationController?.navigationBar.prefersLargeTitles = true
    
    DataKit.configure({
      var config = DataKit.Configuration()
//      config.dbUrl = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent("test.db")
      config.shouldAddStoreAsynchronously = false
      return config
    })
    
    DataKit.loadStores { [unowned self] error in
      if error != nil {
        print("Failed to load CoreData stores")
        return
      }
      self.getNews() { error in
        print("Done loading stories")
        if let error  = error {
          print(error)
        }
        if !self.USE_FRC {
          Story.allAsync() { result in
            self.stories = result.finalResult as? [Story] ?? []
            self.tableView.reloadSections(IndexSet(integersIn: 0..<self.tableView.numberOfSections), with: .automatic)
          }
        } else {
          self.stories = self.frc.fetchedObjects ?? []
          self.tableView.reloadSections(IndexSet(integersIn: 0..<self.tableView.numberOfSections), with: .automatic)
        }
      }
    }
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//    return USE_FRC ? frc.fetchedObjects?.count ?? 0 : stories.count
    return stories.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
    configureCell(cell, at: indexPath)
    return cell!
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let cell = sender as? UITableViewCell, let index = tableView.indexPath(for: cell), let svc = segue.destination as? StoryViewController {
//      svc.story = USE_FRC ? frc.fetchedObjects?[index.row] : stories[index.row]
      svc.story = stories[index.row]
    }
  }
  
  private func configureCell(_ cell: UITableViewCell?, at indexPath: IndexPath) {
//    let story = USE_FRC ? frc.fetchedObjects?[indexPath.row] ?? Story() : stories[indexPath.row]
    let story = stories[indexPath.row]
    cell?.textLabel?.text = story.title
    if let time = story.time {
      cell?.detailTextLabel?.text = DateFormatter.localizedString(from: time as Date, dateStyle: .medium, timeStyle: .medium)
    }
  }
  
  // MARK: -
  
  typealias DownloadFinishedHandler = (_: Error?)->Void
  
  private func getNews(_ done: @escaping DownloadFinishedHandler) {
    session.dataTask(with: URL(string: "https://hacker-news.firebaseio.com/v0/topstories.json")!) { (data, response, error) in
      guard let data = data, let stories = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [Int32] else {
        print("News download failed - HTTP \((response as! HTTPURLResponse).statusCode)")
        done(error)
        return
      }
      Story.deleteAll()
      Story.execute { context in
        print("Got list of stories")
        for storyId in stories[..<40] {
          self.getStory(storyId)
        }
        self.group.notify(queue: DispatchQueue.main) {
          done(nil)
        }
      }
    }.resume()
  }
  
  private func getStory(_ id: Int32, done: DownloadFinishedHandler? = nil) {
    group.enter()
    session.dataTask(with: URL(string: "https://hacker-news.firebaseio.com/v0/item/\(id).json")!) { (data, response, error) in
      guard let data = data, let storyJson = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [AnyHashable:Any] else {
        print("Story download failed - HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        done?(error)
        self.group.leave()
        return
      }
      Story.execute { context in
        print("Saving story \(id)")
        Story.insertOrUpdateOne(storyJson, in: context, idKey: "id", idColumn: "storyId", idType: Int32.self)
        self.group.leave()
      }
    }.resume()
  }
}

extension TableViewController: NSFetchedResultsControllerDelegate {

  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    print("controllerWillChangeContent")
    tableView.beginUpdates()
  }

  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
    print("controller didChange sectionInfo")
    switch type {
    case .insert:
      tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
    case .delete:
      tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
    default:
      break
    }
  }

  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    print("controller didChange anObject")
    switch type {
    case .insert:
      tableView.insertRows(at: [newIndexPath!], with: .automatic)
    case .delete:
      tableView.deleteRows(at: [indexPath!], with: .automatic)
    case .update:
      configureCell(tableView.cellForRow(at: indexPath!), at: indexPath!)
    case .move:
      tableView.deleteRows(at: [indexPath!], with: .automatic)
      tableView.insertRows(at: [newIndexPath!], with: .automatic)
    default:
      break
    }
  }

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    print("controllerDidChangeContent")
    tableView.endUpdates()
  }
}
