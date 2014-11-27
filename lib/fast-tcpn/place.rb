module FastTCPN

  # This class imlements standard place of CPN model.
  # Marking reprezented as HashMarking object with
  # specified keys (see #new and #add_keys)
  #
  # It supports neither time nor timed tokens!
  class Place

    # Class passed to callback fired when tokens are added and/or removed from places.
    # Describes details of the event that caused the callback to be fired.
    Event = Struct.new(:place, :tokens, :tcpn)

    attr_reader :name

    # Create new Place object.
    # +name+ is unique identifier of this place
    # +keys+ are token keys used to quickly find tokens in marking (see HashMarking)
    # +net+ is reference to TCPN object, required to support callbacks
    def initialize(name, keys = {}, net = nil)
      @name = name
      @marking = HashMarking.new keys
      @net = net
    end

    # Return reference this place's marking.
    # If you modify marking using this reference, no
    # callbacks defined for places will be fired!
    def marking
      @marking
    end

    # Removes +token+ from this place
    # Callbacks defined for places will be fired
    def delete(token)
      @net.call_callbacks(:place, :remove, Event.new(@name, [token], @net)) unless @net.nil?
      @marking.delete token
    end

    # Add +token+ to this place
    # Callbacks defined for places will be fired
    def add(token)
      @net.call_callbacks(:place, :add, Event.new(@name, [token], @net)) unless @net.nil?
      @marking.add token
    end

    # Add keys that will be used to store and quickly find tokens in this place's marking.
    # see HashMarking for more info.
    def add_keys(keys)
      @marking.add_keys keys
    end

    # returns keys used to store and access tokens in this place.
    def keys
      @marking.keys
    end

    def inspect
      "<#{self.class} name: #{name.inspect}>"
    end
  end

end
