require 'spec_helper'

describe FastTCPN::Transition do
  let(:process) { :a_process }
  let(:process2) { :a_process2 }
  let(:process3) { :a_process3 }
  let(:cpu) { :a_cpu }

  let(:in1) do
    p = FastTCPN::Place.new "process"
    p.add process
    p
  end

  let(:in2) do
    p = FastTCPN::Place.new "cpu"
    p.add cpu
    p
  end

  let(:empty) do
    p = FastTCPN::Place.new "empty"
    p
  end

  let(:out) { FastTCPN::Place.new "output" }

  let :transition do
    t = FastTCPN::Transition.new :working
    t.input in1
    t.input in2
    t
  end

  it "has name" do
    expect(transition.name).to eq :working
  end

  describe "#fire" do
    it "passes input tokens to sentry" do
      transition.sentry do |marking_for, clock, result|
        expect(marking_for[in1.name].each.first.value).to eq process
        expect(marking_for[in2.name].each.first.value).to eq cpu
      end
      transition.fire
    end

    it "passes valid binding to output arc expression" do
      transition.sentry do |marking_for, clock, result|
        result << { in1.name => marking_for[in1.name].first, in2.name => marking_for[in2.name].first }
      end
      transition.output out do |binding|
        expect(binding[in1.name].value).to eq process
        expect(binding[in2.name].value).to eq cpu
        binding[in1.name]
      end
      transition.fire
    end

    it "passes clock to sentry" do
      transition.sentry do |marking_for, clock, result|
        expect(clock).to eq 1000
      end
      transition.fire(1000)
    end

    it "passes clock to output arc expression" do
      transition.sentry do |marking_for, clock, result|
        result << { in1.name => marking_for[in1.name].first, in2.name => marking_for[in2.name].first }
      end
      transition.output out do |binding, clock|
        expect(clock).to eq 1000
        binding[in1.name]
      end
      transition.fire 1000
    end

    it "removes single tokens from input places and puts in output places" do
      transition.sentry do |marking_for, clock, result|
        result << { in1.name => marking_for[in1.name].first, in2.name => marking_for[in2.name].first }
      end
      transition.output out do |binding|
        binding[in1.name]
      end
      transition.output in2 do |binding|
        binding[in2.name]
      end
      transition.fire
      expect(out.marking.each.map { |t| t.value }).to match_array [ process ]
      expect(in2.marking.each.map { |t| t.value }).to match_array [ cpu ]
    end

    it "removes array of tokens from input places and puts in output places" do
      in1.add process2
      in1.add process3
      transition.sentry do |marking_for, clock, result|
        p1 = marking_for[in1.name].select { |t| t.value == process2 }.first
        p2 = marking_for[in1.name].select { |t| t.value == process3 }.first
        result << { in1.name => [p1, p2], in2.name => marking_for[in2.name].first }
      end
      transition.output out do |binding|
        expect(binding[in1.name].map{ |t| t.value }).to eq [process2, process3]
        binding[in1.name].first
      end
      transition.output in2 do |binding|
        binding[in2.name]
      end
      transition.fire
      expect(out.marking.each.map { |t| t.value }).to match_array [ process2 ]
      expect(in2.marking.each.map { |t| t.value }).to match_array [ cpu ]
    end

    it "accepts nil as result of output arc expression" do
      transition.sentry do |marking_for, clock, result|
        result << { in1.name => marking_for[in1.name].first, in2.name => marking_for[in2.name].first }
      end
      transition.output out do |binding|
        binding[in1.name]
      end
      transition.output in2 do |binding|
        nil
      end
      transition.fire
      expect(out.marking.each.map { |t| t.value }).to match_array [ process ]
      expect(in2.marking).to be_empty
    end


    describe "default sentry" do
      it "works correctly for empty input markings" do
        transition = FastTCPN::Transition.new "disabled"
        transition.input empty
        transition.output out do |binding|
          binding[empty.name]
        end
        expect(transition.fire).to be false
      end

      it "lets it fire for any tokens" do
        transition.output out do |binding|
          binding[in1.name]
        end
        transition.output in2 do |binding|
          binding[in2.name]
        end
        expect(transition.fire).to be true
        expect(in1.marking).to be_empty
        expect(in2.marking).not_to be_empty
        expect(out.marking).not_to be_empty
      end

      it "prevents firing transition if one of many input places is not marked" do
        transition = FastTCPN::Transition.new "disabled"
        transition.input in1
        transition.input empty
        transition.output out do |binding|
          binding[empty.name]
        end
        expect(transition.fire).to be false

      end
    end

    describe "#default_sentry?" do
      it "is true if transition has no custom sentry" do
        transition = FastTCPN::Transition.new "work"
        expect(transition.default_sentry?).to be true
      end
      it "is false if transition has a custom sentry" do
        transition = FastTCPN::Transition.new "work"
        transition.sentry {}
        expect(transition.default_sentry?).to be false
      end
    end

    describe "#output" do
      it "requires Place object as first parameter" do
        expect { transition.output(:asd) {} }.to raise_error
      end
      it "requires block" do
        expect { transition.output in1 }.to raise_error
      end
    end

    describe "#inputs_size" do
      it "counts input arcs" do
        expect{
          transition.input out
        }.to change(transition, :inputs_size).from(2).to(3)
      end
    end

    describe "#outputs_size" do
      it "counts output arcs" do
        expect{
          transition.output(out) {}
        }.to change(transition, :outputs_size).from(0).to(1)
      end
    end

    describe "callbacks" do
      let(:net) { double Object, call_callbacks: nil  }
      let :transition do
        t = FastTCPN::Transition.new :working, net
        t.input in1
        t.input in2
        t
      end

      it "calls before callbacks on its net" do
        expect(net).to receive(:call_callbacks).with(:transition, :before, anything()).once
        transition.fire
      end

      it "calls after callbacks on its net" do
        expect(net).to receive(:call_callbacks).with(:transition, :after, anything()).once
        transition.fire
      end
    end

    it "raises error if sentry puts in binding invalid object in place of token" do
      transition.sentry do |marking_for, clock, result|
        result << { in1.name => Object.new }
      end
      expect { transition.fire }.to raise_error FastTCPN::Transition::InvalidToken
    end

    it "raises error if sentry puts in binding token that not exists in place" do
      transition.sentry do |marking_for, clock, result|
        result << { in1.name => marking_for[in2.name].first }
      end
      expect { transition.fire }.to raise_error FastTCPN::Transition::InvalidToken
    end
  end

end
