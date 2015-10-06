using GitlabAwesomeRelease::ArrayWithinExt

describe GitlabAwesomeRelease::ArrayWithinExt do
  describe "#within" do
    subject { array.within(from_value, to_value) }

    let(:array)      { %w(v0.0.1 v0.0.2 v0.0.3 v0.0.4 v0.0.5) }
    let(:from_value) { "v0.0.2" }
    let(:to_value)   { "v0.0.4" }

    context "Successful" do
      it { should eq %w(v0.0.2 v0.0.3 v0.0.4) }
    end

    context "When invalid from_value" do
      let(:from_value) { "v0.0.0" }

      it { expect { subject }.to raise_error ArgumentError }
    end

    context "When invalid fo_value" do
      let(:to_value) { "v1.0.0" }

      it { expect { subject }.to raise_error ArgumentError }
    end
  end
end
