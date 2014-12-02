require 'spec_helper'
require 'pry'

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

      let(:process) { net.place :process, name: :name }
      let(:cpu) { net.place :cpu, name: :name, process: :process }
      let(:out) { net.place :out }
      let(:finished) { net.place :finished }


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

      let(:process) { net.timed_place :process, name: :name }
      let(:cpu) { net.timed_place :cpu, name: :name, process: :process }
      let(:out) { net.timed_place :out }
      let(:finished) { net.timed_place :finished }

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


    describe "error handling" do
      let(:process) { tcpn.timed_place :process, name: :name }
      let(:cpu) { tcpn.timed_place :cpu, name: :name, process: :process }
      let(:out) { tcpn.timed_place :out }

      let(:tcpn) do 
        FastTCPN::TCPN.new
      end

      before do
        t1 = tcpn.transition :work
        t1.sentry &sentry
        t1.input process
        t1.input cpu
        t1.output out, &out_output
        t1.output cpu, &cpu_output

        process.add AppProcess.new('process1')
        cpu.add CPU.new("CPU1_process1", 'process1')
      end

      let(:sentry) do
        proc do |marking_for, clock, result|
          marking_for[:process].each do |p|
            marking_for[:cpu].each(:process, p.value.name) do |c|
              result << { process: p, cpu: c }
            end
          end
        end
      end

      let(:out_output) do
        proc do |binding, clock|
          { val: binding[:process].value.name + "_done", ts: clock + 10 }
        end
      end

      let(:cpu_output) do
        proc do |binding, clock|
          binding[:cpu].with_timestamp clock + 100
        end
      end

      shared_examples 'error handler' do
        it "raises TCPN::SimulationError" do
          expect { tcpn.sim }.to raise_error FastTCPN::TCPN::SimulationError
        end

        context "when FastTCPN.debug is false" do
          it "does not put FastTCPN files in backtrace" do
            FastTCPN.debug = false
            error_raised = false
            begin
              tcpn.sim
            rescue FastTCPN::TCPN::SimulationError => e
              error_raised = true
              expect(e.backtrace.map { |b| b.sub /:.*$/,'' }.select{ |b| b =~ /\/lib\/fast-tcpn\// }).to be_empty
              expect(e.backtrace).not_to be_empty
            end
            expect(error_raised).to be true
          end
        end

        context "when FastTCPN.debug is true" do
          it "puts FastTCPN files in backtrace" do
            FastTCPN.debug = true
            error_raised = false
            begin
              tcpn.sim
            rescue FastTCPN::TCPN::SimulationError => e
              error_raised = true
              expect(e.backtrace.map { |b| b.sub /:.*$/,'' }.select{ |b| b =~ /\/lib\/fast-tcpn\// }).not_to be_empty
            end
            expect(error_raised).to be true
          end
        end
      end

      context "for invalid mapping from sentry" do
        let(:sentry) do
          proc do |marking_for, clock, result|
            marking_for[:process].each do |p|
              result << { process: p }
            end
          end
        end

        it_behaves_like 'error handler'
      end

      context "for NoMethodError inside simulator" do
        let(:out_output) do
          proc do |binding, clock|
            { val: binding[:process].value.name.no_such_method_exists , ts: clock + 10 }
          end
        end

        it_behaves_like 'error handler'
      end

    end
  end
end
