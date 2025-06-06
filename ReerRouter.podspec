#
# Be sure to run `pod lib lint ReerRouter.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ReerRouter'
  s.version          = '2.2.6'
  s.summary          = 'A router for iOS app.'

  s.description      = <<-DESC
  App URL router for iOS (Swift only).
                       DESC

  s.homepage         = 'https://github.com/reers/ReerRouter'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'phoenix' => 'x.rhythm@qq.com' }
  s.source           = { :git => 'https://github.com/reers/ReerRouter.git', :tag => s.version.to_s }
  
  s.swift_versions = '5.10'
  s.ios.deployment_target = '13.0'

  s.source_files = 'Sources/**/*', 'MacroPlugin/ReerRouterMacros'
  s.exclude_files = 'Sources/ReerRouterMacros'
  
  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-enable-experimental-feature SymbolLinkageMarkers -Xfrontend -load-plugin-executable -Xfrontend ${PODS_ROOT}/ReerRouter/MacroPlugin/ReerRouterMacros#ReerRouterMacros'
  }
  
  s.user_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-enable-experimental-feature SymbolLinkageMarkers -Xfrontend -load-plugin-executable -Xfrontend ${PODS_ROOT}/ReerRouter/MacroPlugin/ReerRouterMacros#ReerRouterMacros'
  }
  
  s.dependency 'SectionReader'
end
