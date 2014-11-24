class Worker
  attr_reader :name
  def initialize(name, finished)
    @name, @finished = name, finished
  end
  def finished?
    @finished
  end
end

shared_examples 'hash marking' do

  let :marking do
    marking_class.new name: :name, finished: :finished?
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

    let(:wget1) { Worker.new :wget1, true }
    let(:wget2) { Worker.new :wget2, true }
    let(:wget3) { Worker.new :wget3, false }

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

      it "returns deleted token" do
        to_delete = subject.each(:name, wget1.name).first
        expect(subject.delete to_delete).to eq to_delete
      end

      it "returns nil if nothing was deleted" do
        already_deleted = subject.delete subject.each(:name, wget1.name).first
        expect(subject.delete already_deleted).to eq nil
      end
    end

  end

  it "works for Symbols" do
    expect {
      marking_class.new.add :asd
    }.not_to raise_error
  end

  it "works for Procs" do
    expect {
      marking_class.new.add(proc {})
    }.not_to raise_error
  end

  it "works for Fixnums" do
    expect {
      marking_class.new.add(123)
    }.not_to raise_error
  end

  Klazz = Struct.new(:name, :id)
  it "works for Structs" do
    expect {
      marking_class.new.add(Klazz.new)
    }.not_to raise_error
  end

  it "works for anonymous Structs" do
    expect {
      marking_class.new.add(Struct.new(:name, :id).new)
    }.not_to raise_error
  end

  it "works for nil" do
    expect {
      marking_class.new.add(nil)
    }.not_to raise_error
  end
end

