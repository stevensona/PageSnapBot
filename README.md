# PageSnapBot
Reddit bot that comments a link to an imgur-hosted screenshot of posted article. I don't know much about reddit bots, and I am fairly sure my account got banned for spam.

## Usage notes
* Running the script (i.e. bot.rb) logs into reddit, takes a screenshot of the first link listed in "new" news subreddit and uploads it to imgur. It then comments a link to the image.
* Requires phantomjs to be in path.
* Used https://github.com/StevenBlack/hosts on the server to block ads from appearing in the screenshots.

## Todo
* Devise a better method for determining which articles to screencap (taking into consideration rate limits).
* Respond to specially formatted comments in articles requesting a screenshot to be taken
