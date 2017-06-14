require "rbchat/http/adapter/js"
require "rbchat/http/adapter/xml"
require "rbchat/http/session"
require "rbchat/core"

require "rbchat/version"

# Getting uuid of QR code.
# Downloading QR code.
# Please scan the QR code to log in.
# Loading the contact, this may take a little while.
# Login successfully as

module RBChat
  def self.login
    Core.new
  end
end
