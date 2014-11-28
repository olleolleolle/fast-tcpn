require 'spec_helper'

describe FastTCPN::TimedHashMarking do

  let(:marking_class) { FastTCPN::TimedHashMarking }

  let(:time) { 100 }

  let(:active1) { Worker.new("active1", true) }
  let(:active2) { Worker.new("active2", false) }
  let(:waiting1) { Worker.new("waiting1", true) }
  let(:waiting1_timestamp) { time + 100 }
  let(:waiting2) { Worker.new("waiting2", false) }
  let(:waiting2_timestamp) { time + 200 }

  let :marking do
    m = marking_class.new name: :name, finished: :finished?
    m.add active1
    m.add active2, time
    m.add waiting1, waiting1_timestamp
    m.add waiting1, waiting2_timestamp
    m.time = time
    m
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
    expect(subject.each.map { |t| t.value.name }).to match_array [ active1.name, active2.name ]
  end

  describe "returns waiting tokens when time comes"  do
    subject do
      marking.time = waiting1_timestamp
      marking
    end

    it "without filter" do
      expect(subject.each.map { |t| t.value.name }).to match_array [ active1.name, active2.name, waiting1.name ]
    end

    it "with name filter" do
      expect(subject.each(:name, waiting1.name).first.value.name).to eq waiting1.name
    end

    it "with finished filter" do
      expect(subject.each(:finished, true).map{ |t| t.value.name }).to match_array [ waiting1.name, active1.name ]
    end
  end

  describe "#next_time" do
    it "returns next time when a token may be available" do
      expect(marking.next_time).to eq waiting1_timestamp
      marking.time = waiting1_timestamp
      expect(marking.next_time).to eq waiting2_timestamp
    end

    it "returns 0 if no token will be available in the future" do
      marking.time = waiting2_timestamp
      expect(marking.next_time).to eq 0
    end

    it "returns 0 for empty marking" do
      marking = marking_class.new name: :name, finished: :finished?
      expect(marking.next_time).to eq 0
    end
  end

  describe "#add" do
    it "uses token's timestamp for token" do
      token = FastTCPN::TimedToken.new(Worker.new(:asd, true), 200)
      expect {
        marking.add token
      }.not_to change(marking, :size)
    end

    it "uses given timestamp for object" do
      expect {
        marking.add Worker.new(:asd, true), time
      }.to change(marking, :size).by(1)
    end

    describe "with Hash" do
      let(:value) { Worker.new("new intel123", true, 'intel') }
      subject do
        marking = marking_class.new name: :name, finished: :finished?
        marking.add val: value, ts: 100
        marking.time = 100
        marking
      end

      it "adds token with value from :val key" do
        expect(subject.each.first.value.name).to eq value.name
      end

      it "adds token with timestamp from :ts key" do
        expect(subject.each.first.timestamp).to eq 100
      end
    end
  end
end
