module Skype
  class API
    attr_accessor :interface
    def initialize(options = {})
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
      @interface.Invoke("NAME " + (options[:name] || "ruby-skype"))
      @interface.Invoke("PROTOCOL 5")
    end

  end

  class SkypeObject
    @@interface = Skype::API.new.interface
    @@class_mapping = {}

    attr_accessor :id

    def initialize(id)
      @id = id

      self.class::PROPERTIES.each do |property|
        class_eval do
          define_method(property.downcase) do
            get(property)
          end
        end
      end
    end

    def self.make(properties, object)
      properties.each do |property|
        @@class_mapping[property] = object
      end
    end

    def get(object)
      object_name = self.class.name.split(/::/).last.upcase
      query = "#{object_name} #{@id} #{object}"
      result = @@interface.Invoke("GET " + query).to_s.gsub(query, '').strip

      # return array for plulal property
      if object[-1, 1] == 'S'
        split_with_object_type(object, result).map do |r|
          if @@class_mapping[object]
            Skype.const_get(@@class_mapping[object]).new(r)
          else
            r
          end
        end
      else
        if @@class_mapping[object]
          Skype.const_get(@@class_mapping[object]).new(result)
        else
          result
        end
      end

    end

    private
    def split_with_object_type(object, string)
      splitter = case object
                 when 'MEMBERS'
                   ' '
                 when 'ACTIVEMEMBERS'
                   ' '
                 when /S$/
                   ', '
                 end
      string.split splitter
    end

  end

  class Chat < SkypeObject
    PROPERTIES = %w(NAME TIMESTAMP ADDER STATUS POSTERS MEMBERS TOPIC CHATMESSAGES ACTIVEMEMBERS FRIENDLYNAME RECENTCHATMESSAGES)
    make %w(CHATMESSAGES RECENTCHATMESSAGES), 'ChatMessage'

    attr_accessor :id

    def self.find_by_hex(hex)
      recents.detect do |chat|
        chat.id.include? hex
      end
    end

    def self.recents
      result = @@interface.Invoke("SEARCH RECENTCHATS")
      result.first.gsub(/^CHATS\s/, '').split(', ').map do |chat_id|
        self.new chat_id
      end
    end

    def hex
      self.id[/[a-z0-9]*$/]
    end

    def post_message(text)
      @@interface.Invoke("CHATMESSAGE #{@id} #{text}")
    end

  end

  class ChatMessage < SkypeObject
    PROPERTIES = %w(CHATNAME TIMESTAMP FROM_HANDLE FROM_DISPNAME TYPE USERS LEAVEREASON BODY STATUS)
  end

end
