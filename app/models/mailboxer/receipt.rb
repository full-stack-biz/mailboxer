# frozen_string_literal: true

module Mailboxer
  class Receipt < ApplicationRecord
    self.table_name = :mailboxer_receipts
    attr_accessible :trashed, :is_read, :deleted if Mailboxer.protected_attributes?

    belongs_to :notification, class_name: 'Mailboxer::Notification', optional: true
    belongs_to :receiver, polymorphic: true, optional: true
    belongs_to :message, class_name: 'Mailboxer::Message', foreign_key: 'notification_id', optional: true

    validates :receiver, presence: true

    scope :recipient, lambda { |recipient|
      where(receiver_id: recipient.id, receiver_type: recipient.class.base_class.to_s)
    }
    # Notifications Scope checks type to be nil, not Notification because of STI behaviour
    # with the primary class (no type is saved)
    scope :notifications_receipts, -> { joins(:notification).where(mailboxer_notifications: { type: nil }) }
    scope :messages_receipts, lambda {
                                joins(:notification).where(mailboxer_notifications: { type: Mailboxer::Message.to_s })
                              }
    scope :notification, lambda { |notification|
      where(notification_id: notification.id)
    }
    scope :conversation, lambda { |conversation|
      joins(:message).where(mailboxer_notifications: { conversation_id: conversation.id })
    }
    scope :sentbox, -> { where(mailbox_type: 'sentbox') }
    scope :inbox, -> { where(mailbox_type: 'inbox') }
    scope :trash, -> { where(trashed: true, deleted: false) }
    scope :not_trash, -> { where(trashed: false) }
    scope :deleted, -> { where(deleted: true) }
    scope :not_deleted, -> { where(deleted: false) }
    scope :is_read, -> { where(is_read: true) }
    scope :is_unread, -> { where(is_read: false) }

    class << self
      # Marks all the receipts from the relation as read
      def mark_as_read(options = {})
        update_receipts({ is_read: true }, options)
      end

      # Marks all the receipts from the relation as unread
      def mark_as_unread(options = {})
        update_receipts({ is_read: false }, options)
      end

      # Marks all the receipts from the relation as trashed
      def move_to_trash(options = {})
        update_receipts({ trashed: true }, options)
      end

      # Marks all the receipts from the relation as not trashed
      def untrash(options = {})
        update_receipts({ trashed: false }, options)
      end

      # Marks the receipt as deleted
      def mark_as_deleted(options = {})
        update_receipts({ deleted: true }, options)
      end

      # Marks the receipt as not deleted
      def mark_as_not_deleted(options = {})
        update_receipts({ deleted: false }, options)
      end

      # Moves all the receipts from the relation to inbox
      def move_to_inbox(options = {})
        update_receipts({ mailbox_type: :inbox, trashed: false }, options)
      end

      # Moves all the receipts from the relation to sentbox
      def move_to_sentbox(options = {})
        update_receipts({ mailbox_type: :sentbox, trashed: false }, options)
      end

      def update_receipts(updates, options = {})
        ids = where(options).pluck(:id)
        Mailboxer::Receipt.where(id: ids).update_all(updates) unless ids.empty?
      end
    end

    # Marks the receipt as deleted
    def mark_as_deleted
      update(deleted: true)
    end

    # Marks the receipt as not deleted
    def mark_as_not_deleted
      update(deleted: false)
    end

    # Marks the receipt as read
    def mark_as_read
      update(is_read: true)
    end

    # Marks the receipt as unread
    def mark_as_unread
      update(is_read: false)
    end

    # Marks the receipt as trashed
    def move_to_trash
      update(trashed: true)
    end

    # Marks the receipt as not trashed
    def untrash
      update(trashed: false)
    end

    # Moves the receipt to inbox
    def move_to_inbox
      update(mailbox_type: :inbox, trashed: false)
    end

    # Moves the receipt to sentbox
    def move_to_sentbox
      update(mailbox_type: :sentbox, trashed: false)
    end

    # Returns the conversation associated to the receipt if the notification is a Message
    def conversation
      message.conversation if message.is_a? Mailboxer::Message
    end

    # Returns if the participant have read the Notification
    def is_unread?
      !is_read
    end

    # Returns if the participant have trashed the Notification
    def is_trashed?
      trashed
    end

    if Mailboxer.search_enabled
      case Mailboxer.search_engine
      when :litesearch
        include Litesearch::Model

        litesearch do |schema|
          schema.field :subject, target: 'mailboxer_notifications.subject', col: :subject
          schema.field :body, target: 'mailboxer_notifications.body', col: :body
          schema.tokenizer :trigram
        end
      when :pg_search
        include PgSearch
        pg_search_scope :search, associated_against: { message: { subject: 'A', body: 'B' } }, using: :tsearch
      else
        searchable do
          text :subject, boost: 5 do
            message&.subject
          end
          text :body do
            message&.body
          end
          integer :receiver_id
        end
      end
    end
  end
end
