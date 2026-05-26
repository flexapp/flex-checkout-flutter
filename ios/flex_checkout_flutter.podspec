Pod::Spec.new do |s|
  s.name             = 'flex_checkout_flutter'
  s.version          = '1.0.0'
  s.summary          = 'Flutter plugin for Flex Checkout SDK'
  s.description      = 'Flutter plugin wrapping the FlexCheckout native iOS SDK.'
  s.homepage         = 'https://github.com/flexapp/flex-checkout-flutter'
  s.license          = { :type => 'Proprietary', :text => 'Copyright (c) Flex. All rights reserved.' }
  s.author           = 'Flex'
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.9'

  s.dependency 'Flutter'
  s.dependency 'FlexCheckout', '~> 1.2.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
