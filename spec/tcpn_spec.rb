require 'spec_helper'

describe FastTCPN::TCPN do
  describe "#place" do

    context "if place does not exist" do

      it "creates new place" do
        expect {
          subject.place "cpus", name: :name, node: :node
        }.to change(subject, :places_count).by(1)
      end

      it "returns created place" do
        p = subject.place "cpus", name: :name, node: :node
        expect(p.name).to eq 'cpus'
        expect(p.keys).to eq({ name: :name, node: :node })
      end

    end

    context "if place exists" do

      subject do
        n = FastTCPN::TCPN.new
        n.place "cpus", name: :name, node: :node
        n
      end

      it "does not create place" do
        expect {
          subject.place "cpus", name: :name, node: :node
        }.not_to change(subject, :places_count)
      end

      it "returns existing place" do
        p = subject.place("cpus", valid: :valid?)
        expect(p.kind_of? FastTCPN::Place).to be true
        expect(p.name).to eq("cpus")
      end

      it "merges new keys of place with old ones" do
        expect(subject.place("cpus", valid: :valid?).keys).to eq({ name: :name, node: :node, valid: :valid? })
      end

    end
  end

  describe "#find_place finds place by name" do

    subject do
      net = FastTCPN::TCPN.new
      net.place "cpus", name: :name, node: :node
      net.place "nodes", name: :name
      net
    end

    it { expect(subject.find_place("cpus").name).to eq "cpus" }
    it { expect(subject.find_place("nodes").name).to eq "nodes" }

  end

  describe "#transition" do
    context "if transition does not exist" do
      it "creates new transition" do
        expect {
          subject.transition(:cpu_working)
        }.to change(subject, :transitions_count).by(1)
      end

      it "returns created transition" do
        t = subject.transition(:cpu_working)
        expect(t.kind_of? FastTCPN::Transition).to be true
        expect(t.name).to eq :cpu_working
      end
    end

    context "if transition exists" do
      subject do
        n = FastTCPN::TCPN.new
        n.transition :cpu_working
        n
      end

      it "does not create new transition" do
        expect {
          subject.transition(:cpu_working)
        }.not_to change(subject, :transitions_count)
      end

      it "returns existing transition" do
        t = subject.transition(:cpu_working)
        expect(t.kind_of? FastTCPN::Transition).to be true
        expect(t.name).to eq :cpu_working
      end
    end
  end

  describe "#sim" do
    AppProcess = Struct.new(:name)
    CPU = Struct.new(:name, :process)

    let(:net) do 
      n = FastTCPN::TCPN.new
      n
    end

    let(:process_count) { 10 }
    let(:cpu_count) { 10 }

    let(:process) { net.place :process, name: :name }
    let(:cpu) { net.place :cpu, name: :name, process: :process }
    let(:out) { net.place :out }
    let(:finished) { net.place :finished }

    before do
      t1 = net.transition :work
      t1.sentry do |marking_for, result|
        marking_for[:process].each do |p|
          marking_for[:cpu].each(:process, p.value.name) do |c|
            result << { process: p, cpu: c }
          end
        end
      end
      t1.input process
      t1.input cpu
      t1.output out do |binding|
        binding[:process].value.name + "_done"
      end
      t1.output cpu do |binding|
        binding[:cpu]
      end

      t2 = net.transition :finish
      t2.input out
      t2.output finished do |binding|
        binding[:out]
      end

      process_count.times do |p|
        process.add AppProcess.new(p.to_s)
        cpu_count.times.map { |c| cpu.add CPU.new("CPU#{c}_#{p}", p.to_s) }
      end

      net.sim

    end

    it "removes all tokens from process" do
      expect(process.marking.size).to eq 0
    end

    it "returns all tokens back to cpu" do
      expect(cpu.marking.size).to eq cpu_count * process_count
    end

    it "leaves no tokens in out" do
      expect(out.marking.size).to eq 0
    end

    it "puts all tokens in finished" do
      expect(finished.marking.size).to eq process_count
    end


  end

end
