describe FastTCPN::HashMarking do
  marking do
    HashMarking.new name: :name, finished: :finished?
  end

  class AppProcess
    attr_reader :name
    def initialize(name, finished)
      @name, @finished = name, finished
    end
    def finished?
      @finished
    end
  end

  describe "access by name" do
    subject do
      marking.add AppProcess :wget1, true
      marking.add AppProcess :wget2, true
      marking.add AppProcess :wget5, false
      marking
    end

    it "returns returns token with name :wget1 for :wget1 param" do
      expect(subject.name(:wget1).first.name).to eq(:wget1)
    end

    it "returns returns token with name :wget2 for :wget2 param" do
      expect(subject.name(:wget2).first.name).to eq(:wget2)
    end

    it "returns returns token with name :wget5 for :wget5 param" do
      expect(subject.name(:wget5).first.name).to eq(:wget5)
    end
  end

  describe "access by finished" do
    it "returns tokens with finished true for true param" do
      subject.finished(true).each do |token|
        expect(token.finished?).to be true
      end
    end
    it "returns tokens with finished false for false param" do
      subject.finished(false).each do |token|
        expect(token.finished?).to be false
      end
    end
  end

end
