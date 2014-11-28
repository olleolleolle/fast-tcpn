require 'spec_helper'

describe FastTCPN::Token do

  let(:token_class) { FastTCPN::Token }
  it_behaves_like 'token'

  describe "#to_hash" do
    it "returns valid reprsentation of token" do
      expect(token_class.new(:asd).to_hash).to eq({ val: :asd })
    end
  end
end
