RSpec.describe WeChat::Bot::ContactList do
  subject(:bot) { WeChat::Bot.new }
  subject(:list) { WeChat::Bot::ContactList.new(bot) }
  subject(:init_raws) { JSON.parse(load_content("webwxinit.json"))["ContactList"] }
  subject(:sync_raws) { JSON.parse(load_content("webwxsync.json"))["ModContactList"] }

  it "should parse" do
    list.batch_sync(init_raws)
    expect(list.size).to eq(5)

    group = list.find(username: "@@xxxxdddddxxxxxx10f3b78483e604e360ddadf34396758160d4803dd4e2")
    expect(group.nickname).to eq("测试群聊")
  end

  it "should update with modifid or new contact" do
    list.batch_sync(init_raws)
    expect(list.size).to eq(5)

    list.batch_sync(sync_raws)
    expect(list.size).to eq(6)

    group = list.find(username: "@@xxxxdddddxxxxxx10f3b78483e604e360ddadf34396758160d4803dd4e2")
    expect(group.nickname).to eq("修改测试群聊")

    group = list.find(username: "@@yyyyyyyyyyyyyyyyyyy")
    expect(group.nickname).to eq("")
  end
end
