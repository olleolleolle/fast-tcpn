require 'spec_helper'

describe "FastTCPN::Place" do

  let(:place_class) { FastTCPN::Place }
  let(:marking_class) { FastTCPN::HashMarking }
  let(:keys) { { name: :name, valid: :valid? } }

  it "has name" do
    p = place_class.new "process"
    expect(p.name).to eq "process"
  end

  it "passes keys to marking constructor" do
    expect(marking_class).to receive(:new).with(keys)
    place_class.new "processes", keys
  end

  describe "when created" do
    subject do
      place_class.new "processes", keys
    end
    let(:token) { "for this example just anything" }
    let(:new_keys) { { node: :node_name, priority: :pri } }

    let :marking do
      marking = double(marking_class)
      mc = class_double(marking_class).as_stubbed_const(:transfer_nested_constants => true)
      allow(mc).to receive(:new).and_return(marking)
      marking
    end

    it "passes add to marking" do
      expect(marking).to receive(:add).with(token)
      subject.add token
    end

    it "passes delete to marking" do
      expect(marking).to receive(:delete).with(token)
      subject.delete token
    end

    it "passes add_keys to marking" do
      expect(marking).to receive(:add_keys).with(new_keys)
      subject.add_keys new_keys
    end

    it "passes keys to marking" do
      expect(marking).to receive(:keys)
      subject.keys
    end
  end

end
