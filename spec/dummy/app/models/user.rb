# frozen_string_literal: true

class User < ApplicationRecord
  acts_as_messageable
  def mailboxer_email(_object)
    email
  end
end
