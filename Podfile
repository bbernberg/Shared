source 'git@github.com:gamechanger/gcpodspecs.git'
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, "7.0"
workspace 'Shared'
pod 'AFNetworking'
pod 'TTTAttributedLabel', :inhibit_warnings => true
pod 'OHAttributedStringAdditions'
pod 'HTAutocompleteTextField', :inhibit_warnings => true
pod 'DDProgressView'
pod 'Reachability'
pod 'SORelativeDateTransformer'
pod 'SVProgressHUD', :inhibit_warnings => true
pod 'SVPullToRefresh'
pod 'TMCache'
pod 'Parse'
pod 'PSAlertView', :inhibit_warnings => true
pod 'FPPopover'
pod 'YRDropdownView', :inhibit_warnings => true
pod 'UIView+Helpers', :inhibit_warnings => true
pod 'MMDrawerController', '~> 0.6'
pod 'Google-API-Client', '~> 1.0', :inhibit_warnings => true
pod 'ParseUI'
pod 'JTCalendar', '~> 2.1'
pod 'GoogleMaps', '~> 1.10'
pod 'CLLocationManager-blocks', '~> 1.3'
pod 'CLImageEditor', '~> 0.1'

post_install do | installer |
  require 'fileutils'
  FileUtils.cp_r('Pods/Target Support Files/Pods/Pods-acknowledgements.plist', 'Shared/Images/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end