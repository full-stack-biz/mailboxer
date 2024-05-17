# frozen_string_literal: true

require 'spec_helper'

describe Mailboxer::Message do
  before do
    ActionMailer::Base.deliveries.clear
    @entity1 = create(:user)
    @entity2 = create(:user)
  end

  context 'with errors' do
    describe 'empty subject' do
      before do
        @receipt1 = @entity1.send_message(@entity2, 'Body', '')
        @message1 = @receipt1.message
      end

      it 'adds errors to the created notification' do
        errors = @message1.errors['conversation.subject']

        expect(errors).to eq(["can't be blank"])
      end
    end
  end

  context 'after send' do
    before do
      ActionMailer::Base.deliveries.clear
      @entity1 = create(:user)
      @entity2 = create(:user)
      @receipt1 = @entity1.send_message(@entity2, 'Body', 'Subject')
      @message1 = @receipt1.message
    end

    it 'is able to be marked as deleted' do
      expect(@receipt1.deleted).to be false
      @message1.mark_as_deleted @entity1
      expect(@message1.is_deleted?(@entity1)).to be true
    end

    it 'creates a conversation' do
      expect(@message1.conversation).to eq(Mailboxer::Conversation.last)
    end

    it 'sends email only to receivers' do
      expect(ActionMailer::Base.deliveries.count).to eq 1
    end

    context 'and multiple replies' do
      before do
        @receipt2 = @entity2.reply_to_all(@receipt1, 'Reply body 1')
        @receipt3 = @entity1.reply_to_all(@receipt2, 'Reply body 2')
        @receipt4 = @entity2.reply_to_all(@receipt3, 'Reply body 3')
      end

      it 'has right recipients' do
        expect(@receipt1.message.recipients.count).to eq 2
        expect(@receipt2.message.recipients.count).to eq 2
        expect(@receipt3.message.recipients.count).to eq 2
        expect(@receipt4.message.recipients.count).to eq 2
      end
    end
  end
end
