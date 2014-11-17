require 'spec_helper'

describe FastTCPN::Token do

  it "stores value" do
    t = FastTCPN::Token.new "asd"
    expect(t.value).to eq "asd"
  end

  describe "#==" do
    it "is true for self" do
      t = FastTCPN::Token.new "asd"
      expect(t == t).to be true
    end

    it "is false for two different tokens, value does not matter" do
      t1 = FastTCPN::Token.new "asd"
      t2 = FastTCPN::Token.new "asd"
      expect(t1 == t2).to be false
    end

    it "it true for clones" do
      t1 = FastTCPN::Token.new "asd"
      t2 = t1.clone
      expect(t1 == t2).to be true
    end
  end
end
