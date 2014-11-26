require 'spec_helper'

describe FastTCPN::DSL::PageDSL do
  describe "Error handling" do

    shared_examples "error handler" do
      it "wraps error in DSLError " do
        expect {
          load_model
        }.to raise_error FastTCPN::DSL::DSLError
      end

      it "includes page name in exception" do
        expect {
          load_model
        }.to raise_error FastTCPN::DSL::DSLError, /Example TCPN Page/
      end

      it "includes original message in exception" do
        expect {
          load_model
        }.to raise_error FastTCPN::DSL::DSLError, /An error occured/
      end
    end

    describe "simple page" do
      let :load_model do
        FastTCPN.model do
          page "Example TCPN Page" do
            raise "An error occured"
          end
        end
      end

      it_behaves_like "error handler"
    end

    describe "nested page" do
      let :load_model do
        FastTCPN.model do
          page "Example TCPN Page" do
            page "A sub page" do
              raise "An error occured"
            end
          end
        end
      end

      it_behaves_like "error handler"

      it "includes subpage name in exception" do
        expect {
          load_model
        }.to raise_error FastTCPN::DSL::DSLError, /A sub page/
      end
    end

  end

  describe "#place" do
    let :model do
      FastTCPN.model do
        page "First page" do
          p1 = place "input"
        end
      end
    end
    it "defines place in model" do
      expect(model.find_place "input").to be_kind_of FastTCPN::Place
    end
  end

  describe "#timed_place" do
    let :model do
      FastTCPN.model do
        page "First page" do
          p1 = timed_place "input"
        end
      end
    end
    it "defines timed place in model" do
      expect(model.find_place "input").to be_kind_of FastTCPN::TimedPlace
    end
  end
end
