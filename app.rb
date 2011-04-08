require 'rubygems'
require 'sinatra'
require 'skype'


get '/:display/chatlist' do
  api = Skype::API.new(:display => ":" + params[:display])
  "chats: #{api.recentchats.join(', ')}"
end

get '/ping/:display/:chat_sha/:msg' do
  api = Skype::API.new(:display => ":" + params[:display])
  chat_id = api.recentchats.detect{|s| s.include? params[:chat_sha]}
  chat = Skype::Chat.new(:display => ":" + params[:display], :chat_id => chat_id)
  chat.message params[:msg]
end
