[![Language](https://img.shields.io/badge/Swift-4.1-orange.svg)](http://swift.org)
[![CocoaPods compatible](https://img.shields.io/badge/CocoaPods-compatible-brightgreen.svg)](https://cocoapods.org)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# DataKit

An easy to use CoreData wrapper in Swift.

## Requirements

DataKit requires Swift 4.1 and Xcode 9.4.

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

Configure DataKit to use the CoreData model you created in Xcode:

```swift
DataKit.configure({
    var config = DataKit.Configuration()
    config.dbModel = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "DataModel", withExtension: "momd")!)!
      return config
    })
```

And then you can start using convenient methods on your model classes to interact with core data store:

```swift
var story = Story.new()
story.title = "DataKit IS Great!"
story.save()
```

Or use JsonLoadable protocol to load data from a web api:

```swift
Story.execute { context in
    print("Saving story \(id)")
    Story.insertOrUpdateOne(storyJson, in: context, idKey: "id", idColumn: "storyId", idType: Int32.self)
}
```

Refer to the example project for more usage examples.

##License

The MIT License (MIT)
