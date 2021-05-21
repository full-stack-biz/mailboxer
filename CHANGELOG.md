# CHANGELOG

## Master (Unreleased)

### Breaking changes
* Add support for multiple attachments instead of one, thanks to @nhinze
* Replace Carrierwave support with ActiveStorage, thanks to @nhinze

### Changed

* Replace deprecated `update_attributes` with `update`, thanks to @booleanbetrayal

### Removed

* Drop test runs for Ruby 2.2.x and 2.3.x, thanks to @rockdog

### Added

* Rails 5.2 testing support, thanks to @rockdog
* Rails 6 testing support, thanks to @rockdog
* Add "not_trashed" example to README, thanks to @fastengineer
* Add `deleted`, `not_deleted` scopes, thanks to @afamyial
* Add `with_email` option to allow not sending an email via send_message, thanks to @KaoruDev

### Fixed

* Fix typo in README, thanks to @MarkFChavez
* Fixed set `mailbox_type` to `inbox` after doing `add_participant`, closes https://github.com/mailboxer/mailboxer/issues/393. Thanks goes to @jerefrer
* Fixed for Rails 6, add `optional:true` to several belongs_to relationships, closes https://github.com/mailboxer/mailboxer/issues/509. Thanks to @kevinjbayer

## 0.15.0 - 2017-05-17

### Changed

* Update for Rails 5.1

* When sorting entries by `created_at`, also sort by `id` descending. This
is to ensure proper sorting of items for databases that do not store
nanoseconds for timestamp columns.

### Fixed

* When trying to delete a Mailboxer object, a `NameError` may be thrown due
to a missing namespace

## 0.14.0 - 2016-07-29

### Added

* Rails 5 compatibility.

### Fixed

* `Mailboxer::Message` object no longer requires to have a subject.
* Objects are now saved before mails are sent, you you can use them in the
mailer templates (to build URLs, for example).

### Changed

* Errors are now stored in the parent message/notification instead of being
stored in the sender receipt. That means you need handle mailboxer related
controller and views differently, and study the upgrade case by case (propably
by having a look at mailboxer's source code). As an example, if you were
previously doing something like this in your controller:

```
@receipt = @actor.send_message(@recipients, params[:body], params[:subject])
if (@receipt.errors.blank?)
  @conversation = @receipt.conversation
  redirect_to conversation_path(@conversation)
else
  render :action => :new
end
```

you now need to do something like

```
@receipt = @actor.send_message(@recipients, params[:body], params[:subject])
@message = @receipt.message
if (@message.errors.blank?)
  @conversation = @message.conversation
  redirect_to conversation_path(@conversation)
else
  render :action => :new
end
```

This might look more complicated at first but allows you to build more RESTful
resources since you can build forms on messages and/or conversations and
directly show errors on them. Less specially handling is now required to
propagate errors around models.
