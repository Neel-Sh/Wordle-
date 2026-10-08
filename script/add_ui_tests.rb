require 'xcodeproj'

project = Xcodeproj::Project.open('Wordle.xcodeproj')
app = project.targets.find { |target| target.name == 'Wordle' }
unless project.targets.any? { |target| target.name == 'WordleUITests' }
  target = project.new_target(:ui_test_bundle, 'WordleUITests', :ios, '27.0')
  target.add_dependency(app)
  group = project.main_group.new_group('WordleUITests', 'WordleUITests')
  reference = group.new_file('EncoreUITests.swift')
  target.source_build_phase.add_file_reference(reference)
  target.build_configurations.each do |config|
    config.build_settings.merge!({
      'GENERATE_INFOPLIST_FILE' => 'YES',
      'PRODUCT_BUNDLE_IDENTIFIER' => 'com.neelsharma.encore.uitests',
      'TEST_TARGET_NAME' => 'Wordle',
      'PRODUCT_NAME' => '$(TARGET_NAME)',
      'SDKROOT' => 'iphoneos',
      'SUPPORTED_PLATFORMS' => 'iphoneos iphonesimulator',
      'TARGETED_DEVICE_FAMILY' => '1,2',
      'SWIFT_VERSION' => '5.0',
      'CODE_SIGN_STYLE' => 'Automatic',
      'DEVELOPMENT_TEAM' => 'Q672YJ8657'
    })
  end
  project.save
else
  target = project.targets.find { |item| item.name == 'WordleUITests' }
end
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.set_launch_target(app)
scheme.add_test_target(target)
scheme.save_as('Wordle.xcodeproj', 'Wordle', true)
