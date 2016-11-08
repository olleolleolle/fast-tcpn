module FastTCPN
  DontCloneClasses = [ Numeric, Symbol, TrueClass, FalseClass, NilClass ]
  module Clone
  # :nodoc:
    def clone(token)
      token.deep_clone
    end
  end
end

# http://stackoverflow.com/questions/8206523/how-to-create-a-deep-copy-of-an-object-in-ruby
class Object
  def deep_clone
    return @deep_cloning_obj if @deep_cloning
    return @deep_cloning_obj if frozen?
    @deep_cloning_obj = clone
    @deep_cloning_obj.instance_variables.each do |var|
      val = @deep_cloning_obj.instance_variable_get(var)
      begin
        @deep_cloning = true
        val = val.deep_clone
      # silent rescue is never a good idea...
      #rescue TypeError
      #  next
      ensure
        # better not to litter original object with
        # temporary instance variables
        #@deep_cloning = false
        remove_instance_variable :@deep_cloning
      end
      @deep_cloning_obj.instance_variable_set(var, val)
    end
    deep_cloning_obj = @deep_cloning_obj
    @deep_cloning_obj = nil
    # better not to litter original object with
    # temporary instance variables
    remove_instance_variable :@deep_cloning_obj
    deep_cloning_obj
  end
end

FastTCPN::DontCloneClasses.each do |klazz|
  klazz.class_eval do
    def deep_clone
      self
    end
  end
end


