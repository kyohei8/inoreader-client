require 'sinatra/base'
require 'sinatra/reloader' #if development?
require 'sinatra/partial'
require 'sinatra/json'
require 'slim'
require 'httparty'
#require './inoreader_api.rb'

class InoreaderRequest
  include HTTParty
  #debug_output $stdout
  InoreaderRequest.disable_rails_query_string_format

  INOREADER_BASE_URL = 'https://www.inoreader.com'

  #Special tags
  TAGS = {
    read: 'user/-/state/com.google/read',
    starred: 'user/-/state/com.google/starred',
    broadcast: 'user/-/state/com.google/broadcast',
    like: 'user/-/state/com.google/like',
    tag: 'user/-/label/' # + tag_name
  }

  attr_reader :auth_token

  def initialize
    auth
  end

  # get auth token
  # @return authKey
  def auth
    puts 'auth='
    options = {
      :body => {
        :Email => 'tsukuda.kyouhei@gmail.com',
        :Passwd => 'wAr0107tk2'
      }
    }
    response = self.class.post("#{INOREADER_BASE_URL}/accounts/ClientLogin", options)
    @auth_token = Hash[*response.body.split.collect { |i| i.split('=') }.flatten]['Auth']
  end

  # get user info
  def user_info
    request '/reader/api/0/user-info'
  end

  # get token
  def token
    request '/reader/api/0/token'
  end

  # OPML Export
  # todo ちゃんどダウンロードできない
  def export
    request '/reader/subscriptions/export?download=1'
  end

  # OPML Import
  def import
    # todo
  end

  # Get unread counters
  def unread_counters
    request '/reader/api/0/unread-count?output=json'
  end

  # user subscriptions
  def user_subscription
    request '/reader/api/0/subscription/list'
  end

  def user_tags_folders
    request '/reader/api/0/tag/list'
  end


  #Stream contents
  def stream(param)
    feed = param[:feed]
    param.delete :feed
    request "/reader/atom/#{feed}", param
  end

  def item_ids(param)
    feed = param[:feed]
    param.delete :feed
    request "/reader/api/0/stream/items/ids/#{feed}", param
  end

  ## tag ##
  # rename
  def rename_tag(source_tag, dest_tag)
    request '/reader/api/0/rename-tag', {s: source_tag, dest: dest_tag}
  end

  # delete(disable)
  def disable_tag(source_tag)
    request '/reader/api/0/disable-tag', {s: source_tag}
  end

  # edit
  def edit_tag(items, add_tag=nil, remove_tag=nil)
    return 'Please enter tag name!' if add_tag.nil? and remove_tag.nil?
    q = {}
    q[:i] = items
    q[:a] = add_tag unless add_tag.nil?
    q[:r] = remove_tag unless remove_tag.nil?
    request '/reader/api/0/edit-tag', q
  end

  # mark all as read
  def mark_all_as_read(feed)
    request '/reader/api/0/mark-all-as-read', {s: feed}
  end

  def add_subscription(url)
    request '/reader/api/0/subscription/quickadd', {quickadd: url}
  end

  # params:
  # ac - Action. Can be edit, subscribe, or unsubscribe.
  # s - Stream id in the form feed/feed_url
  # t - Subscription title. Omit this parameter to keep the title unchanged
  # a - Add subscription to folder/tag.
  # r - Remove subscription from folder/tag.
  def edit_subscription(ac: 'edit', s: nil, t: nil, a: nil, r: nil)
    query = {}
    query[:ac] = ac
    query[:s] = s unless s.nil?
    query[:t] = t unless t.nil?
    query[:a] = a unless a.nil?
    query[:r] = r unless r.nil?
    request '/reader/api/0/subscription/edit', query
  end

  # 購読リストのソート
  def preferences_list
    request '/reader/api/0/preference/list'
  end

  def stream_preferences_list
    request '/reader/api/0/preference/stream/list'
  end

  private
  def request(path, query=nil)
    option = {:headers => {'Authorization' => 'GoogleLogin auth=' + @auth_token}}
    option[:query] = query unless query.nil?
    self.class.get("#{INOREADER_BASE_URL}#{path}", option).body
  end
end


module InoreaderApi
  class Api
    class << self
      # 認証し、sessionにauthKeyを保持する
      # @param un ユーザ名/Email
      # @param pw パスワード
      # @return 認証に成功した場合はauthKey, 失敗した場合はnil
      # TODO 500, 404チェック
      def auth(un, pw)
        response_body = ApiHelper.auth_request '/accounts/ClientLogin', un, pw
        if response_body.nil? or response_body.start_with?('Error')
          #raise response.body.split('=')[1]
          p response_body
          nil
        else
          Hash[*response_body.split.collect { |i| i.split('=') }.flatten]['Auth']
        end
      end

      # get user info
      def user_info(token)
        ApiHelper.request_with_token '/reader/api/0/user-info', token
      end

      # get token
      def token(token)
        ApiHelper.request '/reader/api/0/token', {:query => {:T => token}}
      end

      # OPML Import
      def import
        # todo
      end

      # get unread counters
      def unread_counters(token)
        ApiHelper.request '/reader/api/0/unread-count?output=json', {:query => {:T => token}}
      end

      # user subscriptions
      def user_subscription(token)
        ApiHelper.request '/reader/api/0/subscription/list', {:query => {:T => token}}
      end

      def user_tags_folders(token)
        ApiHelper.request '/reader/api/0/tag/list', {:query => {:T => token}}
      end

      # stream
      #  output format => reader/api/0/stream/contents -> json, reader/atom -> XML or specified output
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
        # TODO feed
        query = {:query => params.merge!(:T => token)}
        p query
        feed_name = feed.empty? ? '' : '/' + feed
        ApiHelper.request "/reader/atom#{feed_name}", query
      end

    end
  end

  class ApiHelper
    debug = false
    include HTTParty
    if debug
      debug_output $stdout
    end
    #InoreaderApi::Api.disable_rails_query_string_format
    self.disable_rails_query_string_format

    INOREADER_BASE_URL = 'https://www.inoreader.com'

    # Inoreaderへのリクエストクラス
    # リクエストしてbodyを返す
    class << self

      # 普通のRequest
      # @param path
      # @param query URLパラメータ  ex. {:query => {:q => 'foo', :ref => 'bar'}}
      # @param method
      # @return response body
      def request(path, query=nil, method=:get)
        self.send(method, "#{INOREADER_BASE_URL}#{path}", query).body
      end

      #ヘッダーにGoogleLogin authのトークンを付けてリクエストする
      def request_with_token(path, token, query=nil, method=:get)
        raise 'Error: not authorized' if token.nil?
        option = {:headers => {'Authorization' => 'GoogleLogin auth=' + token}}
        option[:query] = query unless query.nil?
        self.send(method, "#{INOREADER_BASE_URL}#{path}", option).body
      end

      # Inoreaderへの認証リクエスト
      def auth_request(path, un, pw)
        post("#{INOREADER_BASE_URL}#{path}", {:body => {:Email => un, :Passwd => pw}}).body
      end
    end
  end
end


# Sinatra app
class App < Sinatra::Base
  enable :sessions
  set :session_secret, 'f93f!ep2_3g'
  register Sinatra::Partial
  configure :development do
    register Sinatra::Reloader
  end

  set :partial_template_engine, :slim

  # root
  get '/' do
    unless session[:auth_token].nil?
      @feeds = []
      JSON.parse(InoreaderApi::Api.user_subscription session[:auth_token] )['subscriptions'].each do |subscription|
        @feeds << {:id => subscription['id'], :label => subscription['title'] }
      end
    end
    slim :index
  end

  # 認証を行う
  post '/auth' do
    session[:auth_token] = InoreaderApi::Api.auth(params['un'], params['pw'])
    if session[:auth_token].nil?
      'login failed!'
    else
      redirect to('/')
    end
  end

  # ユーザ情報を表示
  get '/user' do
    json_output InoreaderApi::Api.user_info session[:auth_token]
  end

  #トークンを取得
  get '/token' do
    InoreaderApi::Api.token session[:auth_token]
  end

  get '/import' do
    # TODO
  end

  # 未読数:json
  get '/unread' do
    json_output InoreaderApi::Api.unread_counters session[:auth_token]
  end

  # 登録feed
  get '/user_subscription' do
    json_output InoreaderApi::Api.user_subscription session[:auth_token]
  end

  # タグ情報
  get '/user_tags_folders' do
    json_output InoreaderApi::Api.user_tags_folders session[:auth_token]
  end

  # feed表示
  get '/stream' do
    query = {}
    query[:n] = params[:n] unless params[:n].empty?
    query[:r] = params[:r] unless params[:r].empty?
    query[:ot] = params[:ot] unless params[:ot].empty?
    query[:xt] = params[:xt] unless params[:xt].empty?
    query[:it] = params[:it] unless params[:it].empty?
    query[:c] = params[:c] unless params[:c].empty?
    query[:output] = params[:output] unless params[:output].empty?
    p query
    feed = params[:feed]
    if params[:output] == 'json'
      json_output InoreaderApi::Api.stream session[:auth_token], feed, query
    else
      output InoreaderApi::Api.stream session[:auth_token], feed, query
    end
  end

=begin
  # id
  get '/item_ids' do
    json_output api.item_ids params
  end

  ## tag ##

  # rename
  # ex. /rename_tag?s=xxx&dest=xxx
  get '/rename_tag' do
    api.rename_tag params[:s], params[:dest]
  end

  # disable
  get '/disable_tag' do
    api.disable_tag params[:s]
  end

  # edit
  get '/edit_tag' do
    api.edit_tag params[:i].split(','), "user/-/label/#{params[:a]}", "user/-/label/#{params[:r]}"
  end

  # mark all as read
  get '/mark_all_as_read' do
    api.mark_all_as_read params[:s]
  end

  # add subscription
  get '/add_subscription' do
    json_output api.add_subscription params[:url]
  end

  # edit subscription
  # /edit_subscription?ac=edit&s=feed/http://blog.lofei.info/atom.xml&t=lofei_blog
  get '/edit_subscription' do
    api.edit_subscription params
  end

  #
  get '/preferences_list' do
    json_output api.preferences_list
  end

  get '/stream_preferences_list' do
    json_output api.stream_preferences_list
  end

  get '' do

  end

=end
  private
  # jsonを読める形でhtmlに出力
  def json_output(json)
    "<pre>#{Rack::Utils.escape_html JSON.pretty_generate JSON.parse json }</pre>"
  end

  def output(data)
    "<pre>#{Rack::Utils.escape_html data }</pre>"
  end
end
