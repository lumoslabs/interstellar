# This is a hard fork of https://github.com/meduza-corp/interstellar. Enough changed, including the operational flow, that rather than attempting to break others, we just hard-forked.
---

# Interstellar

This will push your recent google play store reviews into slack

## How it works
Google Play [exports](https://support.google.com/googleplay/android-developer/answer/138230) all your app reviews once a day to the [Google Cloud Storage](https://cloud.google.com/storage/docs) bucket.

_Interstellar_ downloads reviews via google-cloud-storage api and triggers [Slack incoming webhook](https://api.slack.com/incoming-webhooks) for all new or updated reviews.

This works with clockwork for an easy "once every X minutes or days"

## ruby version
Ruby 2.5 has a regression bug in CVS https://github.com/ruby/csv/issues/23

use 2.4 until this is in stdlib

## Configuration

1. Set up your ENV variables (see .env.development for the ones that are needed)
2. Set up a service account on your google play developer console that has access to the reviews. We're using ENV['STORAGE_KEYFILE_JSON'] to store the credentials
3. docker build (this is configured for kubernetes, but it can be run anywhere that is docker friendly)

## Usage
Once configured - run `ruby sender.rb`

## License
This piece of software is distributed under 2-clause BSD license (that's what https://github.com/meduza-corp/interstellar is)
