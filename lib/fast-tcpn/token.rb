module FastTCPN

  class Token
    alias orig_hash hash
    attr_reader :value, :hash, :token_id

    def initialize(value)
      @value = value
      @token_id = object_id
      @hash = orig_hash
    end

    def eql?(o)
      @token_id == o.token_id
    rescue # faster then checking for instance_of?
      false
    end

    alias == eql?

  end

end
