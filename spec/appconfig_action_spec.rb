describe Fastlane::Actions::AppconfigAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The appconfig plugin is working!")

      Fastlane::Actions::AppconfigAction.run(nil)
    end
  end
end
