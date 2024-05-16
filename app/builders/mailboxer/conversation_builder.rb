# frozen_string_literal: true

module Mailboxer
  class ConversationBuilder < Mailboxer::BaseBuilder
    protected

    def klass
      Mailboxer::Conversation
    end
  end
end
