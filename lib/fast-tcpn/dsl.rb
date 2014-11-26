require 'docile'

module FastTCPN
  def self.model(file = nil, &block)
    tcpn = TCPN.new
    load_model tcpn, file, &block
    tcpn
  end

  def self.read(file)
    block = instance_eval "proc { #{File.read file} }", file
    model file, &block
  end

  def self.load_model(tcpn, file, &block)
    Docile.dsl_eval(DSL::TCPNDSL.new(tcpn, file), &block)
  end

  module DSL

    class DSLError < RuntimeError
      attr_reader :cause, :page

      def initialize(cause, page)
        super cause
        set_backtrace cause.backtrace
        @cause, @page = cause, page
      end

      def inspect
        "<#{self.class} #{@cause.inspect} on TCPN page: `#{@page}`>"
      end

      def message
        "#{@cause.message} on TCPN page: `#{@page}`"
      end
    end

    class TCPNDSL
      def initialize(tcpn, file)
        @tcpn = tcpn
        @file = file
      end

      def page(name, &block)
        Docile.dsl_eval(PageDSL.new(@tcpn, self, @file), &block)
      rescue StandardError => e
        raise DSLError.new e, name
      end
    end

    class PageDSL
      def initialize(tcpn, dsl, file)
        @tcpn = tcpn
        @dsl = dsl
        @file = file
      end

      def place(name, keys = {})
        @tcpn.place name, keys
      end

      def timed_place(name, keys = {})
        @tcpn.timed_place name, keys
      end

      def transition(name, &block)
        transition = @tcpn.transition name
        Docile.dsl_eval(TransitionDSL.new(transition), &block)
        transition
      end

      def page(name, &block)
        @dsl.page name, &block
      end

      def sub_page(file)
        file = File.expand_path(file, File.dirname(@file)) unless @file.nil?
        block = instance_eval "proc { #{File.read file} }", file
        FastTCPN.load_model @tcpn, file, &block
      end
    end

    class TransitionDSL
      def initialize(transition)
        @transition = transition
      end

      def input(place)
        @transition.input place
      end

      def output(place, &block)
        @transition.output place, &block
      end

      def sentry(&block)
        @transition.sentry &block
      end
    end

  end
end
