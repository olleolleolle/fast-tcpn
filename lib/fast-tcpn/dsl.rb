require 'docile'

module FastTCPN
  # Allows to create new TCPN model by interpreting passed block of code.
  # If you read this code from a file, pass it's name as a parameter, it
  # will be used in exceptions.
  def self.model(file = nil, &block)
    tcpn = TCPN.new
    load_model tcpn, file, &block
    tcpn
  end

  # Read TCPN model from a +file+.
  def self.read(file)
    block = instance_eval "proc { #{File.read file} }", file
    model file, &block
  end

  # For interal use. Use #read od #model.
  def self.load_model(tcpn, file, &block)
    Docile.dsl_eval(DSL::TCPNDSL.new(tcpn, file), &block)
  end

  module DSL

    # Represents and encapsulates all errors that will occur while
    # running DSL.
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

      # Define a page of TCPN model
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

      # Create and return a new place (not timed). If a place with this
      # name exists somewhere in the model (e.g. on other pages), and object
      # representing exisiting place will be returned. Keys of both keys will
      # be merged.
      def place(name, keys = {})
        @tcpn.place name, keys
      end

      # Create and return a new timed place. 
      def timed_place(name, keys = {})
        @tcpn.timed_place name, keys
      end

      # Create and return new transition for the TCPN. Block
      # defines transitions inputs, outputs and sentry.
      def transition(name, &block)
        transition = @tcpn.transition name
        Docile.dsl_eval(TransitionDSL.new(transition), &block)
        transition
      end

      # define new TCPN (sub) page on this page.
      def page(name, &block)
        @dsl.page name, &block
      end

      # load TCPN sub page from a file. File location is relative to
      # the location of currently interpreted file (if known)
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

      # Defines input place for this transition. +place+ must an
      # object returned by +place+ ot +timed_place+ statement.
      def input(place)
        @transition.input place
      end

      # Defines output place for this transition. +place+ must an
      # object returned by +place+ ot +timed_place+ statement.
      #
      def output(place, &block)
        @transition.output place, &block
      end

      # Defines sentry for this transition.
      def sentry(&block)
        @transition.sentry &block
      end
    end

  end
end
