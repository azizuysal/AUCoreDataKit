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
  
  private var frc: NSFetchedResultsController<Story>!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationController?.navigationBar.prefersLargeTitles = true
    
    DataKit.configure({
      var config = DataKit.Configuration()
      config.dbModel = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "DataModel", withExtension: "momd")!)!
      return config
    })
    
    if USE_FRC {
      let sortDescriptor = NSSortDescriptor(key: "time", ascending: false)
      frc = Story.fetchController(sortDescriptors: [sortDescriptor], cacheName: "TableViewController.storyCache")
      frc.delegate = self
    }
    
    getNews() { error in
      print("Done loading stories")
      if let error  = error {
        print(error)
      }
      if !self.USE_FRC {
        Story.allAsync() { result in
          self.stories = result.finalResult as? [Story] ?? []
          self.tableView.reloadSections(IndexSet(integersIn: 0..<self.tableView.numberOfSections), with: .automatic)
        }
      }
    }
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return stories.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
    let story = stories[indexPath.row]
    cell?.textLabel?.text = story.title
    if let time = story.time {
      cell?.detailTextLabel?.text = DateFormatter.localizedString(from: time as Date, dateStyle: .medium, timeStyle: .medium)
    }
    return cell!
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let cell = sender as? UITableViewCell, let index = tableView.indexPath(for: cell), let svc = segue.destination as? StoryViewController {
      svc.story = stories[index.row]
    }
  }
  
  // MARK: -
  
  typealias DownloadFinishedHandler = (_: Error?)->Void
  
  private func getNews(_ done: @escaping DownloadFinishedHandler) {
    session.dataTask(with: URL(string: "https://hacker-news.firebaseio.com/v0/topstories.json")!) { (data, response, error) in
      guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [Int32], let stories = json else {
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
      guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [AnyHashable:Any], let storyJson = json else {
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
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    print("controllerDidChangeContent")
    stories = frc.fetchedObjects ?? []
//    tableView.reloadSections(IndexSet(integersIn: 0..<tableView.numberOfSections), with: .automatic)
    tableView.reloadData()
  }
}

