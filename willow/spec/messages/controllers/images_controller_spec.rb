require 'rails_helper'
require 'support/hyrax/session_helpers'
require 'support/notifications'
require 'support/jisc_rdss_schemas'

# NB: these tests require some files which cannot be committed to git (yet)
# In order to successfully run them, ensure the path "/willow/spec/fixtures/files/schemas/jisc_rdss/*" is in your
# .gitignore file.
#
# Then, copy the following files and folders to the given locations:
# *  https://github.com/JiscRDSS/rdss-message-api-docs/tree/master/messages  => willow/willow/spec/fixtures/files/schemas/jisc_rdss/messages
# *  https://github.com/JiscRDSS/rdss-message-api-docs/tree/master/schemas   => willow/willow/spec/fixtures/files/schemas/jisc_rdss/schemas
#
# Be sure that the files above are not committed to git!


describe Hyrax::ImagesController, :type => :controller do
  let(:depositor_user) { create(:user, email: 'josiah@example.com', title: 'Professor of Psychoceramics',
                                display_name: 'Josiah Carberry', orcid: '0000-0002-1825-0097' ) }
  let(:work) { create(:image_with_one_file,
                      user: depositor_user,
                      title: ['Do Mug Fairies Exist? An experiment in self-cleaning crockery'],
                      resource_type: ["Article"],
                      creator: ["Ed Pentz"],
                      description: ['The author set out to prove that if coffee or tea mugs are left in an office for ' +
                                        'long enough they will clean themselves. Previous research in this area suggest ' +
                                        'that this hypothesis is true, as the author has very infrequently had to resort ' +
                                        'to cleaning the mugs himself.'],
                      keyword: ["mug", "fairies", "psychoceramics"],
                      license: ["http://creativecommons.org/publicdomain/zero/1.0/"],
                      publisher: ["Society of Psychoceramics"],
                      date_created: ['2014-04-01'],
                      subject: ["Psychoceramics"],
                      language: ["English"],
                      import_url: 'true'
  ) }


  before :all do
    @validator = load_validator_with_jisc_rdss_schemas()
  end

  before :each do
    sign_in depositor_user
  end

  describe '#update' do
    let(:create_status) { true }
    let(:actor) { double(create: create_status) }

    before :each do
      allow(Hyrax::CurationConcern).to receive(:actor).and_return(actor)
      allow(controller).to receive(:curation_concern).and_return(work)
      allow_any_instance_of(Hyrax::Notifications::Subscribers::BuildMessage).to receive(:download_url).and_return('http://some.url.com/download/1')
      allow_any_instance_of(FileSet).to receive(:file_size).and_return([12345])
      allow_any_instance_of(FileSet).to receive(:original_checksum).and_return(['12345'])


      post :create, params: { work: { title: [''] } }
      @message = notification_message_for(Hyrax::Notifications::Events::METADATA_UPDATE) do
        # trigger the approve workflow message
        Hyrax::Notifications::Senders::Approve.call(target: work)
      end
      @messageHeader=@message[:messageHeader]
      @messageBody=@message[:messageBody]
      @messageBodyPayload=@messageBody[:payload]
      @jsonPayload=JSON.pretty_generate(@messageBodyPayload)
    end

    it 'schema validated payload' do
      expect(@jsonPayload).to_not be_nil

      expect(@validator.fully_validate(
          file_fixture("schemas/jisc_rdss/messages/metadata/update/request_schema.json").read,
          @jsonPayload)).to be_empty
    end

    it 'messageType is update' do
      expect(@messageHeader[:messageType]).to eql('MetadataUpdate')
    end

    it 'payload contains objectTitle' do
      expect(@messageBodyPayload[:objectTitle]).to eql('Do Mug Fairies Exist? An experiment in self-cleaning crockery')
    end
  end
end
