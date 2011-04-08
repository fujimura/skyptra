require 'rubygems'
require 'sinatra'
require 'skype'
require 'json'

# list current chat ids.
# :display = display number, `$ echo $DISPLAY` to know current display.
get '/:display/chatlist' do
  "chats: #{@api.recentchats.join(', ')}"
end

# receive commit hook from github
# :display = display number, `$ echo $DISPLAY` to know current display.
# :chat_hex => hex in chat id
post '/:display/:chat_hex/github' do
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

  @chat.message header + "\n" + commits.join("\n")
end

# ping
# :display = display number, `$ echo $DISPLAY` to know current display.
# :chat_hex => hex in chat id
get '/:display/:chat_hex/ping' do
  chat_id = @api.recentchats.detect{|s| s.include? params[:chat_hex]}
  @chat.message 'pong'
end

before '/:display/*' do
  @api = Skype::API.new(:display => ":" + params[:display])
end

before '/:display/:chat_hex/*' do
  chat_id = @api.recentchats.detect{|s| s.include? params[:chat_hex]}
  @chat = Skype::Chat.new(:display => ":" + params[:display], :chat_id => chat_id)
end
