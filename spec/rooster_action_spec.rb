describe Fastlane::Actions::RoosterAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The rooster plugin is working!")

      Fastlane::Actions::RoosterAction.run(nil)
    end
  end
end
