Builds an animated map of video views from ted.com data.

<iframe
  width="560" height="315"
  src="http://www.youtube.com/embed/omO3fr0XuhY"
  frameborder="0" allowfullscreen>
</iframe>

## Overview

**I can't release raw ted.com view data, so please don't ask. Sorry!**

This is published mainly as a reference for your own Processing and ruby-processing
projects, to show you how I created the map that you see.

There are definitely rough edges, butt shouldn't be too hard to use some of the
stuff here to build your own maps from your own data. Feel free to open issues &
ask me questions if you want to. If it sounds like some of this would be useable
by a few people, I can probably package some of it as a gem.

## Installing pre-requisites
`bundle install` will get you all the ruby libs you need.
`rake jars:install` will download & install the needed java libraries.

Postgres & PostGIS are used to process the data. You can get installation instructions
for PostGIS at http://postgis.refractions.net/documentation/. On OSX, `brew install postgis`
works pretty nicely.

## General flow
All raw data (IP geolocation data, video views data, and some metadata about the
talks) is dropped into the `raw_data` directory. Some rake tasks ingest & manipulate
the raw data and produce csv files in the `generated_data` directory. The main
ruby-processing sketch looks for a file in `generated_data` to use for animation.

## Generating data for animation
I ran `rake base_data:load output:by_talk_age` to build the `generated_data/final.csv`
which was used in the animation you see.

