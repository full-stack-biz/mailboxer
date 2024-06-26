# frozen_string_literal: true

class CreateDucks < ActiveRecord::Migration[4.2]
  def self.up
    create_table :ducks do |t|
      t.string :name
      t.string :email

      t.timestamps
    end
  end

  def self.down
    drop_table :ducks
  end
end
