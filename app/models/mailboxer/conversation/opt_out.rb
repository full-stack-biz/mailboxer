# frozen_string_literal: true

module Mailboxer
  class Conversation
    class OptOut < ApplicationRecord
      self.table_name = :mailboxer_conversation_opt_outs

      belongs_to :conversation, class_name: 'Mailboxer::Conversation', optional: true
      belongs_to :unsubscriber, polymorphic: true, optional: true

      validates :unsubscriber, presence: true

      scope :unsubscriber, lambda { |entity|
                             where(unsubscriber_type: entity.class.base_class.name, unsubscriber_id: entity.id)
                           }
    end
  end
end
