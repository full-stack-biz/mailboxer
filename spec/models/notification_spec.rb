# frozen_string_literal: true

require 'spec_helper'

describe Mailboxer::Notification do
  before do
    @entity1 = create(:user)
    @entity2 = create(:user)
    @entity3 = create(:user)
  end

  it { is_expected.to validate_presence_of :body }

  it { is_expected.to validate_length_of(:subject).is_at_most(Mailboxer.subject_max_length) }
  it { is_expected.to validate_length_of(:body).is_at_most(Mailboxer.body_max_length) }

  it 'notifies one user' do
    @entity1.send(Mailboxer.notify_method, 'Subject', 'Body')

    # Check getting ALL receipts
    expect(@entity1.mailbox.receipts.size).to eq 1
    receipt      = @entity1.mailbox.receipts.first
    notification = receipt.notification
    expect(notification.subject).to eq 'Subject'
    expect(notification.body).to eq 'Body'

    # Check getting NOTIFICATION receipts only
    expect(@entity1.mailbox.notifications.size).to eq 1
    notification = @entity1.mailbox.notifications.first
    expect(notification.subject).to eq 'Subject'
    expect(notification.body).to eq 'Body'
  end

  it 'is unread by default' do
    @entity1.send(Mailboxer.notify_method, 'Subject', 'Body')
    expect(@entity1.mailbox.receipts.size).to eq 1
    notification = @entity1.mailbox.receipts.first.notification
    expect(notification).to be_is_unread(@entity1)
  end

  it 'is able to marked as read' do
    @entity1.send(Mailboxer.notify_method, 'Subject', 'Body')
    expect(@entity1.mailbox.receipts.size).to eq 1
    notification = @entity1.mailbox.receipts.first.notification
    notification.mark_as_read(@entity1)
    expect(notification).to be_is_read(@entity1)
  end

  it 'is able to specify a sender for a notification' do
    @entity1.send(Mailboxer.notify_method, 'Subject', 'Body', nil, true, nil, true, @entity3)
    expect(@entity1.mailbox.receipts.size).to eq 1
    notification = @entity1.mailbox.receipts.first.notification
    expect(notification.sender).to eq(@entity3)
  end

  it 'notifies several users' do
    recipients = [@entity1, @entity2, @entity3]
    described_class.notify_all(recipients, 'Subject', 'Body')
    # Check getting ALL receipts
    expect(@entity1.mailbox.receipts.size).to eq 1
    receipt      = @entity1.mailbox.receipts.first
    notification = receipt.notification
    expect(notification.subject).to eq 'Subject'
    expect(notification.body).to eq 'Body'
    expect(@entity2.mailbox.receipts.size).to eq 1
    receipt      = @entity2.mailbox.receipts.first
    notification = receipt.notification
    expect(notification.subject).to eq 'Subject'
    expect(notification.body).to eq 'Body'
    expect(@entity3.mailbox.receipts.size).to eq 1
    receipt      = @entity3.mailbox.receipts.first
    notification = receipt.notification
    expect(notification.subject).to eq 'Subject'
    expect(notification.body).to eq 'Body'

    # Check getting NOTIFICATION receipts only
    expect(@entity1.mailbox.notifications.size).to eq 1
    notification = @entity1.mailbox.notifications.first
    expect(notification.subject).to eq 'Subject'
    expect(notification.body).to eq 'Body'
    expect(@entity2.mailbox.notifications.size).to eq 1
    notification = @entity2.mailbox.notifications.first
    expect(notification.subject).to eq 'Subject'
    expect(notification.body).to eq 'Body'
    expect(@entity3.mailbox.notifications.size).to eq 1
    notification = @entity3.mailbox.notifications.first
    expect(notification.subject).to eq 'Subject'
    expect(notification.body).to eq 'Body'
  end

  it 'notifies a single recipient' do
    described_class.notify_all(@entity1, 'Subject', 'Body')

    # Check getting ALL receipts
    expect(@entity1.mailbox.receipts.size).to eq 1
    receipt      = @entity1.mailbox.receipts.first
    notification = receipt.notification
    expect(notification.subject).to eq 'Subject'
    expect(notification.body).to eq 'Body'

    # Check getting NOTIFICATION receipts only
    expect(@entity1.mailbox.notifications.size).to eq 1
    notification = @entity1.mailbox.notifications.first
    expect(notification.subject).to eq 'Subject'
    expect(notification.body).to eq 'Body'
  end

  it 'is able to specify a sender for a notification' do
    described_class.notify_all(@entity1, 'Subject', 'Body', nil, true, nil, false, @entity3)

    # Check getting ALL receipts
    expect(@entity1.mailbox.receipts.size).to eq 1
    receipt      = @entity1.mailbox.receipts.first
    notification = receipt.notification
    expect(notification.subject).to eq 'Subject'
    expect(notification.body).to eq 'Body'
    expect(notification.sender).to eq @entity3

    # Check getting NOTIFICATION receipts only
    expect(@entity1.mailbox.notifications.size).to eq 1
    notification = @entity1.mailbox.notifications.first
    expect(notification.subject).to eq 'Subject'
    expect(notification.body).to eq 'Body'
    expect(notification.sender).to eq @entity3
  end

  describe 'scopes' do
    let(:scope_user) { create(:user) }
    let!(:notification) { scope_user.send(Mailboxer.notify_method, 'Body', 'Subject').notification }

    describe '.unread' do
      it 'finds unread notifications' do
        unread_notification = scope_user.send(Mailboxer.notify_method, 'Body', 'Subject').notification
        notification.mark_as_read(scope_user)
        expect(described_class.unread.last).to eq unread_notification
      end
    end

    describe '.expired' do
      it 'finds expired notifications' do
        notification.update(expires: 1.day.ago)
        expect(scope_user.mailbox.notifications.expired.count).to eq(1)
      end
    end

    describe '.unexpired' do
      it 'finds unexpired notifications' do
        notification.update(expires: 1.day.from_now)
        expect(scope_user.mailbox.notifications.unexpired.count).to eq(1)
      end
    end
  end

  describe '#expire' do
    subject { described_class.new }

    describe 'when the notification is already expired' do
      before do
        allow(subject).to receive(:expired?).and_return(true)
      end

      it 'does not update the expires attribute' do
        expect(subject).not_to receive :expires=
        expect(subject).not_to receive :save
        subject.expire
      end
    end

    describe 'when the notification is not expired' do
      let(:now) { Time.zone.now }
      let(:one_second_ago) { now - 1.second }

      before do
        allow(Time).to receive(:now).and_return(now)
        allow(subject).to receive(:expired?).and_return(false)
      end

      it 'updates the expires attribute' do
        expect(subject).to receive(:expires=).with(one_second_ago)
        subject.expire
      end

      it 'does not save the record' do
        expect(subject).not_to receive :save
        subject.expire
      end
    end
  end

  describe '#expire!' do
    subject { described_class.new }

    describe 'when the notification is already expired' do
      before do
        allow(subject).to receive(:expired?).and_return(true)
      end

      it 'does not call expire' do
        expect(subject).not_to receive :expire
        expect(subject).not_to receive :save
        subject.expire!
      end
    end

    describe 'when the notification is not expired' do
      let(:now) { Time.zone.now }
      let(:one_second_ago) { now - 1.second }

      before do
        allow(Time).to receive(:now).and_return(now)
        allow(subject).to receive(:expired?).and_return(false)
      end

      it 'calls expire' do
        expect(subject).to receive(:expire)
        subject.expire!
      end

      it 'saves the record' do
        expect(subject).to receive :save
        subject.expire!
      end
    end
  end

  describe '#expired?' do
    subject { described_class.new }

    context 'when the expiration date is in the past' do
      before { allow(subject).to receive(:expires).and_return(1.second.ago) }

      it 'is expired' do
        expect(subject.expired?).to be true
      end
    end

    context 'when the expiration date is now' do
      before do
        time = Time.zone.now
        allow(Time).to receive(:now).and_return(time)
        allow(subject).to receive(:expires).and_return(time)
      end

      it 'is not expired' do
        expect(subject.expired?).to be false
      end
    end

    context 'when the expiration date is in the future' do
      before { allow(subject).to receive(:expires).and_return(1.second.from_now) }

      it 'is not expired' do
        expect(subject.expired?).to be false
      end
    end

    context 'when the expiration date is not set' do
      before { allow(subject).to receive(:expires).and_return(nil) }

      it 'is not expired' do
        expect(subject.expired?).to be false
      end
    end
  end
end
