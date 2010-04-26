# PhotoRoller

The PhotoRoller is designed to automate uploading the photo rolls (or "events"
as they're now called) from your iPhoto library to Gallery.  This is ideal for
those who want to maintain their library locally, then simply duplicate it to
Gallery for sharing or backup.  To export your iPhoto library to Gallery:

* Install the dependencies listed below
* Copy `config/account.yml.template` to `config/account.yml` and fill in the missing data
* Run `./roll_photos.rb`

## Features

* Create-only (Gallery Remote protocol supports neither updates nor deletes)
* Idempotent (re-run as often as you like to sync photos to Gallery)
* Uploads full-sized images
* Supports exclusion by keyword and media and image type
* Logs all images that were not uploaded to `rejects.csv` for manual resolution

## Gotchas

* Rename an album or image and a duplicate will be created with the new name
* Most common upload failure is caused by 2MB cap on uploads set in php.ini

## Dependencies

* Ruby
* (gallery-remote)[http://github.com/mrwalker/gallery-remote] gem
* (plist)[http://plist.rubyforge.org/] gem
