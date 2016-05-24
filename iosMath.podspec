Pod::Spec.new do |s|
  s.name         = "iosMath"
  s.version      = "0.7.1"
  s.summary      = "Math equation rendering for iOS."
  s.description  = <<-DESC
iosMath is a library for typesetting math formulas in iOS using
CoreText. It renders formulae written in latex in a UILabel equivalent
class using the same typsetting rules as latex. This enables displaying
beautifully rendered math equations in iOS applications.
                   DESC
  s.homepage     = "https://github.com/kostub/iosMath"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Kostub Deshmukh" => "kostub@gmail.com" }
  s.platform     = :ios, "6.0"
  s.source       = { :git => "https://github.com/kostub/iosMath.git", :tag => s.version.to_s }
  s.source_files = 'iosMath/**/*.{h,m}'
  s.private_header_files = 'iosMath/render/*Internal.h', 'iosMath/render/MTFontMathTable.h'
  s.resources = "fonts/*.otf", "fonts/*.plist"
  s.frameworks = "CoreGraphics", "QuartzCore", "CoreText", "UIKit"
  s.requires_arc = true
end
