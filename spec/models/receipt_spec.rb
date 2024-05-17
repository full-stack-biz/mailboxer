# frozen_string_literal: true

require 'spec_helper'

describe Mailboxer::Receipt do
  before do
    @entity1 = create(:user)
    @entity2 = create(:user)
    @mail1 = @entity1.send_message(@entity2, 'Body', 'Subject')
  end

  it 'belongs to a message' do
    assert @mail1.message
  end

  it 'belongs to a conversation' do
    assert @mail1.conversation
  end

  it 'is able to be marked as unread' do
    expect(@mail1.is_read).to be true
    @mail1.mark_as_unread
    expect(@mail1.is_read).to be false
  end

  it 'is able to be marked as read' do
    expect(@mail1.is_read).to be true
    @mail1.mark_as_unread
    @mail1.mark_as_read
    expect(@mail1.is_read).to be true
  end

  it 'is able to be marked as deleted' do
    expect(@mail1.deleted).to be false
    @mail1.mark_as_deleted
    expect(@mail1.deleted).to be true
  end

  it 'is able to be marked as not deleted' do
    @mail1.deleted = true
    @mail1.mark_as_not_deleted
    expect(@mail1.deleted).to be false
  end

  context 'STI models' do
    before do
      @entity3 = create(:user)
      @entity4 = create(:user)
      @mail2 = @entity3.send_message(@entity4, 'Body', 'Subject')
    end

    it 'refers to the correct base class' do
      expect(@mail2.receiver_type).to eq @entity3.class.base_class.to_s
    end
  end
end
