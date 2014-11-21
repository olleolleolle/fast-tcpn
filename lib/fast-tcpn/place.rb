module FastTCPN

  class Place

    attr_reader :name

    def initialize(name, keys = {})
      @name = name
      @marking = HashMarking.new keys
    end

    def marking
      @marking
    end

    def delete(token)
      @marking.delete token
    end

    def add(token)
      @marking.add token
    end

    def add_keys(keys)
      @marking.add_keys keys
    end

    def keys
      @marking.keys
    end
  end

end
