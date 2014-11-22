require 'spec_helper'

describe FastTCPN::TimedPlace do

  let(:place_class) { FastTCPN::TimedPlace }
  let(:marking_class) { FastTCPN::TimedHashMarking }
  let(:keys) { { name: :name, valid: :valid? } }

  it_behaves_like 'valid place'

  subject do
    place_class.new "cpu"
  end

  let :marking do
    marking = double(marking_class)
    mc = class_double(marking_class).as_stubbed_const(:transfer_nested_constants => true)
    allow(mc).to receive(:new).and_return(marking)
    marking
  end

  it "passes next_time to marking" do
    expect(marking).to receive(:next_time).and_return(997)
    expect(subject.next_time).to eq 997
  end

  it "passes time= to marking" do
    expect(marking).to receive(:time=)
    subject.time = 123
  end
end
