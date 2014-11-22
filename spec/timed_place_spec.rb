require 'spec_helper'

describe FastTCPN::TimedPlace, focus:true do

  let(:place_class) { FastTCPN::TimedPlace }
  let(:marking_class) { FastTCPN::TimedHashMarking }
  let(:keys) { { name: :name, valid: :valid? } }

  it_behaves_like 'valid place'
end
