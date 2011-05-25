require 'lib/skype'

# list current chat ids.
get '/' do
  @recent_chats = Skype::Chat.recents
  haml :index
end

# receive commit hook from github
# :chat_hex => hex in chat id
post '/chat/:chat_hex/github' do
  @payload = JSON.parse(params['payload'])
  text = erb :github_commit
  @chat.post_message text
end

# ping
# :chat_hex => hex in chat id
get '/chat/:chat_hex/ping' do
  @chat.post_message 'pong'
  redirect '/'
end

before do
  unless ENV['DISPLAY']
    raise 'no display found. set environmental variable DISPLAY to use Skype GUI'
  end
end

before '/chat/:chat_hex/*' do
  @chat = Skype::Chat.find_by_hex(params['chat_hex']) || raise('no chat found')
end
