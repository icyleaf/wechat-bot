RSpec.describe WeChat::Bot::Contact do
  subject(:bot) { WeChat::Bot.new }

  describe "#webwxgetcontact" do
    subject(:raws) { JSON.parse(load_content("webwxgetcontact.json"))["MemberList"] }

    it "should parse speical" do
      contact = WeChat::Bot::Contact.parse(raws[0], bot)
      expect(contact.nickname).to eq('微信团队')
      expect(contact.kind).to eq(:special)
      expect(contact.special?).to be_truthy
    end

    it "should parse mp" do
      contact = WeChat::Bot::Contact.parse(raws[1], bot)
      expect(contact.nickname).to eq('obins外设')
      expect(contact.kind).to eq(:mp)
      expect(contact.mp?).to be_truthy
    end

    it "should parse user" do
      contact = WeChat::Bot::Contact.parse(raws[3], bot)
      expect(contact.nickname).to eq('用户A')
      expect(contact.kind).to eq(:user)
    end
  end

  describe "#webwxinit" do
    subject(:raws) { JSON.parse(load_content("webwxinit.json"))["ContactList"] }

    it "should parse speical" do
      contact = WeChat::Bot::Contact.parse(raws[0], bot)
      expect(contact.nickname).to eq('文件传输助手')
      expect(contact.kind).to eq(:special)
      expect(contact.special?).to be_truthy
    end

    it "should parse mp" do
      contact = WeChat::Bot::Contact.parse(raws[1], bot)
      expect(contact.nickname).to eq('王卡助手')
      expect(contact.kind).to eq(:mp)
      expect(contact.mp?).to be_truthy
    end

    it "should parse group" do
      contact = WeChat::Bot::Contact.parse(raws[4], bot)
      expect(contact.username).to eq("@@xxxxdddddxxxxxx10f3b78483e604e360ddadf34396758160d4803dd4e2")
      expect(contact.nickname).to eq('测试群聊')
      expect(contact.kind).to eq(:group)
      expect(contact.group?).to be_truthy

      expect(contact.members[0].username).to eq("@aaaaaaaaaaaaaaa")
      expect(contact.members[0].nickname).to be_empty
    end
  end

  describe "#webwxsync" do
    subject(:init_raws) { JSON.parse(load_content("webwxinit.json"))["ContactList"] }
    subject(:sync_raws) { JSON.parse(load_content("webwxsync.json"))["ModContactList"] }

    it "should update info" do
      contact = WeChat::Bot::Contact.parse(init_raws[4], bot)
      contact.update(sync_raws[0])

      expect(contact.username).to eq("@@xxxxdddddxxxxxx10f3b78483e604e360ddadf34396758160d4803dd4e2")
      expect(contact.nickname).to eq('修改测试群聊')
      expect(contact.kind).to eq(:group)
      expect(contact.group?).to be_truthy

      expect(contact.members[0].username).to eq("@aaaaaaaaaaaaaaa")
      expect(contact.members[0].nickname).to eq("icyleaf\u{1f37a}")
      expect(contact.members[0].nickname).to eq("icyleaf🍺")
    end
  end
end
