shared_examples "valid place" do

  it "has name" do
    p = place_class.new "process"
    expect(p.name).to eq "process"
  end

  it "passes keys to marking constructor" do
    expect(marking_class).to receive(:new).with(keys)
    place_class.new "processes", keys
  end

  describe "when created" do
    subject do
      place_class.new "processes", keys
    end
    let(:token) { "for this example just anything" }
    let(:new_keys) { { node: :node_name, priority: :pri } }

    let :marking do
      marking = double(marking_class)
      mc = class_double(marking_class).as_stubbed_const(:transfer_nested_constants => true)
      allow(mc).to receive(:new).and_return(marking)
      marking
    end

    it "passes add to marking" do
      expect(marking).to receive(:add).with(token)
      subject.add token
    end

    it "passes delete to marking" do
      expect(marking).to receive(:delete).with(token)
      subject.delete token
    end

    it "passes add_keys to marking" do
      expect(marking).to receive(:add_keys).with(new_keys)
      subject.add_keys new_keys
    end

    it "passes keys to marking" do
      expect(marking).to receive(:keys)
      subject.keys
    end

    describe "net callback" do
      let(:net) { double Object, call_callbacks: nil  }
      let :place do
        place_class.new "process", {}, net
      end

      it "is called on :add" do
        expect(net).to receive(:call_callbacks).with(:place, :add, anything())
        place.add token
      end

      it "is called on :delete" do
        expect(net).to receive(:call_callbacks).with(:place, :delete, anything())
        allow(marking).to receive(:delete)
        place.delete token
      end
    end
  end

end
