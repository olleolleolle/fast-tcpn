module FastTCPN
  class TCPN
    PlaceTypeDoesNotMach = Class.new RuntimeError

    class Clock
      def initialize
        @value = 0
      end

      def set(value)
        return false if value <= @value
        @value = value
        true
      end

      def get
        @value
      end

    end

    def initialize
      @places = {}
      @timed_places = {}
      @transitions = []
      @clock = Clock.new
      @callbacks = {
        transition: { before: [], after: [] },
        place: { add: [], remove: [] }
      }
    end

    def place(name, keys = {})
      create_or_find_place(name, keys, Place)
    end

    def timed_place(name, keys = {})
      place = create_or_find_place(name, keys, TimedPlace)
      @timed_places[place] = true
      place
    end

    def transition(name)
      t = @transitions.select { |t| t.name == name }.first
      if t.nil?
        t = Transition.new name, self
        @transitions << t
      end
      t
    end

    def find_place(name)
      @places[name]
    end

    def places_count
      @places.size
    end

    def transitions_count
      @transitions.size
    end

    def sim
      begin
        fired = fire_transitions
        advanced = move_clock_to find_next_time
      end while fired || advanced
    end

    def clock
      @clock.get
    end

    def cb_for(what, event = nil, &block)
      if what == :transition
        cb_for_transition event, &block
      elsif what == :place
        cb_for_place event, &block
      else
        raise InvalidCallback.new "Don't know how to add callback for #{what}"
      end
    end

    def call_callbacks(what, event, *params)
      @callbacks[what][event].each do |block|
        block.call event, *params
      end
    end


    private

    def cb_for_transition(event, &block)
      if event == :before || event.nil?
        @callbacks[:transition][:before] << block
      end
      if event == :after || event.nil?
        @callbacks[:transition][:after] << block
      end
    end

    def cb_for_place(event, &block)
      if event == :add || event.nil?
        @callbacks[:place][:add] << block
      end
      if event == :remove || event.nil?
        @callbacks[:place][:remove] << block
      end
    end

    def create_or_find_place(name, keys, type)
      place = @places[name]
      if place.nil?
        place = type.new name, keys, self
      else
        unless type == place.class
          raise PlaceTypeDoesNotMatch.new "You tried to create place #{name} of type #{type}, but it already exsists and has type #{place.class}"
        end
        place.add_keys keys
      end
      @places[name] = place
    end

    def move_clock_to(val)
      return false unless @clock.set val
      @timed_places.each_key do |place|
        place.time = val
      end
      true
    end

    def fire_transitions
      fired_count = 0
      begin
        fired = false
        @transitions.shuffle.each do |transition|
          if transition.fire clock
            fired_count += 1
            fired = true
          end
        end
      end while fired
      fired_count > 0
    end

    def find_next_time
      time = 0
      @timed_places.each_key do |place|
        next_time = place.next_time
        if next_time > clock && (time == 0 || next_time < time)
          time = next_time
        end
      end
      time
    end

  end
end
