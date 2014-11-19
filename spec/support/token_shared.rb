shared_examples 'token' do

  it "stores value" do
    t = token_class.new "asd"
    expect(t.value).to eq "asd"
  end

  describe "#==" do
    it "is true for self" do
      t = token_class.new "asd"
      expect(t == t).to be true
    end

    it "is false for two different tokens, value does not matter" do
      t1 = token_class.new "asd"
      t2 = token_class.new "asd"
      expect(t1 == t2).to be false
    end

    it "it true for clones" do
      t1 = token_class.new "asd"
      t2 = t1.clone
      expect(t1 == t2).to be true
    end
  end

end
