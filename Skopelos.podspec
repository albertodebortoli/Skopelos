#
# Be sure to run `pod lib lint Skopelos.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Skopelos'
  s.version          = '2.4.0'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.summary          = 'Simply all you need for doing Core Data. Swift flavour.'
  s.description      = <<-DESC
  A minimalistic, thread safe, non-boilerplate and super easy to use version of Active Record on Core Data. Simply all you need for doing Core Data. Swift flavour.
                       DESC
  s.homepage = 'https://github.com/albertodebortoli/Skopelos'
  s.author = { 'Alberto De Bortoli' => 'albertodebortoli.website@gmail.com' }
  s.source = { :git => 'https://github.com/albertodebortoli/Skopelos.git', :tag => "#{s.version}" }

  s.homepage         = 'https://github.com/albertodebortoli/Skopelos'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Alberto De Bortoli' => 'albertodebortoli.website@gmail.com' }
  s.source           = { :git => 'https://github.com/albertodebortoli/Skopelos.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/albertodebo'

  s.module_name = 'Skopelos'
  
  s.ios.deployment_target = '10.0'
  s.watchos.deployment_target = '4.0'
  s.swift_version = '5.0'

  s.source_files = 'Skopelos/Classes/**/*'
  s.resources = 'Skopelos/Classes/**/*'
  s.frameworks = ["Foundation", "UIKit", "CoreData"]
  
end
