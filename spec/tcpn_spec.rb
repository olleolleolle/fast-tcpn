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

end
