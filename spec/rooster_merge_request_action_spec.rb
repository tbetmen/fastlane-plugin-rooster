describe Fastlane::Actions::RoosterMergeRequestAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with('The rooster plugin is working!')

      Fastlane::Actions::RoosterMergeRequestAction.run(nil)
    end
  end
end
