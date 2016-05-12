#  Be sure to run `pod spec lint iosMath.podspec' to ensure this is a
Pod::Spec.new do |s|
  s.name         = "iosMath"
  s.version      = "0.6.0"
  s.summary      = "Math typesetting for iOS."
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
iosMath is a library for typesetting math formulas in iOS.
                   DESC

  s.homepage     = "https://github.com/kostub/iosMath"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Kostub Deshmukh" => "kostub@gmail.com" }
  s.platform     = :ios, "6.0"
  s.source       = { :git => "https://github.com/kostub/iosMath.git", :tag => s.version.to_s }
  s.source_files = 'iosMath/**/*'
  s.resources = "MathFontBundle/*.otf"
  s.frameworks = "CoreGraphics", "QuartzCore", "CoreText", "UIKit"
  s.requires_arc = true
end
