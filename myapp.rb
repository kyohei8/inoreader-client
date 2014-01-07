require 'sinatra/base'
require 'sinatra/reloader' #if development?
require 'sinatra/json'
require 'slim'
require 'httparty'


class InoreaderRequest
  include HTTParty
  debug_output $stdout
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
  def edit_subscription(ac: 'edit', s: nil, t: nil, a:nil, r:nil)
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

# Sinatra app
class App < Sinatra::Base
  enable :sessions
  set :session_secret, 'f93f!ep2_3g'

  configure :development do
    register Sinatra::Reloader
  end

  api = nil

  # before filter
  # execute auth
  before /^\/(|user|export)/ do
    api ||= InoreaderRequest.new
  end

  # root
  # 認証を行う
  get '/' do
    "auth key: #{api.auth_token}"
  end

  # ユーザ情報を表示
  get '/user' do
    api.user_info
  end

  #トークンを取得
  get '/token' do
    api.token
  end

  #エクスポート
  get '/export.xml' do
    api.export
  end

  # 未読数:json
  get '/unread' do
    json_output api.unread_counters
  end

  # 登録feed
  get '/user_subscription' do
    json_output api.user_subscription
  end

  # タグ情報
  get '/user_tags_folders' do
    json_output api.user_tags_folders
  end

  # feed表示
  get '/stream' do
    json_output api.stream params
  end

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

  private
  # jsonを読める形でhtmlに出力
  def json_output(json)
    "<pre>#{Rack::Utils.escape_html JSON.pretty_generate JSON.parse json }</pre>"
  end

end