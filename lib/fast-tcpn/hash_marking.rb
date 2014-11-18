require 'deep_clone'

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


    InvalidToken = Class.new RuntimeError
    CannotAddKeys = Class.new RuntimeError

    include Enumerable

    attr_reader :keys

    # Creates new HashMarking with specified keys. At least
    # one key must be specified. The keys are used to
    # store tokens in Hashes -- one hash for each key. Thus
    # finding tokens by the keys is fast.
    def initialize(keys = {})
      @keys = keys
      @lists = {}
      @global_list = {}
    end

    def each(key = nil, value = nil)
      return enum_for(:each, key, value) unless block_given?
      list_for(key, value).lazy_shuffle do |token|
        yield clone token
      end
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
      add_token prepare_token(object)
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


    private

    def tokens_by_key(key_name, value)
      unless @keys.has_key? key_name
        raise InvalidKey.new(key_name)
      end
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
      #token.clone
      #token
      DeepClone.clone token
    end

    def prepare_token(object)
      if object.instance_of? Token
        clone object
      else
        Token.new clone(object)
      end
    end

    def add_token(token)
      @global_list[token] = true
      each_key_with(token) do |key_name, value|
        @lists[key_name] ||= {}
        @lists[key_name][value] ||= []
        @lists[key_name][value] << token
      end
    end

    def validate_token!(token)
      unless token.instance_of? Token
        raise InvalidToken.new "#{token} is not a Token object!"
      end
    end

    def delete_token(token)
      @global_list.delete token
      each_key_with(token) do |key_name, value|
        next unless @lists.has_key? key_name
        next unless @lists[key_name].has_key? value
        @lists[key_name][value].delete token
      end
    end

    def list_for(key, value)
      if !key.nil? && !value.nil?
        tokens_by_key key, value
      else
        @global_list.keys
      end
    end
  end

end
