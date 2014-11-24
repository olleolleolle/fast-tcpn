require 'deep_clone'

module FastTCPN
  module Clone
    def clone(token)
      #token.clone
      #token
      DeepClone.clone token
    end
  end
end
