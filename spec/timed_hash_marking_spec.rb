require 'spec_helper'

describe FastTCPN::TimedHashMarking do

  let(:marking_class) { FastTCPN::TimedHashMarking }

  let(:time) { 100 }

  let :marking do
    m = marking_class.new name: :name, finished: :finished?
    m.time = time
  end

  it_behaves_like 'hash marking'

  it "stores current time"
  it "does not allow to put back clock"

  it "returns active tokens"
  it "does not return waiting tokens"
  it "returns waiting tokens when time comes"

end
