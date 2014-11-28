module FastTCPN

  # This class extends HashMarking to support timed tokens.
  # It is however slower than not-timed version, so use it
  # if you really need it.
  class TimedHashMarking < HashMarking
    InvalidTime = Class.new RuntimeError

    attr_reader :time, :next_time

    # Create a new TimedHashMarking
    def initialize(*)
      super
      @time = 0
      @waiting = {}
      # Next time when more tokens will be available from this marking
      @next_time = 0
    end

    # Creates token with +object+ as its value and adds it to the marking.
    # if no timestamp is given, current time will be used.
    def add(object, timestamp = @time)
      if object.instance_of? Hash
        timestamp = object[:ts] || 0
        object = object[:val]
      end
      token = prepare_token(object, timestamp)
      timestamp = token.timestamp
      if timestamp > @time
        add_to_waiting token
      else
        add_token token
      end
    end

    # Set current time for the marking.
    # This will cause moving tokens from waiting to active list.
    # Putting clock back will cause error.
    def time=(time)
      if time < @time
        raise InvalidTime.new("You are trying to put back clock from #{@time} back to #{time}")
      end
      @time = time
      @waiting.keys.sort.each do |timestamp|
        if timestamp > @time
          @next_time = timestamp
          break
        end
        @waiting[timestamp].each { |token| add_token token }
        @waiting.delete timestamp
      end
      @next_time = 0 if @waiting.empty?
      @time
    end

    private

    def prepare_token(object, timestamp = 0)
      if object.instance_of? token_type
        clone object
      else
        token_type.new clone(object), timestamp
      end
    end

    def token_type
      TimedToken
    end

    def add_to_waiting(token)
      @waiting[token.timestamp] ||= []
      @waiting[token.timestamp] << token
      if @next_time == 0 || token.timestamp < @next_time
        @next_time = token.timestamp
      end
    end

  end

end
