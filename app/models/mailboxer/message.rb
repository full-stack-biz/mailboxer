# frozen_string_literal: true

module Mailboxer
  class Message < Mailboxer::Notification
    # attr_accessible :attachment if Mailboxer.protected_attributes?
    attr_accessible :attachments if Mailboxer.protected_attributes?
    self.table_name = :mailboxer_notifications

    belongs_to :conversation, validate: true, autosave: true
    has_many :receipts, dependent: :destroy, class_name: 'Mailboxer::Receipt', inverse_of: :message
    validates :sender, :body, presence: true

    class_attribute :on_deliver_callback
    protected :on_deliver_callback
    scope :conversation, lambda { |conversation|
      where(conversation_id: conversation.id)
    }

    # has_one_attached :attachment
    has_many_attached :attachments
    # mount_uploader :carrierwave_attachment, Mailboxer::AttachmentUploader

    class << self
      # Sets the on deliver callback method.
      def on_deliver(callback_method)
        self.on_deliver_callback = callback_method
      end
    end

    # Delivers a Message. USE NOT RECOMENDED.
    # Use Mailboxer::Models::Message.send_message instead.
    def deliver(reply = false, should_clean = true, with_email = true)
      clean if should_clean

      # Receiver receipts
      receiver_receipts = recipients.map do |r|
        receipts.build(receiver: r, mailbox_type: 'inbox', is_read: false)
      end

      # Sender receipt
      sender_receipt =
        receipts.build(receiver: sender, mailbox_type: 'sentbox', is_read: true)

      if valid?
        save!
        Mailboxer::MailDispatcher.new(self, receiver_receipts).call if with_email

        conversation.touch if reply

        self.recipients = nil

        on_deliver_callback&.call(self)
      end
      sender_receipt
    end
  end
end
