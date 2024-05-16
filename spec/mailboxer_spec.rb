# frozen_string_literal: true

require 'spec_helper'

describe Mailboxer do
  it 'is valid' do
    expect(described_class).to be_a(Module)
  end
end
