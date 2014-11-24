module FastTCPN

  class Place

    Event = Struct.new(:place, :tokens, :tcpn)

    attr_reader :name

    def initialize(name, keys = {}, net = nil)
      @name = name
      @marking = HashMarking.new keys
      @net = net
    end

    def marking
      @marking
    end

    def delete(token)
      @net.call_callbacks(:place, :remove, Event.new(@name, [token], @net)) unless @net.nil?
      @marking.delete token
    end

    def add(token)
      @net.call_callbacks(:place, :add, Event.new(@name, [token], @net)) unless @net.nil?
      @marking.add token
    end

    def add_keys(keys)
      @marking.add_keys keys
    end

    def keys
      @marking.keys
    end

    def inspect
      "<#{self.class} name: #{name.inspect}>"
    end
  end

end
