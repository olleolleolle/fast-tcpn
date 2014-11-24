module FastTCPN
  module Clone
    def clone(token)
      Marshal.load Marshal.dump token
    end
  end
end
