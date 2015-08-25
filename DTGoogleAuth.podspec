Pod::Spec.new do |s|
  s.name             = "DTGoogleAuth"
  s.version          = "0.2.1"
  s.summary          = "Simple authentication with google credentials"
  s.homepage         = "https://github.com/dtorres/DTGoogleAuth"
  s.license          = 'MIT'
  s.author           = { "Diego Torres" => "contact@dtorres.me" }
  s.source           = { :git => "https://github.com/dtorres/DTGoogleAuth.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/dtorres'

  s.default_subspec = 'Core'

  s.subspec 'Core' do |ss|
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.10'
    
    ss.osx.source_files = 'Classes/DTGoogleAuth.{h,m}'
    ss.ios.source_files = 'Classes/*.{h,m}'
    ss.ios.private_header_files = 'Classes/DTSafariViewController.h'
    ss.frameworks = 'Accounts'
    ss.ios.weak_frameworks = 'WebKit', 'SafariServices'
  end
  
  s.subspec 'NoNSURLQueryItems' do |ss|
    ss.ios.deployment_target = '7.0'
    ss.osx.deployment_target = '10.9'
    ss.dependency 'CMDQueryStringSerialization'
    
    ss.osx.source_files = 'Classes/DTGoogleAuth.{h,m}'
    ss.ios.source_files = 'Classes/*.{h,m}'
    ss.ios.private_header_files = 'Classes/DTSafariViewController.h'
    ss.frameworks = 'Accounts'
    ss.ios.weak_frameworks = 'WebKit', 'SafariServices'
  end
end
