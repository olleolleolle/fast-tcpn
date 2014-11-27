require 'spec_helper'

describe FastTCPN::TimedToken do

  let(:token_class) { FastTCPN::TimedToken }
  it_behaves_like 'token'

  it "stores timestamp" do
    t = token_class.new "asd", 100
    expect(t.timestamp).to eq 100
  end

  it "has default timestamp seto to 0" do
    t = token_class.new "asd"
    expect(t.timestamp).to eq 0
  end

  describe "#==" do
    it "does not care for timestamp" do
      t1 = token_class.new "asd", 100
      t2 = t1.clone
      t2.timestamp = 200
      expect(t1 == t2).to be true
    end
  end

  describe "#with_timestamp" do
    let(:t1) { token_class.new "asd", 100 }
    let(:t2) { t1.with_timestamp 1000 }

    it "returns token with the same value" do
      expect(t2.value).to eq t1.value
    end

    it "returns token with new timestamp" do
      expect(t2.timestamp).to eq 1000
    end

    it "returns token that is not equal to self" do
      expect(t1 == t2).not_to be true
    end
  end

  describe "#to_hash" do
    it "returns valid reprsentation of token" do
      expect(token_class.new(:asd, 200).to_hash).to eq({ val: :asd, ts: 200 })
    end
  end

end
