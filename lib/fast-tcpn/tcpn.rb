module FastTCPN
  class TCPN
    def initialize
      @places = {}
      @transitions = []
    end

    def place(name, keys = {})
      place = @places[name]
      if place.nil?
        place = Place.new name, keys
      else
        place.add_keys keys
      end
      @places[name] = place
    end

    def transition(name)
      t = @transitions.select { |t| t.name == name }.first
      if t.nil?
        t = Transition.new name
        @transitions << t
      end
      t
    end

    def find_place(name)
      @places[name]
    end

    def places_count
      @places.size
    end

    def transitions_count
      @transitions.size
    end

    def sim
      begin
        fired = false
        @transitions.shuffle.each do |transition|
          if transition.fire
            fired = true
          end
        end
      end while fired
    end
  end
end
