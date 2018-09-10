//
//  StoryViewController.swift
//  DataKitExample
//
//  Created by Aziz Uysal on 9/6/18.
//  Copyright © 2018 Aziz Uysal. All rights reserved.
//

import UIKit
import WebKit

class StoryViewController: UIViewController {
  
  @IBOutlet private weak var webView: WKWebView!
  @IBOutlet private weak var loadingView: UIView!
  var story: Story!
  
  deinit {
    print("deinit")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.navigationBar.prefersLargeTitles = false
    title = story.title
    loadingView.isHidden = false
    webView.navigationDelegate = self
    if let storyUrl = story.url, let url = URL(string: storyUrl) {
      webView.load(URLRequest(url: url))
    } else {
      loadingView.isHidden = true
    }
  }
}

extension StoryViewController: WKNavigationDelegate {
  
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    loadingView.isHidden = true
  }
  
  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    loadingView.isHidden = true
  }
}
