require 'deep_clone'

module FastTCPN
  module Clone
  # :nodoc:
    def clone(token)
      DeepClone.clone token
    end
  end
end
