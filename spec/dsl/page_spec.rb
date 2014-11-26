require 'spec_helper'

describe FastTCPN::DSL::PageDSL do
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

  shared_examples "nested error handler" do
    it "includes subpage name in exception" do
      expect {
        load_model
      }.to raise_error FastTCPN::DSL::DSLError, /A sub page/
    end
  end

  describe "Error handling" do


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
      it_behaves_like "nested error handler"

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

  describe "created by #read" do
    include UsesTempFiles

    in_directory_with_file "models/example.rb"

    before do
      content_for_file "models/example.rb", <<-EOF
page "Example page" do
  p1 = place "input"
  p2 = place "output"
end
      EOF
    end

    let :model do
      FastTCPN.read "models/example.rb"
    end

    it "has places defined in file" do
      expect(model.find_place("input")).to be_kind_of FastTCPN::Place
      expect(model.find_place("output")).to be_kind_of FastTCPN::Place
    end

  end

  describe "#sub_page" do
    describe "correctly handles errors" do
      include UsesTempFiles

      in_directory_with_file "models/top_page.rb"
      in_directory_with_file "models/a_subpage.rb"

      before do
        content_for_file "models/top_page.rb", <<-EOF
  page "Example TCPN Page" do
    sub_page "a_subpage.rb"
  end
        EOF

        content_for_file "models/a_subpage.rb", <<-EOF
  page "A sub page" do
    p1 = place "subpage place"
    raise "An error occured"
  end
        EOF
      end

      let :load_model do
        FastTCPN.read 'models/top_page.rb'
      end

      it_behaves_like "error handler"
      it_behaves_like "nested error handler"
    end

    describe "correctly loads pages" do
      include UsesTempFiles

      in_directory_with_file "models/top_page.rb"
      in_directory_with_file "models/a_subpage.rb"

      before do
        content_for_file "models/top_page.rb", <<-EOF
  page "Example TCPN Page" do
    sub_page "a_subpage.rb"
    p1 = place "top page place"
    transition "send" do
      input p1
    end
  end
        EOF

        content_for_file "models/a_subpage.rb", <<-EOF
  page "A sub page" do
    p1 = place "sub page place"
    transition "work" do
      input p1
    end
  end
        EOF
      end

      let :model do
        FastTCPN.read 'models/top_page.rb'
      end

      it "has place from top page" do
        expect(model.find_place("top page place")).to be_kind_of FastTCPN::Place
      end

      it "has place from sub page" do
        expect(model.find_place("sub page place")).to be_kind_of FastTCPN::Place
      end

      it "has transition from top page" do
        expect(model.find_transition("send")).to be_kind_of FastTCPN::Transition
      end

      it "has transition from sub page" do
        expect(model.find_transition("work")).to be_kind_of FastTCPN::Transition
      end
    end

  end
end
