require 'spec_helper'

describe FastTCPN::TimedHashMarking do

  let(:marking_class) { FastTCPN::TimedHashMarking }

  let(:time) { 100 }

  let(:active1) { AppProcess.new("active1", true) }
  let(:active2) { AppProcess.new("active2", false) }
  let(:waiting1) { AppProcess.new("waiting1", true) }
  let(:waiting1_timestamp) { time + 100 }
  let(:waiting2) { AppProcess.new("waiting2", false) }
  let(:waiting2_timestamp) { time + 200 }

  let :marking do
    m = marking_class.new name: :name, finished: :finished?
    m.add active1
    m.add active2, time
    m.add waiting1, waiting1_timestamp
    m.add waiting1, waiting2_timestamp
    m.time = time
  end

  subject { marking }

  it_behaves_like 'hash marking'

  it "stores current time" do
    expect(subject.time).to eq time
  end

  it "does not allow to put back clock" do
    expect { subject.time = time - 10 }.to raise_error FastTCPN::TimedHashMarking::InvalidTime
  end

  it "returns only active tokens" do
    expect(subject.each.map { |t| t.value.name }).to match_array [ active1.name, active2.name, active3.name ]
  end

  describe "returns waiting tokens when time comes"  do
    subject do
      marking.time = waiting1_timestamp
      marking
    end

    it "without filter" do
      expect(subject.each.map { |t| t.value.name }).to match_array [ active1.name, active2.name, active3.name, waiting1.name ]
    end

    it "with name filter" do
      expect(subject.each(:name, waiting1.name).value.name).to eq waiting1.name
    end

    it "with finished filter" do
      expect(subject.each(:finished, true).value.name).to match_array [ waiting1.name, active1.name ]
    end
  end

end
