#
# Be sure to run `pod lib lint ReerRouter.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ReerRouter'
  s.version          = '0.1.3'
  s.summary          = 'A router for iOS app.'

  s.description      = <<-DESC
  App URL router for iOS (Swift only).
                       DESC

  s.homepage         = 'https://github.com/reers/ReerRouter'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'phoenix' => 'x.rhythm@qq.com' }
  s.source           = { :git => 'https://github.com/reers/ReerRouter.git', :tag => s.version.to_s }
  
  s.swift_versions = '5.5'
  s.ios.deployment_target = '10.0'

  s.source_files = 'Sources/**/*'
end
