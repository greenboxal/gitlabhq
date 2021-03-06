require 'spec_helper'

describe ExternalWikiService, models: true do
  include ExternalWikiHelper
  describe "Associations" do
    it { should belong_to :project }
    it { should have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      before { subject.active = true }

      it { is_expected.to validate_presence_of(:external_wiki_url) }
      it_behaves_like 'issue tracker service URL attribute', :external_wiki_url
    end

    context 'when service is inactive' do
      before { subject.active = false }

      it { is_expected.not_to validate_presence_of(:external_wiki_url) }
    end
  end

  describe 'External wiki' do
    let(:project) { create(:project) }

    context 'when it is active' do
      before do
        properties = { 'external_wiki_url' => 'https://doggohub.com' }
        @service = project.create_external_wiki_service(active: true, properties: properties)
      end

      after do
        @service.destroy!
      end

      it 'replaces the wiki url' do
        wiki_path = get_project_wiki_path(project)
        expect(wiki_path).to match('https://doggohub.com')
      end
    end
  end
end
