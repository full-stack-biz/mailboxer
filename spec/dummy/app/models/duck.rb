# frozen_string_literal: true

class Duck < ApplicationRecord
  acts_as_messageable
  def mailboxer_email(object)
    case object
    when Mailboxer::Message
      nil
    when Mailboxer::Notification
      email
    end
  end
end
