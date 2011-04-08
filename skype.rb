require 'rubygems'
require 'dbus'

module Skype
  class API
    attr_accessor :interface
    def initialize(options)
      if options[:display]
        ENV['DISPLAY'] = options[:display]
      else
        raise 'display number is required' if options[:display]
      end
      bus = DBus::SessionBus.instance
      service = bus.service("com.Skype.API")
      object = service.object('/com/Skype')
      object.introspect
      @interface = object["com.Skype.API"]

      # requires authorization of this app in Skype GUI.
      # see vnc and authorize app
      puts "press Yes in Skype to use this app"
      @interface.Invoke("NAME " + (options[:name] || "ruby-skype"))
      @interface.Invoke("PROTOCOL 5")
    end

    def recentchats
      format @interface.Invoke("SEARCH RECENTCHATS")
    end

  end

  class Chat < API

    attr_accessor :chat_id

    def initialize(options)
      super
      puts "recent chats:"
      recent.each_with_index do |chat, i|
        puts "  #{i+1}: #{chat}"
      end
      puts "which chat to join? (#{recent.length.times.map{|i|i+1}.join('/')})"
      index = gets.chomp
      @chat_id = recent[index.to_i-1]
    end


    def format(list)
      list.first.gsub(/^CHATS\s/, '').split(',').map(&:chomp).map(&:strip)
    end

    def message(text)
      @interface.Invoke("CHATMESSAGE #{@chat_id} #{text}")
    end
  end

end
