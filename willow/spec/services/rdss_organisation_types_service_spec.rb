require 'rails_helper'

describe RdssOrganisationTypesService do
  before do
    # Configure QA to use fixtures
    qa_fixtures = { local_path: File.expand_path('../../../config/authorities', __FILE__) }
    allow(Qa::Authorities::Local).to receive(:config).and_return(qa_fixtures)
  end

  describe "#select_all_options" do
    it "returns all terms" do
      expect(described_class.select_all_options).to include(
        ["furtherEducation", 'furtherEducation'])
    end
  end

  describe "#label" do
    it "resolves for ids of all terms" do
      expect(described_class.label('research')).to eq("research")
    end
  end
end
