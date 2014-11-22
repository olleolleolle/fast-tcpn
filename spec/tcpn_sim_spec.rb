require 'spec_helper'

describe FastTCPN::TCPN do
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

    shared_examples "correctly moves tokens" do

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

    context "without time" do

      before do
        t1 = net.transition :work
        t1.sentry do |marking_for, clock, result|
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

      include_examples "correctly moves tokens"

    end

    context "with time" do
      before do
        t1 = net.transition :work
        t1.sentry do |marking_for, clock, result|
          marking_for[:process].each do |p|
            marking_for[:cpu].each(:process, p.value.name) do |c|
              result << { process: p, cpu: c }
            end
          end
        end
        t1.input process
        t1.input cpu
        t1.output out do |binding, clock|
          { val: binding[:process].value.name + "_done", ts: clock + 10 }
        end
        t1.output cpu do |binding, clock|
          binding[:cpu].with_timestamp clock + 100
        end

        t2 = net.transition :finish
        t2.input out
        t2.output finished do |binding, clock|
          binding[:out].with_timestamp clock + 100
        end

        process_count.times do |p|
          process.add AppProcess.new(p.to_s)
          cpu_count.times.map { |c| cpu.add CPU.new("CPU#{c}_#{p}", p.to_s) }
        end

        net.sim

      end

      include_examples "correctly moves tokens"

      it "sets correct timestamps of used cpus" do
        used_cpus = cpu.marking.select { |token| token.timestamp == 100 }.length
        expect(used_cpus).to eq process_count
      end

      it "sets correct timestamps on processes" do
        finished.marking.each do |token|
          expect(token.timestamp).to eq 110
        end
      end

      it "stops at correct time" do
        expect(net.clock).to eq 110
      end

    end

  end

end
