Pod::Spec.new do |s|
    s.name = 'Skopelos'
    s.version = '2.0.1'
    s.license = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.summary = 'Simply all you need for doing Core Data. Swift flavour.'
    s.description = 'A minimalistic, thread safe, non-boilerplate and super easy to use version of Active Record on Core Data. Simply all you need for doing Core Data. Swift flavour.'
    s.homepage = 'https://github.com/albertodebortoli/Skopelos'
    s.author = { 'Alberto De Bortoli' => 'albertodebortoli.website@gmail.com' }
    s.source = { :git => 'https://github.com/albertodebortoli/Skopelos.git', :tag => "#{s.version}" }
    s.source_files = 'Skopelos/src/**/*.{swift}'
    s.module_name = 'Skopelos'
    s.ios.deployment_target = '9.0'
    s.watchos.deployment_target = '3.0'
    s.requires_arc = true
    s.frameworks = ["Foundation", "UIKit", "CoreData"]
end

