# frozen_string_literal: true

require 'spec_helper'

describe Mailboxer::Conversation do
  let!(:entity1)  { create(:user) }
  let!(:entity2)  { create(:user) }
  let!(:receipt1) { entity1.send_message(entity2, 'Body', 'Subject') }
  let!(:receipt2) { entity2.reply_to_all(receipt1, 'Reply body 1') }
  let!(:receipt3) { entity1.reply_to_all(receipt2, 'Reply body 2') }
  let!(:receipt4) { entity2.reply_to_all(receipt3, 'Reply body 3') }
  let!(:message1) { receipt1.notification }
  let!(:message4) { receipt4.notification }
  let!(:conversation) { message1.conversation }

  it { is_expected.to validate_presence_of :subject }
  it { is_expected.to validate_length_of(:subject).is_at_most(Mailboxer.subject_max_length) }

  it 'has proper original message' do
    expect(conversation.original_message).to eq message1
  end

  it 'has proper originator (first sender)' do
    expect(conversation.originator).to eq entity1
  end

  it 'has proper last message' do
    expect(conversation.last_message).to eq message4
  end

  it 'has proper last sender' do
    expect(conversation.last_sender).to eq entity2
  end

  it 'has all conversation users' do
    expect(conversation.recipients.count).to eq 2
    expect(conversation.recipients.count).to eq 2
    expect(conversation.recipients.count(entity1)).to eq 1
    expect(conversation.recipients.count(entity2)).to eq 1
  end

  it 'is able to be marked as deleted' do
    conversation.move_to_trash(entity1)
    conversation.mark_as_deleted(entity1)
    expect(conversation).to be_is_deleted(entity1)
  end

  it 'is removed from the database once deleted by all participants' do
    conversation.mark_as_deleted(entity1)
    conversation.mark_as_deleted(entity2)
    expect(described_class.exists?(conversation.id)).to be false
  end

  it 'is able to be marked as read' do
    conversation.mark_as_read(entity1)
    expect(conversation).to be_is_read(entity1)
  end

  it 'is able to be marked as unread' do
    conversation.mark_as_read(entity1)
    conversation.mark_as_unread(entity1)
    expect(conversation).to be_is_unread(entity1)
  end

  it 'is able to add a new participant' do
    new_user = create(:user)
    conversation.add_participant(new_user)
    expect(conversation.participants.count).to eq 3
    expect(conversation.participants).to include(new_user, entity1, entity2)
    expect(conversation.receipts_for(new_user).count).to eq conversation.receipts_for(entity1).count
    expect(conversation.receipts_for(new_user).map(&:mailbox_type).uniq).to eq ['inbox']
  end

  it 'delivers messages to new participants' do
    new_user = create(:user)
    conversation.add_participant(new_user)
    expect do
      entity1.reply_to_all(receipt4, 'Reply body 4')
    end.to change { conversation.receipts_for(new_user).count }.by 1
  end

  describe 'scopes' do
    let(:participant) { create(:user) }
    let(:entity3) { create(:user) }
    let!(:inbox_conversation) { entity1.send_message(participant, 'Body', 'Subject').notification.conversation }
    let!(:sentbox_conversation) { participant.send_message(entity1, 'Body', 'Subject').notification.conversation }
    let!(:conversation_with_multiple_entities) do
      entity1.send_message([participant, entity3], 'Body', 'Subject').notification.conversation
    end

    describe '.participant' do
      it 'finds conversations with receipts for participant' do
        expect(described_class.participant(participant)).to eq [
          conversation_with_multiple_entities,
          sentbox_conversation,
          inbox_conversation
        ]
      end
    end

    describe '.inbox' do
      it 'finds inbox conversations with receipts for participant' do
        expect(described_class.inbox(participant)).to eq [
          conversation_with_multiple_entities,
          inbox_conversation
        ]
      end
    end

    describe '.sentbox' do
      it 'finds sentbox conversations with receipts for participant' do
        expect(described_class.sentbox(participant)).to eq [sentbox_conversation]
      end
    end

    describe '.trash' do
      it 'finds trash conversations with receipts for participant' do
        trashed_conversation = entity1.send_message(participant, 'Body', 'Subject').notification.conversation
        trashed_conversation.move_to_trash(participant)

        expect(described_class.trash(participant)).to eq [trashed_conversation]
      end
    end

    describe '.not_trash' do
      it 'finds non trashed conversations with receipts for participant' do
        trashed_conversation = entity1.send_message(participant, 'Body', 'Subject').notification.conversation
        trashed_conversation.move_to_trash(participant)

        expect(described_class.not_trash(participant)).to eq [conversation_with_multiple_entities,
                                                              sentbox_conversation, inbox_conversation]
      end
    end

    describe '.deleted' do
      it 'finds deleted conversations with receipts for participant' do
        deleted_conversation = entity1.send_message(participant, 'Body', 'Subject').notification.conversation
        deleted_conversation.mark_as_deleted(participant)

        expect(described_class.deleted(participant)).to eq [deleted_conversation]
      end
    end

    describe '.not_deleted' do
      it 'finds non deleted conversations with receipts for participant' do
        deleted_conversation = entity1.send_message(participant, 'Body', 'Subject').notification.conversation
        deleted_conversation.mark_as_deleted(participant)

        expect(described_class.not_deleted(participant).to_a).to eq [conversation_with_multiple_entities,
                                                                     sentbox_conversation, inbox_conversation]
      end
    end

    describe '.unread' do
      it 'finds unread conversations with receipts for participant' do
        [
          sentbox_conversation,
          inbox_conversation,
          conversation_with_multiple_entities
        ].each { |c| c.mark_as_read(participant) }
        unread_conversation = entity1.send_message(participant, 'Body', 'Subject').notification.conversation

        expect(described_class.unread(participant)).to eq [unread_conversation]
      end
    end

    describe '.between' do
      it 'finds conversations where two participants participate' do
        expect(described_class.between(entity1, participant)).to eq [
          conversation_with_multiple_entities,
          sentbox_conversation,
          inbox_conversation
        ]
      end

      it 'does not find conversations if the participants have not interacted yet' do
        expect(described_class.between(participant, entity2)).to eq []
      end
    end

    describe '.only_between' do
      it 'finds conversations where only two specific participants participate' do
        expect(described_class.only_between(entity1, participant).first).to eq sentbox_conversation
      end

      it 'does not find conversations if the participants have not interacted yet' do
        expect(described_class.between(participant, entity2)).to eq []
      end
    end
  end

  describe '#is_completely_trashed?' do
    it 'returns true if all receipts in conversation are trashed for participant' do
      conversation.move_to_trash(entity1)
      expect(conversation.is_completely_trashed?(entity1)).to be true
    end
  end

  describe '#is_deleted?' do
    it 'returns false if a recipient has not deleted the conversation' do
      expect(conversation.is_deleted?(entity1)).to be false
    end

    it 'returns true if a recipient has deleted the conversation' do
      conversation.mark_as_deleted(entity1)
      expect(conversation.is_deleted?(entity1)).to be true
    end
  end

  describe '#is_orphaned?' do
    it 'returns true if both participants have deleted the conversation' do
      conversation.mark_as_deleted(entity1)
      conversation.mark_as_deleted(entity2)
      expect(conversation.is_orphaned?).to be true
    end

    it 'returns false if one has not deleted the conversation' do
      conversation.mark_as_deleted(entity1)
      expect(conversation.is_orphaned?).to be false
    end
  end

  describe '#messages_for' do
    context 'before deleted' do
      it 'return all messages for user' do
        expect(conversation.messages_for(entity1).count).to eq 4
        expect(conversation.messages_for(entity2).count).to eq 4
      end
    end

    context 'after deleted' do
      before do
        conversation.mark_as_deleted(entity1)
      end

      it 'return no messages for user' do
        expect(conversation.messages_for(entity1).count).to eq 0
      end

      it 'return all messages for other user' do
        expect(conversation.messages_for(entity2).count).to eq 4
      end
    end

    context 'after deleted have have new messages' do
      before do
        conversation.mark_as_deleted(entity1)
        entity2.reply_to_conversation(conversation, 'Reply after deleted')
      end

      it 'return no messages for user' do
        expect(conversation.messages_for(entity1).count).to eq 1
      end
    end
  end

  describe '#opt_out' do
    context 'participant still opt in' do
      let(:opt_out) { conversation.opt_outs.first }

      it 'creates an opt_out object' do
        expect do
          conversation.opt_out(entity1)
        end.to change { conversation.opt_outs.count }.by 1
      end

      it 'creates opt out object linked to the proper conversation and participant' do
        conversation.opt_out(entity1)
        expect(opt_out.conversation).to eq conversation
        expect(opt_out.unsubscriber).to eq entity1
      end
    end

    context 'participant already opted out' do
      before do
        conversation.opt_out(entity1)
      end

      it 'does nothing' do
        expect do
          conversation.opt_out(entity1)
        end.not_to(change { conversation.opt_outs.count })
      end
    end
  end

  describe '#opt_out' do
    context 'participant already opt in' do
      it 'does nothing' do
        expect do
          conversation.opt_in(entity1)
        end.not_to(change { conversation.opt_outs.count })
      end
    end

    context 'participant opted out' do
      before do
        conversation.opt_out(entity1)
      end

      it 'destroys the opt out object' do
        expect do
          conversation.opt_in(entity1)
        end.to change { conversation.opt_outs.count }.by(-1)
      end
    end
  end

  describe '#subscriber?' do
    let(:action) { conversation.has_subscriber?(entity1) }

    context 'participant opted in' do
      it 'returns true' do
        expect(action).to be true
      end
    end

    context 'participant opted out' do
      before do
        conversation.opt_out(entity1)
      end

      it 'returns false' do
        expect(action).to be false
      end
    end
  end
end
