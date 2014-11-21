require 'spec_helper'

describe FastTCPN::Transition do
  let(:process) { :a_process }
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
      transition.sentry do |marking_for, result|
        expect(marking_for[in1.name].each.first.value).to eq process
        expect(marking_for[in2.name].each.first.value).to eq cpu
      end
      transition.fire
    end

    it "passes valid binding to output arc expression" do
      b = nil
      transition.sentry do |marking_for, result|
        result << { in1.name => marking_for[in1.name].first, in2.name => marking_for[in2.name].first }
      end
      transition.output out do |binding|
        expect(binding[in1.name].value).to eq process
        expect(binding[in2.name].value).to eq cpu
        binding[in1.name]
      end
      transition.fire
    end

    it "removes marking from input places and puts in output places" do
      transition.sentry do |marking_for, result|
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

    it "accepts nil as result of output arc expression" do
      transition.sentry do |marking_for, result|
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
    end

    it "raises error if sentry puts in binding invalid object in place of token" do
      transition.sentry do |marking_for, result|
        result << { in1.name => Object.new }
      end
      expect { transition.fire }.to raise_error FastTCPN::Transition::InvalidToken
    end

    it "raises error if sentry puts in binding token that not exists in place" do
      transition.sentry do |marking_for, result|
        result << { in1.name => marking_for[in2.name].first }
      end
      expect { transition.fire }.to raise_error FastTCPN::Transition::InvalidToken
    end
  end

end
