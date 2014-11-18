require 'spec_helper'

class AppProcess
  attr_reader :name
  def initialize(name, finished)
    @name, @finished = name, finished
  end
  def finished?
    @finished
  end
end

describe FastTCPN::HashMarking do

  let :marking do
    FastTCPN::HashMarking.new name: :name, finished: :finished?
  end

  describe "without tokens" do
    describe "#keys" do
      shared_examples "keys defined in constructor" do
        it "returns keys defined in constructor" do
          expect(subject.keys[:name]).to eq :name
          expect(subject.keys[:finished]).to eq :finished?
        end
      end
      context "for just created marking" do
        subject { marking }

        include_examples "keys defined in constructor"

        it "has 2 keys" do
          expect(subject.keys.size).to eq 2
        end

      end

      context "for marking with keys added later" do
        subject do
          marking.add_keys val: :something, valid: :valid?
          marking
        end

        include_examples "keys defined in constructor"

        it "has 4 keys" do
          expect(subject.keys.size).to eq 4
        end

        it "returns the added keys" do
          expect(subject.keys[:val]).to eq :something
          expect(subject.keys[:valid]).to eq :valid?
        end

      end
    end
  end

  describe "with tokens" do

    let(:wget1) { AppProcess.new :wget1, true }
    let(:wget2) { AppProcess.new :wget2, true }
    let(:wget3) { AppProcess.new :wget3, false }

    subject do
      marking.add wget1
      marking.add wget2
      marking.add wget3
      marking
    end

    it "iterates over all tokens" do
      expect(subject.map { |t| t.value.name }).to match_array [wget1.name, wget2.name, wget3.name]
    end

    # FIXME: to small number of tokens in this test
    # this may fail once for some time, when two
    # shuffles return the same order of tokens...
    it "shuffles tokens for each iteration" do
      list1 = subject.map { |t| t.value.name }
      list2 = subject.map { |t| t.value.name }
      expect(list1).to match_array list2
      expect(list1).not_to eq list2
    end

    it "iterates over selected tokens" do
      expect(subject.each(:finished, true).map { |t| t.value.name }).to match_array [wget1.name, wget2.name]
    end

    it "clones tokens before they are returned" do
      expect(subject.each(:name, wget1.name).first.object_id).not_to eq(wget1.object_id)
    end


    describe "#add_keys" do
      it "raises error" do
        expect {
          subject.add_keys val: :something, valid: :valid?
        }.to raise_error FastTCPN::HashMarking::CannotAddKeys
      end
    end

=begin
this is obsolete... a hope!
use each and friends instead!

    describe "#by_name" do

      it "returns correct token for :wget1" do
        expect(subject.by_name(:wget1).first.value.name).to eq(wget1.name)
      end

      it "returns correct token for :wget2" do
        expect(subject.by_name(:wget2).first.value.name).to eq(wget2.name)
      end

      it "returns correct token for :wget3" do
        expect(subject.by_name(:wget3).first.value.name).to eq(wget3.name)
      end

    end

    describe "access by finished" do
      it "returns tokens with finished true for true param" do
        subject.by_finished(true).each do |token|
          expect(token.value.finished?).to be true
        end
      end
      it "returns tokens with finished false for false param" do
        subject.by_finished(false).each do |token|
          expect(token.value.finished?).to be false
        end
      end
    end
=end

    describe "#delete" do
      it "deletes tokens from 'name' list" do
        expect {
          subject.delete subject.each(:name, wget1.name).first
        }.to change(subject, :size).by(-1)
        expect(subject.each(:name, wget1.name).map { |t| t.value }).not_to include(wget1)
      end

      it "deletes from 'finished' list" do
        expect {
          subject.delete subject.each(:name, wget1.name).first
        }.to change(subject, :size).by(-1)
        expect(subject.each(:finished, wget1.finished?)).not_to include(wget1)
      end
    end

  end
end
