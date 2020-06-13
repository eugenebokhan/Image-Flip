platform :ios, '13.2'

source 'https://cdn.cocoapods.org/'

install! 'cocoapods', :disable_input_output_paths => true
use_frameworks!
inhibit_all_warnings!

def pods
  pod 'Alloy/Shaders'
  pod 'SnapKit'
  pod 'PHAssetPicker'
  pod 'MetalView'
  pod 'SwiftGen'
end

target 'ImageFlip' do
  pods
end

target 'ImageFlipUITests' do
  pods
  pod 'SwiftSnapshotTesting'
end
