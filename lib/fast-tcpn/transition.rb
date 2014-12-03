module FastTCPN

  class OutputArc
    attr_reader :place, :block
    # the +block+ will be given actual binding and
    # must return token that should be put in the
    # +palce+
    def initialize(place, block)
      @place, @block = place, block
    end
  end

  class TCPNBinding
    TokenNotFound = Class.new RuntimeError

    def initialize(mapping, marking_for)
      @mapping, @marking_for = mapping, marking_for
    end

    def [](place_name)
      token = @mapping[place_name]
      if token.nil?
        raise TokenNotFound.new("No mapping for place `#{place_name}`")
      end
      marking = @marking_for[place_name]
      if marking.nil?
        raise TokenNotFound.new("No marking for place `#{place_name}`")
      end
      if token.instance_of? Array
        token.map { |t| get_new_token marking, t }
      else
        get_new_token marking, token
      end
    end

    private

    def get_new_token(marking, token)
      new_token = marking.get token
      if new_token.nil?
        raise TokenNotFound.new("There was no `#{token.inspect}` in `#{marking.inspect}`!")
      end
      new_token
    end
  end

  # This is implementation of TCPN transition.
  # It has input and output places and it can be fired.
  class Transition
    InvalidToken = Class.new RuntimeError

    class FiringError < RuntimeError
      attr_reader :cause, :transition

      def initialize(transition, cause)
        @transition, @cause = transition, cause
        set_backtrace @cause.backtrace
      end

      def inspect
        "<#{self.class} #{@cause.inspect} in transition `#{@transition.name}`>"
      end
    end

    attr_reader :name

    # Class passed to callback fired when a transition is fired.
    # Describes details of the event that caused the callback to be fired.
    Event = Struct.new(:transition, :binding, :clock, :tcpn)

    # Create new Transition.
    # +name+ identifies this transition
    # +net+ is reference to TCPN object, required to enable callback handling.
    def initialize(name, net = nil)
      @name = name
      @inputs = []
      @outputs = []
      @sentry = nil
      @net = net
    end

    # Add input arc from the +place+.
    # No inscription currently possible,
    # one token will be taken from the +place+
    # each time the transition is fired.
    def input(place)
      raise "This is not a Place object!" unless place.kind_of? Place
      @inputs << place
    end

    # Add output arc to the +place+.
    # +block+ is the arc's expresstion, it will be called while firing
    # transition. Value returned from the block will be put in output 
    # place. The block gets +binding+, and +clock+ values. +binding+ is
    # a hash with names of input places as keys nad tokens as values.
    def output(place, &block)
      raise "This is not a Place object!" unless place.kind_of? Place
      raise "Tried to define output arc without expression! Block is required!" unless block_given?
      @outputs << OutputArc.new(place, block)
    end

    # Define sentry for this transition as a block.
    # The block gets three parameters: +marking_for+, +clock+ and +result+.
    # +marking_for+ is a hash with input place names as keys and marking objects
    # as values. Thus one can iterate over tokens from specified input places. 
    # This block is supposed to push a hash of valid binding to the result like this:
    #          result << { output_place_name1 => token, output_place_name2 => token2 }
    def sentry(&block)
      @sentry = block
    end

    # fire this transition if possible
    # returns true if fired false otherwise
    def fire(clock = 0)

      # Marking is shuffled each time before it is
      # used so here we can take first found binding
      mapping = Enumerator.new do |y|
                  get_sentry.call(input_markings, clock, y)
                end.first

      return false if mapping.nil?

      tcpn_binding = TCPNBinding.new mapping, input_markings

      call_callbacks :before, Event.new(@name, tcpn_binding, clock, @net)

      tokens_for_outputs = @outputs.map do |o|
        o.block.call(tcpn_binding, clock)
      end

      mapping.each do |place_name, token|
        unless token.kind_of? Token
          t = if token.instance_of? Array
                token
              else
                [ token ]
              end
          t.each do |t|
            unless t.kind_of? Token
              raise InvalidToken.new("#{t.inspect} put by sentry for transition `#{name}` in binding for `#{place_name}`")
            end
          end
        end
        deleted = find_input(place_name).delete(token)
        if deleted.nil?
          raise InvalidToken.new("#{token.inspect} put by sentry for transition `#{name}` does not exists in `#{place_name}`")
        end
      end

      @outputs.each do |o|
        token = tokens_for_outputs.shift
        o.place.add token unless token.nil?
      end

      call_callbacks :after, Event.new(@name, mapping, clock, @net)

      true
    rescue InvalidToken
      raise
    rescue RuntimeError => e
      raise FiringError.new(self, e)
    end

    # Returns true if no custom sentry was defined for this transition.
    def default_sentry?
      @sentry.nil?
    end

    # Number of input places
    def inputs_size
      @inputs.size
    end

    # Number of output places
    def outputs_size
      @outputs.size
    end

    private

    def get_sentry
      @sentry || default_sentry
    end

    def call_callbacks(event, event_object)
      return if @net.nil?
      @net.call_callbacks(:transition, event, event_object)
    end

    def input_markings
      bnd = {}
      @inputs.each do |place|
        bnd[place.name] = place.marking
      end
      bnd
    end

    def find_input(name)
      @inputs.each do |place|
        return place if place.name == name
      end
      nil
    end

    def default_sentry
      proc do |marking_for, clock, result|
        mapping = marking_for.map do |place, marking|
          break nil if marking.first.nil?
          { place => marking.first }
        end
        unless mapping.nil?
          result << mapping.compact.reduce(:merge)
        end
      end
    end
  end

end

