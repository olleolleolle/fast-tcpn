module FastTCPN

  class HashMarking
    InvalidToken = Class.new RuntimeError
    CannotAddKeys = Class.new RuntimeError

    attr_reader :keys

    # Creates new HashMarking with specified keys. At least
    # one key must be specified. The keys are used to
    # store tokens in Hashes -- one hash for each key. Thus
    # finding tokens by the keys is fast.
    def initialize(keys)
      @keys = keys
      @lists = {}
    end

    def add_keys(keys)
      unless empty?
        raise CannotAddKeys.new("marking not empty!");
      end
      @keys.merge!(keys)
    end

    def empty?
      size == 0
    end

    # Creates new token of the +object+ and 
    # adds it to the marking
    def add(object)
      token = Token.new clone(object)
      each_key_with(token) do |key_name, value|
        @lists[key_name] ||= {}
        @lists[key_name][value] ||= []
        @lists[key_name][value] << token
      end
    end

    # Deletes the +token+ from the marking.
    # To do it you must first find the token in
    # the marking.
    def delete(token)
      unless token.kind_of? Token
        raise InvalidToken.new "#{token} is not a Token object!"
      end
      each_key_with(token) do |key_name, value|
        next unless @lists.has_key? key_name
        next unless @lists[key_name].has_key? value
        @lists[key_name][value].delete token
      end
    end

    # Returns number of tokens in this marking
    def size
      @lists.values.first.values.first.size
    rescue
      0
    end


    def method_missing(method, *args)
      unless method.to_s[0..2] == "by_"
        super
      end
      key = method.to_s[3..-1].to_sym
      unless @keys.has_key? key
        super
      end
      value = args[0]
      tokens_by_key(key, value).map { |t| clone t }
    end

    private

    def tokens_by_key(key_name, value)
      @lists[key_name][value]
    end

    def each_key_with(token)
      @keys.each do |name, method|
        unless token.value.respond_to? method
          raise InvalidToken.new("#{token.inspect} does not respond to #{method}")
        end
        value = token.value.send(method)
        yield name, value
      end
    end

    def clone(token)
      token.clone
      #token
    end
  end

end
