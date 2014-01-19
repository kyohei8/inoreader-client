require 'httparty'
require 'json'
module InoreaderApi

  class InoreaderApiError < StandardError;
  end

  class Api
    class << self
      # Authenticate, to return authKey
      # @param un username or Email
      # @param pw Password
      # @return AuthKey If successfully authenticated, and nil if it fails
      # TODO 500, 404チェック
      def auth(un, pw)
        response_body = ApiHelper.auth_request un, pw
        if response_body.nil? or response_body.start_with?('Error')
          nil
        else
          Hash[*response_body.split.collect { |i| i.split('=') }.flatten]['Auth']
        end
      end

      # get user info
      # @param [String] token auth token
      def user_info(token)
        ApiHelper.request_with_token '/reader/api/0/user-info', token
      end

      # get user id
      # @param [String] token auth token
      def user_id(token)
        JSON.generate({:userId => JSON.parse(user_info(token))['userId']})
      end

      # get token
      # @param [String] token auth token
      def token(token)
        ApiHelper.request '/reader/api/0/token', {:query => {:T => token}}
      end

      # OPML Import
      def import
        # todo
      end

      # get unread counters
      # @param [String] token auth token
      def unread_counters(token)
        ApiHelper.request '/reader/api/0/unread-count?output=json', {:query => {:T => token}}
      end

      # get user subscriptions
      # @param [String] token auth token
      def user_subscription(token)
        ApiHelper.request '/reader/api/0/subscription/list', {:query => {:T => token}}
      end

      # get user tags/folders
      # @param [String] token auth token
      def user_tags_folders(token)
        ApiHelper.request '/reader/api/0/tag/list', {:query => {:T => token}}
      end

      # stream
      #  output format => reader/api/0/stream/contents -> only json,
      #                   reader/atom -> XML or json
      # @param [String] token auth token
      # @param [String] feed id of subscription
      # @param [Hash] params request Parameters
      # @option params [Number] :n Number of items. (default 20, max 1000)
      # @option params [String] :r Order. (default: newest first. o: oldest first)
      # @option params [String] :ot Start time (unix timestamp. ex.1389756192)
      # @option params [String] :xt Exclude Target. (ex. 'user/-/state/com.google/read')
      # @option params [String] :it Include Target. ('user/-/state/com.google/read(,starred,like)')
      # @option params [String] :c Continuation.
      # @option params [String] :output output format ('json', 'xml', ...)
      def stream(token, feed='', params={})
        query = {:query => params.merge!(:T => token)}
        feed_name = feed.empty? ? '' : '/' + feed
        ApiHelper.request "/reader/atom#{feed_name}", query
      end

      # item ids
      # @param [String] token auth token
      # @param [String] feed id of subscription
      # @param [Hash] params request Parameters
      # @option params [Number] :n Number of items. (default 20, max 1000)
      # @option params [String] :r Order. (default: newest first. o: oldest first)
      # @option params [String] :ot Start time (unix timestamp. ex.1389756192)
      # @option params [String] :xt Exclude Target. (ex. 'user/-/state/com.google/read')
      # @option params [String] :it Include Target. ('user/-/state/com.google/read(,starred,like)')
      # @option params [String] :c Continuation.
      # @option params [String] :output output format ('json', 'xml', ...)
      def item_ids(token, feed='', params={})
        query = {:query => params.merge!(:T => token)}
        feed_name = feed.empty? ? '' : '/' + feed
        ApiHelper.request "/reader/api/0/stream/items/ids#{feed_name}", query
      end

      ## tag ##

      # rename tag
      # @param [String] token auth token
      # @param source source tag
      # @param dest   dest tag
      def rename_tag(token, source, dest)
        ApiHelper.request '/reader/api/0/rename-tag', {:query => {:T => token, s: source, dest: dest}}
      end

      # delete(disable) tag
      # @param [String] token auth token
      def disable_tag(token, tag_name)
        ApiHelper.request '/reader/api/0/disable-tag', {:query => {:T => token, s: tag_name}}
      end

      # add tag
      # @param [String] token auth token
      # @param [String] items Item IDs(short or long)
      # @param [String] add_tag use SpecialTag or custom tag
      def add_tag(token, items, add_tag=nil)
        ApiHelper.request '/reader/api/0/edit-tag', {:query => {:T => token, :i => items, :a => add_tag}}
      end

      # remove tag
      # @param [String] token auth token
      # @param [Array] items Item IDs(short or long)
      # @param [String] remove_tag SpecialTag or custom tag
      def remove_tag(token, items, remove_tag)
        ApiHelper.request '/reader/api/0/edit-tag', {:query => {:T => token, :i => items, :r => remove_tag}}
      end

      # mark all as read. mark as read, older than ts.
      # @param [String] token auth token
      # @param [String] ts microseconds.
      # @param [String] s Stream.
      def mark_all_as_read(token, ts, s)
        ApiHelper.request '/reader/api/0/mark-all-as-read', {:query => {:T => token, :ts => ts, :s => s}}
      end

      # add Subscription
      # @param [String] token auth token
      # @param [String] url specify the URL to add.
      def add_subscription(token, url)
        ApiHelper.request '/reader/api/0/subscription/quickadd', {:query => {:T => token, quickadd: url}}
      end

      # edit subscription
      # @param [String] token auth token
      # @param [String] ac action ('edit' or 'subscribe' or 'unsubscribe')
      # @param [String] s stream id(feed/feed_url)
      # @param [String] t subscription title. Omit this parameter to keep the title unchanged
      # @param [String] a add subscription to folder/tag.
      # @param [String] r remove subscription from folder/tag.
      def edit_subscription(token, ac, s, t=nil, a=nil, r=nil)
        query = {:T => token, :ac => ac, :s => s}
        query[:t] = t unless t.nil?
        query[:a] = a unless a.nil?
        query[:r] = r unless r.nil?
        ApiHelper.request '/reader/api/0/subscription/edit', {:query => query}
      end

      # rename subscription title
      # @param [String] token auth token
      # @param [String] s stream id(feed/feed_url)
      # @param [String] t subscription new title.
      def rename_subscription(token, s, t)
        edit_subscription token, :edit, s, t
      end

      # add folder to subscription
      # @param [String] token auth token
      # @param [String] s stream id(feed/feed_url)
      # @param [String] a add subscription to folder
      def add_folder_subscription(token, s, a)
        edit_subscription token, :edit, s, nil, a
      end

      # remove folder to subscription
      # @param [String] token auth token
      # @param [String] s stream id(feed/feed_url)
      # @param [String] r remove subscription to folder
      def remove_folder_subscription(token, s, r)
        edit_subscription token, :edit, s, nil, nil, r
      end

      # unsubscribe
      # @param [String] token auth token
      # @param [String] s stream id(feed/feed_url)
      def unsubscribe(token, s)
        edit_subscription token, :unsubscribe, s
      end

      # subscribe (=add Subscription)
      # @param [String] token auth token
      # @param [String] s stream id(feed/feed_url)
      def subscribe(token, s)
        edit_subscription token, :subscribe, s
      end

      # preference list:current subscriptions sorting.
      # @param [String] token auth token
      def preferences_list(token)
        ApiHelper.request '/reader/api/0/preference/list', {:query => {:T => token}}
      end

      # Stream preferences list
      # @param [String] token auth token
      def stream_preferences_list(token)
        ApiHelper.request '/reader/api/0/preference/stream/list', {:query => {:T => token}}
      end

      # @param [String] token auth token
      # @param [String] s stream id. root or folder name
      # @param [String] k key
      # @param [String] v value
      def set_stream_preferences(token, s, k, v)
        query = {:query => {:T => token, :s => s, :k => k, :v => v}}
        ApiHelper.request '/reader/api/0/preference/stream/set', query ,:post
      end

      # Set stream preferences is now is “subscription-ordering” only
      # @param [String] token auth token
      # @param [String] s stream id. root or folder name
      # @param [String] v sorting value
      def set_subscription_ordering(token, s ,v)
        set_stream_preferences(token, s, 'subscription-ordering', v)
      end

    end
  end

  class ApiHelper
    debug = false
    include HTTParty
    if debug
      debug_output $stdout
    end
    self.disable_rails_query_string_format

    INOREADER_BASE_URL = 'https://www.inoreader.com'

    class << self
      # send request
      # @param [String] path request path
      # @param [Hash] query URL params  ex. {:query => {:T => 'token', :ref => 'bar'}}
      # @param [Symbol] method :get or :post
      # @return response body
      def request(path, query=nil, method=:get)
        self.send(method, "#{INOREADER_BASE_URL}#{path}", query).body
      rescue => e
        raise InoreaderApiError.new "Network Error:#{e.message}"
      end

      # send request for attach a 'GoogleLogin auth' to request header
      # @param [String] path request path
      # @param [Hash] query URL parameter, without token  ex. {:query => {:q => 'foo', :ref => 'bar'}}
      # @param [Symbol] method :get or :post
      # @return response body
      def request_with_token(path, token, query=nil, method=:get)
        raise 'Error: not authorized' if token.nil?
        option = {:headers => {'Authorization' => 'GoogleLogin auth=' + token}}
        option[:query] = query unless query.nil?
        self.send(method, "#{INOREADER_BASE_URL}#{path}", option).body
      rescue => e
        raise InoreaderApiError.new "Network Error:#{e.message}"
      end

      # auth request to Inoreader
      # @param [String] un username
      # @param [String] pw password
      # @return response body
      def auth_request(un, pw)
        request '/accounts/ClientLogin', {:body => {:Email => un, :Passwd => pw}}, :post
      rescue => e
        raise InoreaderApiError.new "Network Error:#{e.message}"
      end
    end
  end
end
