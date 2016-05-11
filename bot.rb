#!/usr/bin/env ruby

require 'webshot'
require 'imgur'
require 'redditkit'

# monkey patch webshot gem until PR is accepted
module Webshot
  class Screenshot

    # Captures a screenshot of +url+ saving it to +path+.
    def capture(url, path, opts = {})
      begin
        # Default settings
        width   = opts.fetch(:width, 120)
        height  = opts.fetch(:height, 90)
        gravity = opts.fetch(:gravity, "north")
        quality = opts.fetch(:quality, 85)
        full = opts.fetch(:full, true)
        selector = opts.fetch(:selector, nil)
        nothumb = opts.fetch(:nothumb, false)
        allowed_status_codes = opts.fetch(:allowed_status_codes, [])

        # Reset session before visiting url
        Capybara.reset_sessions! unless @session_started
        @session_started = false

        # Open page
        visit url

        # Timeout
        sleep opts[:timeout] if opts[:timeout]

        # Check response code
        status_code = page.driver.status_code.to_i
        unless valid_status_code?(status_code, allowed_status_codes)
          fail WebshotError, "Could not fetch page: #{url.inspect}, error code: #{page.driver.status_code}"
        end
        tmp = Tempfile.new(["webshot", ".png"])
        tmp.close
        begin
          screenshot_opts = { full: full }
          screenshot_opts = screenshot_opts.merge({ selector: selector }) if selector

          # Save screenshot to file
          if nothumb
            page.driver.save_screenshot(path, screenshot_opts)
          else
            page.driver.save_screenshot(tmp.path, screenshot_opts)

            # Resize screenshot
            thumb = MiniMagick::Image.open(tmp.path)
            if block_given?
              # Customize MiniMagick options
              yield thumb
            else
              thumb.combine_options do |c|
                c.thumbnail "#{width}x"
                c.background "white"
                c.extent "#{width}x#{height}"
                c.gravity gravity
                c.quality quality
              end
            end
            # Save thumbnail
            thumb.write path
            thumb
          end
        ensure
          tmp.unlink
        end
      rescue Capybara::Poltergeist::StatusFailError, Capybara::Poltergeist::BrowserError, Capybara::Poltergeist::DeadClient, Capybara::Poltergeist::TimeoutError, Errno::EPIPE => e
        # TODO: Handle Errno::EPIPE and Errno::ECONNRESET
        raise WebshotError.new("Capybara error: #{e.message.inspect}")
      end
    end
  end
end

reddit = RedditKit::Client.new ENV['reddit-username'], ENV['reddit-password']
post = reddit.links('news', category: :new).first
page_url = post.url

ws = Webshot::Screenshot.instance
ws.capture page_url, 'snap.png', timeout: 3, nothumb: true #option only available in monkey-patched version
imgur = Imgur.new ENV['imgur-clientid']
image = Imgur::LocalImage.new './snap.png', title: post.domain
image_url = imgur.upload(image).link

comment = reddit.submit_comment post, "[Ad-free snapshot of the article.](#{image_url}) I am a bot. PM me bug reports/suggestions."
reddit.upvote post
puts comment.text
