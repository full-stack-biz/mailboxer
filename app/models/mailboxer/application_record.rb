# frozen_string_literal: true

module Mailboxer
  class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
  end
end
