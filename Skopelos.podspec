Pod::Spec.new do |s|
	s.name = 'Skopelos'
	s.version = '2.0.0-je'
    s.license = { :type => 'Apache 2.0', :file => 'LICENSE' }
	s.summary = 'Simply all you need for doing Core Data. Swift flavour.'
	s.description = 'A minimalistic, thread safe, non-boilerplate and super easy to use version of Active Record on Core Data. Simply all you need for doing Core Data. Swift flavour.'
	s.homepage = 'https://github.com/justeat/Skopelos'
	s.author = 'Just Eat'
	s.source = { :git => 'https://github.com/justeat/Skopelos.git', :tag => "#{s.version}" }
	s.source_files = 'Skopelos/src/**/*.{swift}'
	s.module_name = 'Skopelos'
	s.ios.deployment_target = '9.0'
    s.watchos.deployment_target = '3.0'
	s.requires_arc = true
	s.frameworks = ["Foundation", "CoreData"]
end

