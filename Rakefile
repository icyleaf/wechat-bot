require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

require 'wechat_bot'
require 'awesome_print'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc 'Run a sample wechat bot'
task :bot do
  bot = WeChat::Bot.new
  bot.start
end

task :test do
  bot = WeChat::Bot.new
  list = WeChat::Bot::ContactList.new(bot)

  puts list.methods
  exit

  contacts = [{"Uin"=>0, "UserName"=>"filehelper", "NickName"=>"文件传输助手", "HeadImgUrl"=>"/cgi-bin/mmwebwx-bin/webwxgeticon?seq=645600992&username=filehelper&skey=@crypt_5f613f69_3f81c273144cb6d19ca014c87784e700", "ContactFlag"=>2, "MemberCount"=>0, "MemberList"=>[], "RemarkName"=>"", "HideInputBarFlag"=>0, "Sex"=>0, "Signature"=>"", "VerifyFlag"=>0, "OwnerUin"=>0, "PYInitial"=>"WJCSZS", "PYQuanPin"=>"wenjianchuanshuzhushou", "RemarkPYInitial"=>"", "RemarkPYQuanPin"=>"", "StarFriend"=>0, "AppAccountFlag"=>0, "Statues"=>0, "AttrStatus"=>0, "Province"=>"", "City"=>"", "Alias"=>"", "SnsFlag"=>0, "UniFriend"=>0, "DisplayName"=>"", "ChatRoomId"=>0, "KeyWord"=>"fil", "EncryChatRoomId"=>"", "IsOwner"=>0}, {"Uin"=>0, "UserName"=>"@ec7caaf5a6d34b1c6de5cbf712e9a5b7", "NickName"=>"王卡助手", "HeadImgUrl"=>"/cgi-bin/mmwebwx-bin/webwxgeticon?seq=658640561&username=@ec7caaf5a6d34b1c6de5cbf712e9a5b7&skey=@crypt_5f613f69_3f81c273144cb6d19ca014c87784e700", "ContactFlag"=>3, "MemberCount"=>0, "MemberList"=>[], "RemarkName"=>"", "HideInputBarFlag"=>0, "Sex"=>0, "Signature"=>"“王卡”产品为联通定制化产品，您可畅享指定APP应用流量免费，套餐资费更优惠，王卡福利社 等多重特权！了解更多惊喜尽在“王卡助手”，更多特权等你来发现！", "VerifyFlag"=>24, "OwnerUin"=>0, "PYInitial"=>"WKZS", "PYQuanPin"=>"wangkazhushou", "RemarkPYInitial"=>"", "RemarkPYQuanPin"=>"", "StarFriend"=>0, "AppAccountFlag"=>0, "Statues"=>0, "AttrStatus"=>0, "Province"=>"广东", "City"=>"深圳", "Alias"=>"", "SnsFlag"=>0, "UniFriend"=>0, "DisplayName"=>"", "ChatRoomId"=>0, "KeyWord"=>"gh_", "EncryChatRoomId"=>"", "IsOwner"=>0}, {"Uin"=>0, "UserName"=>"filehelper", "NickName"=>"文件传输助手", "HeadImgUrl"=>"/cgi-bin/mmwebwx-bin/webwxgeticon?seq=645600992&username=filehelper&skey=@crypt_5f613f69_3f81c273144cb6d19ca014c87784e700", "ContactFlag"=>2, "MemberCount"=>0, "MemberList"=>[], "RemarkName"=>"", "HideInputBarFlag"=>0, "Sex"=>0, "Signature"=>"", "VerifyFlag"=>0, "OwnerUin"=>0, "PYInitial"=>"WJCSZS", "PYQuanPin"=>"wenjianchuanshuzhushou", "RemarkPYInitial"=>"", "RemarkPYQuanPin"=>"", "StarFriend"=>0, "AppAccountFlag"=>0, "Statues"=>0, "AttrStatus"=>0, "Province"=>"", "City"=>"", "Alias"=>"", "SnsFlag"=>0, "UniFriend"=>0, "DisplayName"=>"", "ChatRoomId"=>0, "KeyWord"=>"fil", "EncryChatRoomId"=>"", "IsOwner"=>0}, {"Uin"=>0, "UserName"=>"@0f4c761428a1b11156cc53ccbcd0c493", "NickName"=>"icyleaf<span class=\"emoji emoji1f37a\"></span>", "HeadImgUrl"=>"/cgi-bin/mmwebwx-bin/webwxgeticon?seq=620410039&username=@0f4c761428a1b11156cc53ccbcd0c493&skey=@crypt_5f613f69_3f81c273144cb6d19ca014c87784e700", "ContactFlag"=>65539, "MemberCount"=>0, "MemberList"=>[], "RemarkName"=>"", "HideInputBarFlag"=>0, "Sex"=>1, "Signature"=>"爱好户外的代码仔，下厨初心者", "VerifyFlag"=>0, "OwnerUin"=>0, "PYInitial"=>"ICYLEAFSPANCLASSEMOJIEMOJI1F37ASPAN", "PYQuanPin"=>"icyleafspanclassemojiemoji1f37aspan", "RemarkPYInitial"=>"", "RemarkPYQuanPin"=>"", "StarFriend"=>0, "AppAccountFlag"=>0, "Statues"=>0, "AttrStatus"=>37986725, "Province"=>"Rotterdam", "City"=>"", "Alias"=>"", "SnsFlag"=>49, "UniFriend"=>0, "DisplayName"=>"", "ChatRoomId"=>0, "KeyWord"=>"icy", "EncryChatRoomId"=>"", "IsOwner"=>0}]

  contacts.each do |c|
    user = WeChat::Bot::Contact.parse(c, bot)
    puts "[#{user.kind}] #{user.nickname} - #{user.username}"
  end

  all = {"BaseResponse"=>{"Ret"=>0, "ErrMsg"=>""}, "MemberCount"=>6, "MemberList"=>[{"Uin"=>0, "UserName"=>"weixin", "NickName"=>"微信团队", "HeadImgUrl"=>"/cgi-bin/mmwebwx-bin/webwxgeticon?seq=500002&username=weixin&skey=@crypt_5f613f69_3f81c273144cb6d19ca014c87784e700", "ContactFlag"=>1, "MemberCount"=>0, "MemberList"=>[], "RemarkName"=>"", "HideInputBarFlag"=>0, "Sex"=>0, "Signature"=>"微信团队官方帐号", "VerifyFlag"=>56, "OwnerUin"=>0, "PYInitial"=>"WXTD", "PYQuanPin"=>"weixintuandui", "RemarkPYInitial"=>"", "RemarkPYQuanPin"=>"", "StarFriend"=>0, "AppAccountFlag"=>0, "Statues"=>0, "AttrStatus"=>4, "Province"=>"", "City"=>"", "Alias"=>"", "SnsFlag"=>0, "UniFriend"=>0, "DisplayName"=>"", "ChatRoomId"=>0, "KeyWord"=>"wei", "EncryChatRoomId"=>"", "IsOwner"=>0}, {"Uin"=>0, "UserName"=>"@f4eaa88ed1f5b2a0a0c33b4c01e8368f", "NickName"=>"obins外设", "HeadImgUrl"=>"/cgi-bin/mmwebwx-bin/webwxgeticon?seq=639310140&username=@f4eaa88ed1f5b2a0a0c33b4c01e8368f&skey=@crypt_5f613f69_3f81c273144cb6d19ca014c87784e700", "ContactFlag"=>3, "MemberCount"=>0, "MemberList"=>[], "RemarkName"=>"", "HideInputBarFlag"=>0, "Sex"=>0, "Signature"=>"obins工程师团队为您打造的专业外设品牌！", "VerifyFlag"=>24, "OwnerUin"=>0, "PYInitial"=>"OBINSWS", "PYQuanPin"=>"obinswaishe", "RemarkPYInitial"=>"", "RemarkPYQuanPin"=>"", "StarFriend"=>0, "AppAccountFlag"=>0, "Statues"=>0, "AttrStatus"=>0, "Province"=>"江苏", "City"=>"苏州", "Alias"=>"", "SnsFlag"=>0, "UniFriend"=>0, "DisplayName"=>"", "ChatRoomId"=>0, "KeyWord"=>"gh_", "EncryChatRoomId"=>"", "IsOwner"=>0}, {"Uin"=>0, "UserName"=>"@3202677ee97ceba886b9b1410bc0b732", "NickName"=>"QQ安全中心", "HeadImgUrl"=>"/cgi-bin/mmwebwx-bin/webwxgeticon?seq=631620302&username=@3202677ee97ceba886b9b1410bc0b732&skey=@crypt_5f613f69_3f81c273144cb6d19ca014c87784e700", "ContactFlag"=>3, "MemberCount"=>0, "MemberList"=>[], "RemarkName"=>"", "HideInputBarFlag"=>0, "Sex"=>0, "Signature"=>"QQ安全中心官方微信。努力保护您的QQ安全，关键时刻及时提醒，随时掌握帐号安全动态。", "VerifyFlag"=>24, "OwnerUin"=>0, "PYInitial"=>"QQAQZX", "PYQuanPin"=>"QQanquanzhongxin", "RemarkPYInitial"=>"", "RemarkPYQuanPin"=>"", "StarFriend"=>0, "AppAccountFlag"=>0, "Statues"=>0, "AttrStatus"=>0, "Province"=>"广东", "City"=>"深圳", "Alias"=>"", "SnsFlag"=>0, "UniFriend"=>0, "DisplayName"=>"", "ChatRoomId"=>0, "KeyWord"=>"qqs", "EncryChatRoomId"=>"", "IsOwner"=>0}, {"Uin"=>0, "UserName"=>"@0f4c761428a1b11156cc53ccbcd0c493", "NickName"=>"icyleaf<span class=\"emoji emoji1f37a\"></span>", "HeadImgUrl"=>"/cgi-bin/mmwebwx-bin/webwxgeticon?seq=620410039&username=@0f4c761428a1b11156cc53ccbcd0c493&skey=@crypt_5f613f69_3f81c273144cb6d19ca014c87784e700", "ContactFlag"=>65539, "MemberCount"=>0, "MemberList"=>[], "RemarkName"=>"", "HideInputBarFlag"=>0, "Sex"=>1, "Signature"=>"爱好户外的代码仔，下厨初心者", "VerifyFlag"=>0, "OwnerUin"=>0, "PYInitial"=>"ICYLEAFSPANCLASSEMOJIEMOJI1F37ASPAN", "PYQuanPin"=>"icyleafspanclassemojiemoji1f37aspan", "RemarkPYInitial"=>"", "RemarkPYQuanPin"=>"", "StarFriend"=>0, "AppAccountFlag"=>0, "Statues"=>0, "AttrStatus"=>37986725, "Province"=>"Rotterdam", "City"=>"", "Alias"=>"", "SnsFlag"=>49, "UniFriend"=>0, "DisplayName"=>"", "ChatRoomId"=>0, "KeyWord"=>"icy", "EncryChatRoomId"=>"", "IsOwner"=>0}, {"Uin"=>0, "UserName"=>"@5957231a28bf59dd36ca0699fa393eaa", "NickName"=>"陈老宅 🍕", "HeadImgUrl"=>"/cgi-bin/mmwebwx-bin/webwxgeticon?seq=658640520&username=@5957231a28bf59dd36ca0699fa393eaa&skey=@crypt_5f613f69_3f81c273144cb6d19ca014c87784e700", "ContactFlag"=>3, "MemberCount"=>0, "MemberList"=>[], "RemarkName"=>"", "HideInputBarFlag"=>0, "Sex"=>0, "Signature"=>"我做过很多事，每一件都是喜欢的。", "VerifyFlag"=>0, "OwnerUin"=>0, "PYInitial"=>"CLZ?", "PYQuanPin"=>"chenlaozhai?", "RemarkPYInitial"=>"", "RemarkPYQuanPin"=>"", "StarFriend"=>0, "AppAccountFlag"=>0, "Statues"=>0, "AttrStatus"=>33654783, "Province"=>"", "City"=>"", "Alias"=>"", "SnsFlag"=>49, "UniFriend"=>0, "DisplayName"=>"", "ChatRoomId"=>0, "KeyWord"=>"nic", "EncryChatRoomId"=>"", "IsOwner"=>0}, {"Uin"=>0, "UserName"=>"@ec7caaf5a6d34b1c6de5cbf712e9a5b7", "NickName"=>"王卡助手", "HeadImgUrl"=>"/cgi-bin/mmwebwx-bin/webwxgeticon?seq=658640561&username=@ec7caaf5a6d34b1c6de5cbf712e9a5b7&skey=@crypt_5f613f69_3f81c273144cb6d19ca014c87784e700", "ContactFlag"=>3, "MemberCount"=>0, "MemberList"=>[], "RemarkName"=>"", "HideInputBarFlag"=>0, "Sex"=>0, "Signature"=>"“王卡”产品为联通定制化产品，您可畅享指定APP应用流量免费，套餐资费更优惠，王卡福利社 等多重特权！了解更多惊喜尽在“王卡助手”，更多特权等你来发现！", "VerifyFlag"=>24, "OwnerUin"=>0, "PYInitial"=>"WKZS", "PYQuanPin"=>"wangkazhushou", "RemarkPYInitial"=>"", "RemarkPYQuanPin"=>"", "StarFriend"=>0, "AppAccountFlag"=>0, "Statues"=>0, "AttrStatus"=>0, "Province"=>"广东", "City"=>"深圳", "Alias"=>"", "SnsFlag"=>0, "UniFriend"=>0, "DisplayName"=>"", "ChatRoomId"=>0, "KeyWord"=>"gh_", "EncryChatRoomId"=>"", "IsOwner"=>0}], "Seq"=>0}
  all["MemberList"].each do |c|
    user = WeChat::Bot::Contact.parse(c, bot)
    puts "[#{user.kind}] #{user.nickname} - #{user.username}"
  end
end
