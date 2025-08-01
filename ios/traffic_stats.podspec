#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint hello.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'traffic_stats'
  s.version          = '0.0.1+1'
  s.summary          = 'A plugin for getting network traffic stats'
  s.description      = <<-DESC
A plugin for getting network traffic stats
                       DESC
  s.homepage         = 'https://github.com/whitecodel/traffic_stats'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'whitecodel@whitecodel.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
