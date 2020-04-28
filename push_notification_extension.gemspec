$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "push_notification_extension/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "push_notification_extension"
  s.version     = PushNotificationExtension::VERSION
  s.authors     = ["Anypresence"]
  s.email       = ["jbozek@anypresence.com"]
  s.homepage    = "http://www.anypresence.com"
  s.summary     = "The most awesome push notification engine in the world. THE WORLD."
  s.description = "Push notification integration for apps generated using AnyPresence's solution."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile"] + ["manifest.json"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails"
  s.add_dependency "json"
  s.add_dependency "multi_json"
  s.add_dependency "fcm"
  s.add_dependency "mongoid"
  s.add_dependency "liquid"
  s.add_dependency "simple_form"
  s.add_dependency "kaminari"

  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "factory_girl"
end
