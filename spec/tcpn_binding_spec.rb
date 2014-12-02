require 'spec_helper'

describe FastTCPN::TCPNBinding do

  let :marking_for do
    process = FastTCPN::HashMarking.new
    process.add "process1"
    process.add "process2"

    cpu = FastTCPN::HashMarking.new
    cpu.add "cpu1"
    cpu.add "cpu2"

    { process: process, cpu: cpu }
  end

  let :selected_process do
    marking_for[:process].each.first
  end

  let :selected_cpu do
    marking_for[:cpu].each.first
  end

  let :mapping do
    { process: selected_process, cpu: selected_cpu }
  end

  subject do
    FastTCPN::TCPNBinding.new mapping, marking_for
  end

  describe "returns new copy of token for given place" do
    it "returns selected process" do
      expect(subject[:process]).to eq selected_process
    end

    it "returns selected cpu" do
      expect(subject[:cpu]).to eq selected_cpu
    end

  end

  context "for array of tokens for a place" do
    let :selected_process do
      [ marking_for[:process].to_a[0],
        marking_for[:process].to_a[1] ]
    end
    it "returns array of new copies of tokens for this place" do
      expect(subject[:process]).to eq selected_process
    end

  end
end
