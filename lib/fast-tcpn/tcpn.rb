module FastTCPN

  # This class represents TCPN model: places, transitions, arcs
  class TCPN

    PlaceTypeDoesNotMach = Class.new RuntimeError

    class Clock
      # :nodoc:

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

    # Create and return new not timed place for this model.
    #
    # If a place with this
    # name exists somewhere in the model (e.g. on other pages), and object
    # representing exisiting place will be returned. Keys of both keys will
    # be merged. For description of keys see doc for HashMarking.
    def place(name, keys = {})
      create_or_find_place(name, keys, Place)
    end

    # Create and return a new timed place for this model.
    #
    # If a place with this
    # name exists somewhere in the model (e.g. on other pages), and object
    # representing exisiting place will be returned. Keys of both keys will
    # be merged. For description of keys see doc for HashMarking.
    def timed_place(name, keys = {})
      place = create_or_find_place(name, keys, TimedPlace)
      @timed_places[place] = true
      place
    end

    # Create and return new transition for this model.
    # +name+ identifies transition in the net.
    def transition(name)
      t = find_transition name
      if t.nil?
        t = Transition.new name, self
        @transitions << t
      end
      t
    end

    # Returns place with given name for this net.
    def find_place(name)
      @places[name]
    end

    # Returns transition with given name for this net.
    def find_transition(name)
      @transitions.select { |t| t.name == name }.first
    end

    # Number of places in this net.
    def places_count
      @places.size
    end

    # Number of transitions in this net.
    def transitions_count
      @transitions.size
    end

    # Starts simulation of this net.
    def sim
      begin
        fired = fire_transitions
        advanced = move_clock_to find_next_time
      end while fired || advanced
    end

    # Returns current value of global simulation clock for this net.
    def clock
      @clock.get
    end

    # defines new callback for this net.
    # +what+ can be +transition+ of +place+ for callbacks.
    # Transition callbacks are fired when transitions are fired, place
    # callbacks when place marking changes.
    # +event+ for transition callback can be +before+ or +after+, for place,
    # can be +:add+ or +:remove+. It defines when the callbacks fill be fired.
    # If omitted, it will be called for both cases.
    #
    # Callback block for transition gets value of event tag (:before or :after)
    # and FastTCPN::Transition::Event object.
    #
    # Callback block for place gets value of event tag (:add or :remove)
    # and FastTCPN::Place::Event object.
    def cb_for(what, event = nil, &block)
      if what == :transition
        cb_for_transition event, &block
      elsif what == :place
        cb_for_place event, &block
      else
        raise InvalidCallback.new "Don't know how to add callback for #{what}"
      end
    end

    # :nodoc:
    # Calls callbacks, for internal use.
    def call_callbacks(what, event, *params)
      @callbacks[what][event].each do |block|
        block.call event, *params
      end
    end


    # OLD API, derived from tcpn gem

    # Return marking for specified place in a form of Hash:
    # { val: token_value, ts: token_timestamp }
    def marking_for(name)
      find_place(name).marking.map { |t| t.to_hash }
    end

    def add_marking_for(name, m)
      token = m
      timestamp = nil
      if m.kind_of? Hash
        token = m[:val]
        timestamp = m[:ts]
      end
      find_place(name).add token, timestamp
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
