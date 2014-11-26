require 'spec_helper'

describe FastTCPN::DSL::TransitionDSL do
  let :model do

    FastTCPN.model do
      page "Test TCPN page" do
        p1 = place :in
        p2 = place :out
        transition "work" do
          input p1
          output p2 do |binding, clock|
            binding[:in]
          end
          sentry do |marking_for, clock, result|
            result << { out: marking_for[:in] }
          end
        end
      end
    end

  end

  describe "defines transition" do
    it "with name `work`" do
      expect(model.find_transition("work")).not_to be_nil
    end

    it "with one input place" do
      expect(model.find_transition("work").inputs_size).to eq 1
    end
    it "with out output place" do
      expect(model.find_transition("work").outputs_size).to eq 1
    end

    it "with sentry" do
      expect(model.find_transition("work").default_sentry?).to be false
    end
  end

end
