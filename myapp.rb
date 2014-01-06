require 'sinatra/base'
require 'sinatra/reloader' #if development?
require 'sinatra/json'
require 'slim'
require 'httparty'


class InoreaderRequest
  include HTTParty
  #debug_output $stdout

  INOREADER_BASE_URL = 'https://www.inoreader.com'
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
  #@param feed ex.feed/http://~
  def stream(feed)
    number = 20
    order = 'o'
    xt='user/-/state/com.google/read'
    output='json'
    option = {:headers => {'Authorization' => 'GoogleLogin auth=' + @auth_token}}
    self.class.get("#{INOREADER_BASE_URL}/reader/atom/#{feed}?n=#{number}&o=#{order}&xt=#{xt}&output=#{output}",option).body
    #?n=#{number}&o=#{order}&xt=#{xt}?output=#{output}",option).body
  end

  private
  def request(path)
    option = {:headers => {'Authorization' => 'GoogleLogin auth=' + @auth_token}}
    self.class.get("#{INOREADER_BASE_URL}#{path}",option).body
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
    if api.nil?
      api = InoreaderRequest.new
    end
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
  get '/unread.json' do
    json JSON.parse(api.unread_counters)
  end

  # 未読数:View
  get '/unread_view' do
    res = JSON.parse(api.unread_counters)
    @max = res['max']
    @uc = res['unreadcounts']
    slim :unread
  end

  get '/user_subscription.json' do
    json JSON.parse api.user_subscription
  end

  get '/user_subscription_view' do
    @subscriptions = JSON.parse(api.user_subscription)['subscriptions']
    slim :user_subscription
  end

  get '/user_tags_folders.json' do
    json JSON.parse api.user_tags_folders
  end

  get '/user_tags_folders_view' do
    @tags = JSON.parse(api.user_tags_folders)['tags']
    slim :user_tags_folders
  end

  get '/stream' do
    json JSON.parse api.stream 'feed/http://www.ideaxidea.com/feed'
  end

end