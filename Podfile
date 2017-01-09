# Needed due to
# http://stackoverflow.com/questions/33395675/cocoapods-file-reference-is-a-member-of-multiple-groups
workspace 'iosMath.xcworkspace'
project 'iosMath.xcodeproj'

install! 'cocoapods', :deterministic_uuids => false

target 'iosMathExample' do
  pod 'iosMath', :path => './'
end

target 'iosMathTests' do
  pod 'iosMath', :path => './'
end

