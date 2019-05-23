# Needed due to
# http://stackoverflow.com/questions/33395675/cocoapods-file-reference-is-a-member-of-multiple-groups
workspace 'iosMath.xcworkspace'
inhibit_all_warnings!

install! 'cocoapods', :deterministic_uuids => false

target 'iosMathExample' do
  platform :ios, '11'
  project 'iosMath.xcodeproj'
  pod 'iosMath', :path => './'
end

target 'iosMathTests' do
  platform :ios, '11'
  project 'iosMath.xcodeproj'
  pod 'iosMath', :path => './'
end

target 'MacOSMath' do
  platform :osx, '10.11'
  project 'MacOSMath.xcodeproj'
  pod 'iosMath', :path => './'
end
