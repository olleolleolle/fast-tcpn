module FastTCPN

  class Token

    attr_reader :value

    def initialize(value)
      @value = value
      @token_id = object_id
    end

    def ==(o)
      return false unless o.kind_of? Token
      @token_id == o.token_id
    end

    protected

    def token_id
      @token_id
    end

  end

end
