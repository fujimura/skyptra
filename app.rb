require 'rubygems'
require 'sinatra'
require 'skype'
require 'json'

get '/:display/chatlist' do
  api = Skype::API.new(:display => ":" + params[:display])
  "chats: #{api.recentchats.join(', ')}"
end

post '/:display/:chat_sha/github' do
  api = Skype::API.new(:display => ":" + params[:display])
  chat_id = api.recentchats.detect{|s| s.include? params[:chat_sha]}
  chat = Skype::Chat.new(:display => ":" + params[:display], :chat_id => chat_id)
  payload = JSON.parse(params['payload'])
  header = "[GitHub commit bot] #{payload['repository']['name']} に以下のコミットがpushされました。"
  commits = payload['commits'].map do |commit|
    <<-COMMIT
    #{commit['url']}
    commit: #{commit['id']}
    Author: #{commit['author']['name']} / Date: #{commit['timestamp']}

    #{commit['message']}
   COMMIT
  end

  chat.message header + '\n' + commits.join('\n')
end

get '/ping/:display/:chat_sha' do
  api = Skype::API.new(:display => ":" + params[:display])
  chat_id = api.recentchats.detect{|s| s.include? params[:chat_sha]}
  chat = Skype::Chat.new(:display => ":" + params[:display], :chat_id => chat_id)
  chat.message 'pong'
end
