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

  class Transition
    InvalidToken = Class.new RuntimeError

    attr_reader :name

    def initialize(name)
      @name = name
      @inputs = []
      @outputs = []
      @sentry = default_sentry
    end

    # Add input arc from the +place+.
    # No inscruption currently possible,
    # one token will be taken from the +place+
    # each time the transition is fired.
    def input(place)
      raise "This is not a Place object!" unless place.kind_of? Place
      @inputs << place
    end

    # Add output arc to the +place+, +block+ is the
    # arcs inscription it will be given current binding
    # and should return tokens that should be put in
    # the +place+.
    def output(place, &block)
      raise "This is not a Place object!" unless place.kind_of? Place
      @outputs << OutputArc.new(place, block)
    end

    # Define sentry for this transition as a block.
    # The sentry block will be given markings of
    # all input places in the form of Hash:
    # { place_name => Array_of_tokens, ... } and
    # a result object.
    # It should push (<<) to the return object
    # subsequent valid bindings in the form of Hash with
    # { place_name => token, another_place_name => another_token }
    def sentry(&block)
      @sentry = block
    end

    # fire this transition if possible
    # returns true if fired false otherwise
    def fire(clock = 0)

      # Marking is shuffled each time before it is
      # used so here we can take first found binding
      binding = Enumerator.new do |y|
                  @sentry.call(input_markings, clock, y)
                end.first

      return false if binding.nil?

      binding.each do |place_name, token|
        unless token.kind_of? Token
          raise InvalidToken.new("#{token.inspect} put by sentry for transition `#{name}` in binding for `#{place_name}`")
        end
        deleted = find_input(place_name).delete(token)
        if deleted.nil?
          raise InvalidToken.new("#{token.inspect} put by sentry for transition `#{name}` does not exists in `#{place_name}`")
        end
      end

      @outputs.each do |o|
        token = o.block.call(binding, clock)
        o.place.add token unless token.nil?
      end
      true
    end

    private

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
        result << marking_for.map do |place, marking|
          { place => marking.first } unless marking.first.nil?
        end.reduce(:merge)
      end
    end
  end

end

