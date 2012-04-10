module Aspector
  class EventHandler
    attr_accessor :next_event_handler

    def handle_event source, event_name, priority, extras
      puts event_to_string(source, event_name, priority, extras)
      next_event_handler.handle_event(source, event_name, priority, extras) if next_event_handler
    end

    def append_event_handler event_handler
      e = self
      while e.next_event_handler
        e = e.next_event_handler
      end
      e.next_event_handler = event_handler
    end

    protected

    def event_to_string
      fields = [priority, source, event_name, extras.delete(:context), extras.delete(:method), extras.delete(:advice)]
      fields.compact!
      fields.join(' | ')
    end
  end
end

