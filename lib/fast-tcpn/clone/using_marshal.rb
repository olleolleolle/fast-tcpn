module FastTCPN
  module Clone
    # :nodoc:
    def clone(token)
      Marshal.load Marshal.dump token
    end
  end
end
