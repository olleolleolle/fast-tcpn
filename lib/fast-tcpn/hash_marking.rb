class Array

  # This will slow down with time -- the more
  # times we yield, the harder will be to hit
  # an unused value. So use standerd shuffle
  # if you need significant amount of values
  # shuffled. But if you need just a few, this
  # one is faster ;-)
  def lazy_shuffle
    return enum_for(:lazy_shuffle) unless block_given?
    was = {}
    self.size.times do
      i = 0
      begin
        i = rand self.size
      end while was.has_key?(i)
      was[i] = true
      yield self[i]
    end
  end
end

module FastTCPN

  class HashMarking

    include Clone


    InvalidToken = Class.new RuntimeError
    InvalidKey = Class.new RuntimeError
    CannotAddKeys = Class.new RuntimeError

    include Enumerable

    attr_reader :keys

    # Creates new HashMarking with specified keys. At least
    # one key must be specified. The keys are used to
    # store tokens in Hashes -- one hash for each key. Thus
    # finding tokens by the keys is fast.
    #
    # +keys+ is a hash of the form: { key_name => method }, where +key_name+ is a name that
    # will be used to access tokens indexed by this key and +method+ is a method that should
    # be called on token's value to get value that should be used group tokens indexed by this key.
    def initialize(keys = {})
      @keys = keys
      @lists = {}
      @global_list = {}
    end

    # Allows to iterate over all values in marking or over all values for which
    # specified +key+ has specified +value+. If no block is given, returns adequate
    # Enumerator. Yielded values are deep-cloned so you can use them without fear of
    # interfering with TCPN simulation.
    #
    # Values are yielded in random order -- each time each is called with block
    # or a new Enumerator is created, the order is changed. Thus tokens are selection 
    # is `in some sense fair`. Current implementation assumes, that in most cases iteration
    # will finish quickly, without yielding large number of tokens. In such cases the 
    # shuffling algorithm is efficient. But if for some reason most tokens from marking
    # should be yielded, it will be less and less efficient, with every nxt token. In this
    # case one should consider using standard +shuffle+ method here instead of +lazy_shuffle+.
    def each(key = nil, value = nil)
      return enum_for(:each, key, value) unless block_given?
      return if empty?
      list_for(key, value).lazy_shuffle do |token|
        yield clone token
      end
    end

    # Add new keys to this marking. This list will be merged with exisiting keys.
    # Adding keys is possible only if marking is empty, otherwise CannotAddKeys 
    # exception will be raised.
    def add_keys(keys)
      unless empty?
        raise CannotAddKeys.new("marking not empty!");
      end
      @keys.merge!(keys)
    end

    # True if the marking is empty.
    def empty?
      size == 0
    end

    # Creates new token of the +object+ and adds it to the marking.
    # Objects added to the marking are deep-cloned, so you can use them
    # without fear to interfere with TCPN simulation. But have it in mind!
    # If you put a large object with a lot of references in the marking,
    # it will significanntly slow down simulation and increase memory usage.
    def add(object)
      value = object
      if object.instance_of? Hash
        value = object[:val]
      end
      add_token prepare_token(value)
    end

    alias << add

    # Deletes the +token+ from the marking.
    # To do it you must first find the token in
    # the marking.
    def delete(token)
      validate_token!(token)
      delete_token(token)
    end

    # Returns number of tokens in this marking
    def size
      @global_list.size
    end

    # :nodoc:
    # Return fresh, unaltered clone of given token
    # The given token's value could have been changed when it was
    # passed to a user-defined code. Use this method to refresh this value.
    # Will work as long as user interfered with token value, but not with
    # the token object iself.
    #
    # For internal use, while firing transition
    def get(token)
      clone @global_list[token]
    end

    private

    def tokens_by_key(key_name, value)
      unless @keys.has_key? key_name
        raise InvalidKey.new(key_name)
      end
      @lists[key_name][value]
    end

    def each_key_with(token)
      @keys.each do |name, method_with_params|
        params = nil
        method = method_with_params
        if method_with_params.instance_of? Array
          method = method_with_params.first
          params = method_with_params[1..-1]
        end
        unless token.value.respond_to? method
          raise InvalidToken.new("#{token.inspect} does not respond to #{method.inspect}")
        end
        value = token.value.send(method, *params)
        yield name, value
      end
    end

    def prepare_token(object)
      if object.instance_of? token_type
        clone object
      else
        token_type.new clone(object)
      end
    end

    def add_token(token)
      @global_list[token] = token
      each_key_with(token) do |key_name, value|
        @lists[key_name] ||= {}
        @lists[key_name][value] ||= []
        @lists[key_name][value] << token
      end
    end

    # reimplement if inherited classes need different one
    def token_type
      Token
    end

    def validate_token!(token)
      unless token.instance_of? token_type
        raise InvalidToken.new "#{token} is not a #{token_type} object!"
      end
    end

    def delete_token(token)
      return nil unless @global_list.delete token
      each_key_with(token) do |key_name, value|
        next unless @lists.has_key? key_name
        next unless @lists[key_name].has_key? value
        @lists[key_name][value].delete token
      end
      token
    end

    def list_for(key, value)
      list = if !key.nil? && !value.nil?
        tokens_by_key key, value
      else
        @global_list.keys
      end
      if list.nil?
        list = []
      end
      list
    end
  end

end
