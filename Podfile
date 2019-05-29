def shared_pods
  pod 'AudioKit', :git => 'https://github.com/AudioKit/AudioKit.git', :branch => 'develop'
end

target 'LaunchpadKit_iOS' do
  use_frameworks!
  shared_pods
end

target 'LaunchpadKit_Mac' do
  use_frameworks!
  shared_pods
end

target 'Example' do
  use_frameworks!
  shared_pods
  pod 'MusicTheorySwift'
  pod 'MIDIEventKit'
end
