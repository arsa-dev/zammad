# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Whatsapp::Webhook::Message::Document, :aggregate_failures, current_user_id: 1 do
  describe '#process' do
    let(:channel) { create(:whatsapp_channel) }

    let(:from) do
      {
        phone: Faker::PhoneNumber.cell_phone_in_e164.delete('+'),
        name:  Faker::Name.unique.name,
      }
    end

    let(:json) do
      {
        object: 'whatsapp_business_account',
        entry:  [{
          id:      '222259550976437',
          changes: [{
            value: {
              messaging_product: 'whatsapp',
              metadata:          {
                display_phone_number: '15551340563',
                phone_number_id:      channel.options[:phone_number_id],
              },
              contacts:          [{
                profile: {
                  name: from[:name],
                },
                wa_id:   from[:phone],
              }],
              messages:          [{
                from:      from[:phone],
                id:        'wamid.HBgNNDkxNTE1NjA4MDY5OBUCABIYFjNFQjBDMUM4M0I5NDRFNThBMUQyMjYA',
                timestamp: '1707921703',
                document:  {
                  mime_type: 'application/pdf',
                  sha256:    'mi4AElysqJQ1Oc4pugVtrLKyiB+GLE/pzPEgtBsrcLk=',
                  id:        '1870770316696531',
                  filename:  'lorem-ipsum.pdf',
                },
                type:      'document',
              }],
            },
            field: 'messages',
          }],
        }],
      }.to_json
    end

    let(:data) { JSON.parse(json).deep_symbolize_keys }

    context 'when all data is valid' do
      let(:url)            { Faker::Internet.unique.url }
      let(:mime_type)      { 'application/pdf' }
      let(:media_content)  { SecureRandom.uuid }
      let(:media_file)     { Tempfile.create('lipsum.pdf').tap { |f| File.write(f, media_content) } }
      let(:valid_checksum) { Digest::SHA2.new(256).hexdigest(media_content) }

      let(:internal_response1) do
        Struct.new(:data, :error).new(Struct.new(:url, :mime_type, :sha256).new(url, mime_type, valid_checksum), nil)
      end

      let(:internal_response2) do
        Struct.new(:data, :error).new(Struct.new(:success).new(true), nil)
      end

      before do
        allow_any_instance_of(WhatsappSdk::Api::Medias).to receive(:media).and_return(internal_response1)
        allow_any_instance_of(WhatsappSdk::Api::Medias).to receive(:download).and_return(internal_response2)

        allow_any_instance_of(Whatsapp::Incoming::Media).to receive(:with_tmpfile).and_yield(media_file)
      end

      after do
        File.unlink(media_file)
      end

      it 'creates a user' do
        expect { described_class.new(data:, channel:).process }.to change(User, :count).by(1)
      end

      it 'creates a ticket + an article' do
        described_class.new(data:, channel:).process

        expect(Ticket.last).to have_attributes(
          title:    "New WhatsApp message from #{from[:name]} (+#{from[:phone]})",
          group_id: channel.group_id,
        )
        expect(Ticket.last.preferences).to include(
          channel_id: channel.id,
          whatsapp:   {
            from:      {
              phone_number: from[:phone],
              display_name: from[:name],
            },
            timestamp: '1707921703',
          },
        )

        expect(Ticket::Article.last).to have_attributes(
          body: '',
        )
        expect(Ticket::Article.last.preferences).to include(
          whatsapp: {
            entry_id:   '222259550976437',
            media_id:   '1870770316696531',
            message_id: 'wamid.HBgNNDkxNTE1NjA4MDY5OBUCABIYFjNFQjBDMUM4M0I5NDRFNThBMUQyMjYA',
            type:       'document',
          }
        )

        expect(Store.last).to have_attributes(
          filename: "#{Ticket.last.number}-1870770316696531.pdf",
          size:     media_file.size.to_s,
        )
        expect(Store.last.preferences).to include(
          'Mime-Type' => 'application/pdf',
        )
      end
    end

    context 'when the media type is not supported' do
      let(:url) { Faker::Internet.unique.url }
      let(:mime_type)      { 'application/zip' }
      let(:media_content)  { SecureRandom.uuid }
      let(:media_file)     { Tempfile.create('lipsum.zip').tap { |f| File.write(f, media_content) } }
      let(:valid_checksum) { Digest::SHA2.new(256).hexdigest(media_content) }

      let(:internal_response1) do
        Struct.new(:data, :error).new(Struct.new(:url, :mime_type, :sha256).new(url, mime_type, valid_checksum), nil)
      end

      before do
        allow_any_instance_of(WhatsappSdk::Api::Medias).to receive(:media).and_return(internal_response1)
      end

      after do
        File.unlink(media_file)
      end

      it 'creates an article with error information' do
        described_class.new(data:, channel:).process

        expect(Ticket::Article.last.body).to include('Invalid Media Type application/zip')
        expect(Ticket::Article.last.internal).to be_truthy
      end
    end
  end
end
