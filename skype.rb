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
      result = @interface.Invoke("SEARCH RECENTCHATS")
      result.first.gsub(/^CHATS\s/, '').split(',').map(&:chomp).map(&:strip)
    end

  end

  class Chat < API

    attr_accessor :chat_id

    def initialize(options)
      super
      @chat_id = options[:chat_id] || raise('no chat_id given')
    end

    def message(text)
      @interface.Invoke("CHATMESSAGE #{@chat_id} #{text}")
    end
  end

end
