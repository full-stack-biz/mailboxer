# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20_210_521_115_002) do
  create_table 'active_storage_attachments', force: :cascade do |t|
    t.string 'name', null: false
    t.string 'record_type', null: false
    t.integer 'record_id', null: false
    t.integer 'blob_id', null: false
    t.datetime 'created_at', null: false
    t.index ['blob_id'], name: 'index_active_storage_attachments_on_blob_id'
    t.index %w[record_type record_id name blob_id], name: 'index_active_storage_attachments_uniqueness',
                                                    unique: true
  end

  create_table 'active_storage_blobs', force: :cascade do |t|
    t.string 'key', null: false
    t.string 'filename', null: false
    t.string 'content_type'
    t.text 'metadata'
    t.integer 'byte_size', null: false
    t.string 'checksum', null: false
    t.datetime 'created_at', null: false
    t.string 'service_name', null: false
    t.index ['key'], name: 'index_active_storage_blobs_on_key', unique: true
  end

  create_table 'active_storage_variant_records', force: :cascade do |t|
    t.bigint 'blob_id', null: false
    t.string 'variation_digest', null: false
    t.index %w[blob_id variation_digest], name: 'index_active_storage_variant_records_uniqueness', unique: true
  end

  create_table 'cylons', force: :cascade do |t|
    t.string 'name'
    t.string 'email'
    t.datetime 'created_at'
    t.datetime 'updated_at'
  end

  create_table 'ducks', force: :cascade do |t|
    t.string 'name'
    t.string 'email'
    t.datetime 'created_at'
    t.datetime 'updated_at'
  end

  create_table 'mailboxer_conversation_opt_outs', force: :cascade do |t|
    t.string 'unsubscriber_type'
    t.integer 'unsubscriber_id'
    t.integer 'conversation_id'
    t.index ['conversation_id'], name: 'index_mailboxer_conversation_opt_outs_on_conversation_id'
    t.index %w[unsubscriber_id unsubscriber_type],
            name: 'index_mailboxer_conversation_opt_outs_on_unsubscriber_id_type'
  end

  create_table 'mailboxer_conversations', force: :cascade do |t|
    t.string 'subject', default: ''
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'mailboxer_notifications', force: :cascade do |t|
    t.string 'type'
    t.text 'body'
    t.string 'subject', default: ''
    t.string 'sender_type'
    t.integer 'sender_id'
    t.integer 'conversation_id'
    t.boolean 'draft', default: false
    t.string 'notification_code'
    t.string 'notified_object_type'
    t.integer 'notified_object_id'
    t.string 'attachment'
    t.datetime 'updated_at', null: false
    t.datetime 'created_at', null: false
    t.boolean 'global', default: false
    t.datetime 'expires'
    t.index ['conversation_id'], name: 'index_mailboxer_notifications_on_conversation_id'
    t.index %w[notified_object_id notified_object_type],
            name: 'index_mailboxer_notifications_on_notified_object_id_and_type'
    t.index %w[notified_object_type notified_object_id], name: 'mailboxer_notifications_notified_object'
    t.index %w[sender_id sender_type], name: 'index_mailboxer_notifications_on_sender_id_and_sender_type'
    t.index ['type'], name: 'index_mailboxer_notifications_on_type'
  end

  create_table 'mailboxer_receipts', force: :cascade do |t|
    t.string 'receiver_type'
    t.integer 'receiver_id'
    t.integer 'notification_id', null: false
    t.boolean 'is_read', default: false
    t.boolean 'trashed', default: false
    t.boolean 'deleted', default: false
    t.string 'mailbox_type', limit: 25
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.boolean 'is_delivered', default: false
    t.string 'delivery_method'
    t.string 'message_id'
    t.index ['notification_id'], name: 'index_mailboxer_receipts_on_notification_id'
    t.index %w[receiver_id receiver_type], name: 'index_mailboxer_receipts_on_receiver_id_and_receiver_type'
  end

  create_table 'users', force: :cascade do |t|
    t.string 'name'
    t.string 'email'
    t.datetime 'created_at'
    t.datetime 'updated_at'
  end

  add_foreign_key 'active_storage_attachments', 'active_storage_blobs', column: 'blob_id'
  add_foreign_key 'active_storage_variant_records', 'active_storage_blobs', column: 'blob_id'
  add_foreign_key 'mailboxer_conversation_opt_outs', 'mailboxer_conversations', column: 'conversation_id'
  add_foreign_key 'mailboxer_notifications', 'mailboxer_conversations', column: 'conversation_id'
  add_foreign_key 'mailboxer_receipts', 'mailboxer_notifications', column: 'notification_id'
end
