require 'pry'
module FastTCPN
  class TCPN

    class Clock
      def initialize
        @value = 0
      end

      def set(value)
        return false if value <= @value
        @value = value
        true
      end

      def get
        @value
      end

    end

    def initialize
      @places = {}
      @transitions = []
      @clock = Clock.new
    end

    def place(name, keys = {})
      place = @places[name]
      if place.nil?
        place = TimedPlace.new name, keys
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
        fired = fire_transitions
        advanced = move_clock_to find_next_time
      end while fired || advanced
    end

    def clock
      @clock.get
    end

    private

    def move_clock_to(val)
      return false unless @clock.set val
      @places.each do |name, place|
        place.time = val
      end
      true
    end

    def fire_transitions
      fired_count = 0
      begin
        fired = false
        @transitions.shuffle.each do |transition|
          if transition.fire clock
            fired_count += 1
            fired = true
          end
        end
      end while fired
      fired_count > 0
    end

    def find_next_time
      time = 0
      @places.each do |name, place|
        next_time = place.next_time
        if next_time > clock && (time == 0 || next_time < time)
          time = next_time
        end
      end
      time
    end

  end
end
