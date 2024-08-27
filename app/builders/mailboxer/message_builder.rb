# frozen_string_literal: true

module Mailboxer
  class MessageBuilder < Mailboxer::BaseBuilder
    protected

    # @param attachments [Enumerable]
    def assign_attachments_field(object, attachments)
      # see https://edgeapi.rubyonrails.org/classes/ActiveStorage/Attached/Many.html#method-i-attach
      attachments.each do |attachment|
        case attachment
        when File
          object.attachments.attach(io: attachment, filename: File.basename(attachment.path))
        when Hash
          object.attachments.attach(io: attachment[:io], filename: attachment[:filename], content_type: attachment[:content_type])
        else # blob
          object.attachments.attach(attachment)
        end
      end
    end

    def klass
      Mailboxer::Message
    end
  end
end
