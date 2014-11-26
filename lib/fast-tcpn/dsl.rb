require 'docile'

module FastTCPN
  def self.model(&block)
    tcpn = TCPN.new
    Docile.dsl_eval(DSL::TCPNDSL.new(tcpn), &block)
    tcpn
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
        "#{@cause.inspect} on TCPN page: `#{@page}`"
      end

      def message
        "#{@cause.message} on TCPN page: `#{@page}`"
      end
    end

    class TCPNDSL
      def initialize(tcpn)
        @tcpn = tcpn
      end

      def page(name, &block)
        Docile.dsl_eval(PageDSL.new(@tcpn, self), &block)
      rescue StandardError => e
        raise DSLError.new e, name
      end
    end

    class PageDSL
      def initialize(tcpn, dsl)
        @tcpn = tcpn
        @dsl = dsl
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
