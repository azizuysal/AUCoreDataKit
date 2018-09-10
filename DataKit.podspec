Pod::Spec.new do |s|
s.name             = "DataKit"
s.version          = "1.0.0.0"
s.summary          = "An easy to use CoreData wrapper in Swift."
s.description      = "An easy to use CoreData wrapper in Swift. Just add your CoreData model in Xcode and you're good to go!"
s.homepage         = "https://github.com/azizuysal/DataKit"
s.license          = { :type => "MIT", :file => "LICENSE.md" }
s.author           = { "Aziz Uysal" => "azizuysal@gmail.com" }
s.social_media_url = "https://twitter.com/azizuysal"
s.source           = { :git => "https://github.com/azizuysal/DataKit.git", :tag => s.version.to_s }
s.platform         = :ios, "11.0"
s.requires_arc     = true
s.swift_version    = "4.1"

# If more than one source file: https://guides.cocoapods.org/syntax/podspec.html#source_files
s.source_files = "DataKit/DataKit/*.{swift}"

end
