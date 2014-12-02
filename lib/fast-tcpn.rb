require 'fast-tcpn/version'
require 'fast-tcpn/place'
require 'fast-tcpn/timed_place'
require 'fast-tcpn/transition'
require 'fast-tcpn/clone'
require 'fast-tcpn/hash_marking'
require 'fast-tcpn/timed_hash_marking'
require 'fast-tcpn/token'
require 'fast-tcpn/timed_token'
require 'fast-tcpn/tcpn'
require 'fast-tcpn/dsl'

module FastTCPN
  @@debug = false

  # Check debugging of FastTCPN -- full backtraces from simulator
  def self.debug
    @@debug
  end

  # Turn on/off debugging of FastTCPN -- full backtraces from simulator
  def self.debug=(d)
    @@debug = d
  end
end
