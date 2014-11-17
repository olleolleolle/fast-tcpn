module FastTCPN

  class Token

    attr_reader :value

    def initialize(value)
      @value = value
      @token_id = object_id
    end

    def eql?(o)
      @token_id == o.token_id
    rescue # faster then checking for instance_of?
      false
    end

    alias == eql?

    def hash
      @token_id
    end

    protected

    def token_id
      @token_id
    end

  end

end
