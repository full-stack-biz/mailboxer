# frozen_string_literal: true

class Cylon < ApplicationRecord
  acts_as_messageable
  def mailboxer_email(_object)
    nil
  end
end
