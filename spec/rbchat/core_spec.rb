RSpec.describe RBChat::Core do
  subject { RBChat::Core.new }

  describe ".qr_uuid" do
    before do
      stub_qr_uuid
      @uuid = subject.qr_uuid
    end

    it "should return uuid" do
      expect(@uuid).to eq("YbvryPcSTw==")
    end
  end
end
