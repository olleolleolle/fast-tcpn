require 'deep_dive'

[ Fixnum, Symbol, TrueClass, FalseClass ].each do |klazz|
  klazz.class_eval do
    def clone
      self
    end
  end
end

class Object
  include DeepDive
  exclude do |sym, obj|
    obj.kind_of? Symbol
  end
end

module FastTCPN
  module Clone
    def clone(token)
      token.dclone
    end
  end
end
