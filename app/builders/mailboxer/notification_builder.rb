# frozen_string_literal: true

module Mailboxer
  class NotificationBuilder < Mailboxer::BaseBuilder
    protected

    def klass
      Mailboxer::Notification
    end
  end
end
