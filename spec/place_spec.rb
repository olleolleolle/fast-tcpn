require 'spec_helper'

describe "FastTCPN::Place" do

  let(:place_class) { FastTCPN::Place }
  let(:marking_class) { FastTCPN::HashMarking }
  let(:keys) { { name: :name, valid: :valid? } }

  it_behaves_like 'valid place'
end
