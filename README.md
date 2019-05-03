[![Language](https://img.shields.io/badge/Swift-5.0-orange.svg)](http://swift.org)
[![CocoaPods compatible](https://img.shields.io/badge/CocoaPods-compatible-brightgreen.svg)](https://cocoapods.org)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Build Status](https://travis-ci.org/azizuysal/AUCoreDataKit.svg?branch=master)](https://travis-ci.org/azizuysal/AUCoreDataKit)

# DataKit

An easy to use CoreData wrapper in Swift.

## Requirements

DataKit requires Swift 5.0 and Xcode 10.2.

## Installation

### CocoaPods

You can use [CocoaPods](https://cocoapods.org) to integrate DataKit with your project.

Simply add the following line to your `Podfile`:
```ruby
pod "AUCoreDataKit"
```

And run `pod update` in your project directory.

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate NetKit into your Xcode project using Carthage, specify it in your `Cartfile`:

```yaml
github "azizuysal/AUCoreDataKit"
```

Run `carthage update` to build the framework and drag the built `DataKit.framework` into your Xcode project.

### Manually

You can integrate DataKit manually into your project simply by dragging `DataKit.framework` onto Linked Frameworks and Libraries section in Xcode.

## Usage

Optionally configure DataKit if the defaults are not suitable for your use case. DataKit automatically merges and uses CoreData models created in Xcode and uses Application name to name its database file:

```swift
DataKit.configure({
    var config = DataKit.Configuration()
    config.dbUrl = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent("test.db")
    return config
})
```

You must call this method once to load data stores for CoreData. You can start using DataKit as soon as the data stores are loaded in the callback. If there was an error, the error parameter will contain the details.
```swift
DataKit.loadStores { error in
  // your code here
}
```

Afterwards,  you can start using convenient methods on your model classes to interact with core data store:

```swift
var story = Story.new()
story.title = "DataKit IS Great!"
story.save()
```

Or use JsonLoadable protocol to load data from a web api:

```swift
Story.execute(in: DataKit.newPrivateContext()) { context in
    print("Saving story \(id)")
    Story.insertOrUpdateOne(storyJson, in: context, idKey: "id", idColumn: "storyId", idType: Int32.self)
}
```

Refer to the example project for more usage examples.

Please email me if you'd like more examples and/or additional features.

##License

The MIT License (MIT)
