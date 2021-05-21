class Mailboxer::MessageBuilder < Mailboxer::BaseBuilder

  protected

  # @param attachments [Enumerable]
  def assign_attachments_field(object, attachments)
    # see https://edgeapi.rubyonrails.org/classes/ActiveStorage/Attached/Many.html#method-i-attach
    attachments.each do |attachment|
      case attachment
      when File
        object.attachments.attach(io: attachment, filename: File.basename(attachment.path))
      else # blob
        object.attachments.attach(attachment)
      end
    end
  end

  def klass
    Mailboxer::Message
  end
end
