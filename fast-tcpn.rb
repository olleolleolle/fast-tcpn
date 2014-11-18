# WRz 2014-11-14
#
# This is a proof of concept implementation of
# fast TCPN simulator.
# Main concept if that guard is not a function
# receiving binding and answering if it is valid or not.
# Instead guard gets list of all input tokens from input
# places and returns valid bindngs. If programmer is a fool
# and guard is naive, it will be slow as it was so far. But
# generally it is possible to generate possible bindings
# using Hashes in linear time (about n*k where k is number of
# input places and n is number of tokens in each place) instead
# of n**k as in case of analysing cartesian product for traditional
# boolean guard

#
# Note on clining.
#
# Branch clone_selected_tokens assumes that only tokens
# used by the user are cloned. Here we clone whole marking
# before it can be used in guard or inscription. For well 
# prepared guard, when possible small number of tokens is 
# taken from marking it is faster to clone individual tokens 
# (4 sec instead of 6.9 sec). But for worse guard it is faster 
# to clone whole marking at the begining, then many individual 
# tokens (14 sec. instead of 6.9 sec). The better guard in this
# example is when we put all processes in a Hash and try to match 
# a CPU, worse guard is when we put all CPUs in a Hash and try to 
# match a process. We have 10 times more CPUs the processes in this 
# example, and putting a token into a Hash requires cloning it.
#
# The above times were obtained for 1000 procs, 10 cpus for each and
# ruby_deep_clone library.
#
#
# Possible optimization.
# If we could define how a place stores its marking, it would make
# firing transition much faster. Ther would be no need to rewrite
# tokens from array to other structure, e.g Hash. We could e.g. define
# that processes should be stored in a Hash keyed by process name and
# thus make all guards matching by process name much faster! How to
# do this to make it sufficiently general? Different (custom) 
# implementations of Marking class?
#
# HashMarking -- when creating Place define token keys that will be used
# to search tokens in different transitions, these keys will be passed to
# HashMarking object created in the Place. The HashMarking object maintains
# a Hash of tokens for each of the keys defined when creating the Place.
# Every token in the Place is put in each Hash udenr different keys. 
# HashMarking exposes method named after the keys, that find token in
# appropriate Hash using given key. This way we will have possibility
# to quickly find tokens using require criterions. Adding a token to marking
# requires adding to each Hash (an probably an Array that probably should 
# also be maintaned). Deleting requires removal from every Hash (but using
# the Hash'es key, thus quickly). It will be a little slower, but adding 
# and deleting is much less often then finding tokens while trying to fire
# a transition. Memory oveshead will not be significant, since the Hashes
# will store only reference to a single copy of the object. The keys may
# not uniquely identify objects, so the Hashes should store arrays of
# objects matching given key. Iterators should be exposed for these arrays
# and for the whole marking. The iterators should shuffle the arrays before
# starting iteration and clone yielded objects -- anyway we assume that
# shuffling will let one take first object returned by iterator, so cloning
# will be rare.
#
# Thus we will be able to fire transition not in linear time, but in O(1) 
# time at the expense of not significant memory overhead and insignificant 
# complication of add/delete token operations for marking!
#
#
#
# (***) Note on efficiency (find this mark in code).
#
# calling
# marking_hash[:process].each
# without additional parameters results in need to do
# @global_list.keys in HashMarking and to generate an
# awfully large array. This is major cause that is blocking
# subsequent speedup of simulation. Unfortunately this
# array is required to enable shuffling of elements to
# ensure fair treatment of TCPN conflicts.
#
# THE BELOW IS NOT TRUE -- tested it!
# Similar situation will occcur in case of places that
# store a lot of tokens under one key -- there we also use
# Hash with tokens as keys and generate token list using
# Hash#keys method. Adding and removing tokens is faster
# in this case, especially for the large token lists.

require 'benchmark'
require 'deep_clone'
require 'fast-tcpn'

require 'ruby-prof'

module FastTCPN

  class Place

    attr_reader :name

    def initialize(name, keys = {})
      @name = name
      @marking = HashMarking.new keys
    end

    def marking
      @marking
    end

    def delete(token)
      @marking.delete token
    end

    def add(token)
      @marking << token
    end
  end

  class OutputArc
    attr_reader :place, :block
    # the +block+ will be given actual binding and
    # must return token that should be put in the
    # +palce+
    def initialize(place, block)
      @place, @block = place, block
    end
  end

  class Transition
    def initialize(name)
      @name = name
      @inputs = []
      @outputs = []
      @guard = nil
    end

    # Add input arc from the +place+.
    # No inscruption currently possible,
    # one token will be taken from the +place+
    # each time the transition is fired.
    def input(place)
      raise "This is not a Place object!" unless place.kind_of? Place
      @inputs << place
    end

    # Add output arc to the +place+, +block+ is the
    # arcs inscription it will be given current binding
    # and should return tokens that should be put in
    # the +place+.
    def output(place, &block)
      raise "This is not a Place object!" unless place.kind_of? Place
      @outputs << OutputArc.new(place, block)
    end

    # Define guard for this transition as a block.
    # The guard block will be given markings of
    # all input places in the form of Hash:
    # { place_name => Array_of_tokens, ... } and
    # a result object.
    # It should push (<<) to the return object
    # subsequent valid bindings in the form of Hash with
    # { place_name => token, another_place_name => another_token }
    def guard(&block)
      @guard = block
    end

    # fire this transition if possible
    # returns true if fired false otherwise
    def fire

      # Marking is shuffled each time before it is
      # used so here we can take first found binding
      binding = Enumerator.new do |y|
                  @guard.call(marking_hash, y)
                end.first

      return false if binding.nil?
      binding.each do |place_name, token|
        find_input(place_name).delete(token)
      end
      @outputs.each do |o|
        o.place.add o.block.call(binding)
      end
      true
    end

    private

    def marking_hash
      bnd = {}
      @inputs.each do |place|
        bnd[place.name] = place.marking
      end
      bnd
    end

    def find_input(name)
      @inputs.each do |place|
        return place if place.name == name
      end
      nil
    end
  end

end

AppProcess = Struct.new(:name)
CPU = Struct.new(:name, :process)

p1 = FastTCPN::Place.new :process, { name: :name }
cpu = FastTCPN::Place.new :cpu, { process: :process }
p2 = FastTCPN::Place.new :done

profile = false

10_000.times do |p| 
  p1.add AppProcess.new(p)
  10.times.map { |c| cpu.add CPU.new("CPU#{c}_#{p}", p) }
end


t = FastTCPN::Transition.new 'run'
t.input p1
t.input cpu
t.output p2 do |binding|
  binding[:process].value.name.to_s + "_done"
end
t.output cpu do |binding|
  binding[:cpu]
end

t.guard do |marking_hash, result|
  # (***) see note on efficiency above
  marking_hash[:process].each do |p|
    marking_hash[:cpu].each(:process, p.value.name) do |c|
      result << { process: p, cpu: c }
    end
  end
end

puts p1.marking.size
puts p2.marking.size
puts cpu.marking.size

RubyProf.start if profile

Benchmark.bm do |x|
  x.report do
    {} while t.fire
  end
end


if profile
  result = RubyProf.stop
  # Print a flat profile to text
  #printer = RubyProf::FlatPrinter.new(result)
  #printer = RubyProf::FlatPrinterWithLineNumbers.new(result)
  #printer = RubyProf::GraphHtmlPrinter.new(result)
  printer.print(STDOUT)
end

puts p1.marking.size
puts p2.marking.size
puts cpu.marking.size
