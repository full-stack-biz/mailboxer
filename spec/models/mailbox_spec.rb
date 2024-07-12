# frozen_string_literal: true

require 'spec_helper'

describe Mailboxer::Mailbox do
  before do
    @entity1 = create(:user)
    @entity2 = create(:user)
    @receipt1 = @entity1.send_message(@entity2, 'Body', 'Subject')
    @receipt2 = @entity2.reply_to_all(@receipt1, 'Reply body 1')
    @receipt3 = @entity1.reply_to_all(@receipt2, 'Reply body 2')
    @receipt4 = @entity2.reply_to_all(@receipt3, 'Reply body 3')
    @message1 = @receipt1.message
    @message4 = @receipt4.message
    @conversation = @message1.conversation
  end

  it 'returns conversations between two entities' do
    assert @entity1.mailbox.conversations_with(@entity2)

    expect(@entity1.mailbox.conversations_with(@entity2)).to eq [@conversation]
  end

  it 'returns all conversations' do
    @conv2 = @entity1.send_message(@entity2, 'Body', 'Subject').conversation
    @conv3 = @entity2.send_message(@entity1, 'Body', 'Subject').conversation
    @conv4 = @entity1.send_message(@entity2, 'Body', 'Subject').conversation

    assert @entity1.mailbox.conversations

    expect(@entity1.mailbox.conversations.to_a.size).to eq 4
    expect(@entity1.mailbox.conversations.to_a.count(@conversation)).to eq 1
    expect(@entity1.mailbox.conversations.to_a.count(@conv2)).to eq 1
    expect(@entity1.mailbox.conversations.to_a.count(@conv3)).to eq 1
    expect(@entity1.mailbox.conversations.to_a.count(@conv4)).to eq 1
  end

  it 'returns all mail' do
    assert @entity1.mailbox.receipts
    expect(@entity1.mailbox.receipts.count).to eq 4
    expect(@entity1.mailbox.receipts[0]).to eq Mailboxer::Receipt.recipient(@entity1).conversation(@conversation)[0]
    expect(@entity1.mailbox.receipts[1]).to eq Mailboxer::Receipt.recipient(@entity1).conversation(@conversation)[1]
    expect(@entity1.mailbox.receipts[2]).to eq Mailboxer::Receipt.recipient(@entity1).conversation(@conversation)[2]
    expect(@entity1.mailbox.receipts[3]).to eq Mailboxer::Receipt.recipient(@entity1).conversation(@conversation)[3]

    assert @entity2.mailbox.receipts
    expect(@entity2.mailbox.receipts.count).to eq 4
    expect(@entity2.mailbox.receipts[0]).to eq Mailboxer::Receipt.recipient(@entity2).conversation(@conversation)[0]
    expect(@entity2.mailbox.receipts[1]).to eq Mailboxer::Receipt.recipient(@entity2).conversation(@conversation)[1]
    expect(@entity2.mailbox.receipts[2]).to eq Mailboxer::Receipt.recipient(@entity2).conversation(@conversation)[2]
    expect(@entity2.mailbox.receipts[3]).to eq Mailboxer::Receipt.recipient(@entity2).conversation(@conversation)[3]
  end

  it 'returns sentbox' do
    assert @entity1.mailbox.receipts.inbox
    expect(@entity1.mailbox.receipts.sentbox.count).to eq 2
    expect(@entity1.mailbox.receipts.sentbox[0]).to eq @receipt1
    expect(@entity1.mailbox.receipts.sentbox[1]).to eq @receipt3

    assert @entity2.mailbox.receipts.inbox
    expect(@entity2.mailbox.receipts.sentbox.count).to eq 2
    expect(@entity2.mailbox.receipts.sentbox[0]).to eq @receipt2
    expect(@entity2.mailbox.receipts.sentbox[1]).to eq @receipt4
  end

  it 'returns inbox' do
    assert @entity1.mailbox.receipts.inbox
    expect(@entity1.mailbox.receipts.inbox.count).to eq 2
    expect(@entity1.mailbox.receipts.inbox[0]).to eq Mailboxer::Receipt.recipient(@entity1).inbox.conversation(@conversation)[0]
    expect(@entity1.mailbox.receipts.inbox[1]).to eq Mailboxer::Receipt.recipient(@entity1).inbox.conversation(@conversation)[1]

    assert @entity2.mailbox.receipts.inbox
    expect(@entity2.mailbox.receipts.inbox.count).to eq 2
    expect(@entity2.mailbox.receipts.inbox[0]).to eq Mailboxer::Receipt.recipient(@entity2).inbox.conversation(@conversation)[0]
    expect(@entity2.mailbox.receipts.inbox[1]).to eq Mailboxer::Receipt.recipient(@entity2).inbox.conversation(@conversation)[1]
  end

  it 'understands the read option' do
    expect(@entity1.mailbox.inbox({ read: false }).count).not_to eq 0
    @conversation.mark_as_read(@entity1)
    expect(@entity1.mailbox.inbox({ read: false }).count).to eq 0
  end

  it 'returns trashed mails' do
    @entity1.mailbox.receipts.move_to_trash

    assert @entity1.mailbox.receipts.trash
    expect(@entity1.mailbox.receipts.trash.count).to eq 4
    expect(@entity1.mailbox.receipts.trash[0]).to eq Mailboxer::Receipt.recipient(@entity1).conversation(@conversation)[0]
    expect(@entity1.mailbox.receipts.trash[1]).to eq Mailboxer::Receipt.recipient(@entity1).conversation(@conversation)[1]
    expect(@entity1.mailbox.receipts.trash[2]).to eq Mailboxer::Receipt.recipient(@entity1).conversation(@conversation)[2]
    expect(@entity1.mailbox.receipts.trash[3]).to eq Mailboxer::Receipt.recipient(@entity1).conversation(@conversation)[3]

    assert @entity2.mailbox.receipts.trash
    expect(@entity2.mailbox.receipts.trash.count).to eq 0
  end

  it 'deletes trashed mails' do
    @entity1.mailbox.receipts.move_to_trash
    @entity1.mailbox.empty_trash

    assert @entity1.mailbox.receipts.trash
    expect(@entity1.mailbox.receipts.trash.count).to eq 0

    assert @entity2.mailbox.receipts
    expect(@entity2.mailbox.receipts.count).to eq 4

    assert @entity2.mailbox.receipts.trash
    expect(@entity2.mailbox.receipts.trash.count).to eq 0
  end

  it 'deleteds messages are not shown in inbox' do
    assert @entity1.mailbox.receipts.inbox
    expect(@entity1.mailbox.inbox.count).to eq 1
    expect(@entity1.mailbox.receipts.inbox[0]).to eq Mailboxer::Receipt.recipient(@entity1).inbox.conversation(@conversation)[0]
    expect(@entity1.mailbox.receipts.inbox[1]).to eq Mailboxer::Receipt.recipient(@entity1).inbox.conversation(@conversation)[1]

    assert @entity1.mailbox.receipts.inbox.mark_as_deleted
    expect(@entity1.mailbox.inbox.count).to eq 0
  end

  it 'deleteds messages are not shown in sentbox' do
    assert @entity1.mailbox.receipts.inbox
    expect(@entity1.mailbox.receipts.sentbox.count).to eq 2
    expect(@entity1.mailbox.receipts.sentbox[0]).to eq @receipt1
    expect(@entity1.mailbox.receipts.sentbox[1]).to eq @receipt3

    assert @entity1.mailbox.receipts.sentbox.mark_as_deleted
    expect(@entity1.mailbox.sentbox.count).to eq 0
  end

  it 'replies for deleted messages return to inbox' do
    assert @entity1.mailbox.receipts.inbox
    expect(@entity1.mailbox.inbox.count).to eq 1
    expect(@entity1.mailbox.receipts.inbox[0]).to eq Mailboxer::Receipt.recipient(@entity1).inbox.conversation(@conversation)[0]
    expect(@entity1.mailbox.receipts.inbox[1]).to eq Mailboxer::Receipt.recipient(@entity1).inbox.conversation(@conversation)[1]

    assert @entity1.mailbox.receipts.inbox.mark_as_deleted
    expect(@entity1.mailbox.inbox.count).to eq 0

    @entity2.reply_to_all(@receipt1, 'Reply body 1')
    expect(@entity1.mailbox.inbox.count).to eq 1

    @entity2.reply_to_all(@receipt3, 'Reply body 3')
    expect(@entity1.mailbox.inbox.count).to eq 1
  end

  context 'STI models' do
    before do
      @sti_entity1 = create(:user)
      @sti_entity2 = create(:user)
      @sti_mail = @sti_entity1.send_message(@sti_entity2, 'Body', 'Subject')
    end

    it 'adds one to senders sentbox' do
      expect(@sti_entity1.mailbox.sentbox.count).to eq 1
      expect(@sti_entity1.mailbox.sentbox).to include(@sti_mail.conversation)
    end

    it 'adds one to recievers inbox' do
      expect(@sti_entity2.mailbox.inbox.count).to eq 1
      expect(@sti_entity2.mailbox.inbox).to include(@sti_mail.conversation)
    end
  end
end
