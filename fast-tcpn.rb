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

require 'benchmark'

class Place
  attr_reader :name

  def initialize(name, marking = [])
    @name = name
    @marking = clone marking
  end

  def marking
    clone @marking
  end

  def marking=(m)
    @marking = clone m
  end

  def marking_delete(token)
    @marking.delete token
  end

  def marking_add(token)
    @marking << clone(token)
  end

  private
  # if you turn on this cloning, it works 5x slower...
  def clone(o)
    #Marshal.load(Marshal.dump(o))
    #o.clone
    o
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
  # { place_name => Array_of_tokens, ... }
  # It must return Array of subsequent
  # valid bindings each in the form of Hash with
  # { place_name => token, another_place_name => another_token }
  def guard(&block)
    @guard = block
  end

  # fire this transition if possible
  # returns true if fired false otherwise
  def fire

    # FIXME:
    # if we shuffle place order in marking_hash
    # and tokens in each places order, we will be
    # able to take just first found binding here
    # * no need to iterate to the end
    # * no need to generate maybe large data structure
    valid_bindings = @guard.call(marking_hash)
    binding = valid_bindings[rand * valid_bindings.length]


    return false if binding.nil?
    binding.each do |place_name, token|
      find_input(place_name).marking_delete(token)
    end
    @outputs.each do |o|
      o.place.marking_add o.block.call(binding)
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

AppProcess = Struct.new(:name)
CPU = Struct.new(:name, :process)

procs = 1000.times.map { |i| AppProcess.new(i) }
cpus = procs.map { |p| 10.times.map { |i| CPU.new("CPU#{i}_#{p.name}", p.name) } }.reduce(:+)

p1 = Place.new :process, procs
cpu = Place.new :cpu, cpus
p2 = Place.new :done

t = Transition.new 'run'
t.input p1
t.input cpu
t.output p2 do |binding|
  binding[:process].name.to_s + "_done"
end
t.output cpu do |binding|
  binding[:cpu]
end

t.guard do |marking_hash|
  res = []
  cpus = {}
  marking_hash[:cpu].each { |c| cpus[c.process] ||= []; cpus[c.process] << c }
  res = []
  marking_hash[:process].each do |p|
    cpus[p.name].each do |c|
      res << { process: p, cpu: c }
    end
  end
  res
end

Benchmark.bm do |x|
  x.report do
    {} while t.fire
  end
end

puts p1.marking.size
puts p2.marking.size
puts cpu.marking.size
