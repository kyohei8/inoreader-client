require 'sinatra/base'
require 'sinatra/reloader' #if development?
require 'sinatra/partial'
require 'sinatra/assetpack'
require 'sinatra/json'
require 'slim'
require './util.rb'
require 'inoreader-api'
require './lib/aes_crypt.rb'

# Sinatra app
class App < Sinatra::Base
  enable :sessions
  set :session_secret, 'f93f!ep2_3g'
  set :public_folder, File.dirname(__FILE__) + '/assets'
  configure :development do
    register Sinatra::Reloader
  end

  register Sinatra::Partial
  set :partial_template_engine, :slim

  # setup assetpack
  set :root, File.dirname(__FILE__)
  register Sinatra::AssetPack

  assets do
    serve '/css', from: 'app/css'
    serve '/js', from: 'app/js'
    css :bootstrap, %w(/css/bootstrap.css)
    js :app, '/js/app.js', ['/js/jquery-2.0.3.min.js', '/js/bootstrap.min.js']
    js :subscription, '', ['/js/subscription.js']
  end

  class SpecialTags
    TAGS = {
      :read => 'user/__uid__/state/com.google/read',
      :starred => 'user/__uid__/state/com.google/starred',
      :broadcast => 'user/__uid__/state/com.google/broadcast',
      :like => 'user/__uid__/state/com.google/like',
      :label => 'user/__uid__/label/',
    }.freeze

    # @param [String] user_id
    # @param [Symbol] tags SpecialTags::TAGS key
    # @return [Array] Array of Hash
    def self.generate(user_id, *tags)
      tags.map do |tag_name|
        {:label => tag_name, :value => TAGS[tag_name].gsub('__uid__', user_id)}
      end
    end
  end

  CRYPT_KEY = 'sRywAcbsUnsRTXfMb7kyFeawm4QSzf7t'

  get '/' do
    slim :index
  end

  get '/logout' do
    session.clear
    redirect '/'
  end

  # 認証を行う
  post '/auth' do
    response = InoreaderApi::Api.auth(params['un'], params['pw'])
    if response[:auth_token].nil?
      'login failed!'
    else
      # encrypt token
      session[:auth_token] = AESCrypt.encrypt(response[:auth_token], CRYPT_KEY, nil, 'AES-256-CBC')
      session[:uid] = JSON.parse(InoreaderApi::Api.user_id token)['userId']
      redirect to('/')
    end
  end

  # ユーザ情報を表示
  get '/user' do
    json_output InoreaderApi::Api.user_info token
  end

  get '/user_id' do
    json_output InoreaderApi::Api.user_id token
  end

  #トークンを取得
  get '/token' do
    output InoreaderApi::Api.token token
  end

  get '/import' do
    # TODO
  end

  # 未読数:json
  get '/unread' do
    json_output InoreaderApi::Api.unread_counters token
  end

  # 登録feed
  get '/user_subscription' do
    json_output InoreaderApi::Api.user_subscription token
  end

  # タグ情報
  get '/user_tags_folders' do
    json_output InoreaderApi::Api.user_tags_folders token
  end

  get '/stream' do
    if has_token
      @feeds = []
      JSON.parse(InoreaderApi::Api.user_subscription token)['subscriptions'].each do |subscription|
        @feeds << {:id => subscription['id'], :label => subscription['title']}
      end
    end
    slim :stream
  end

  # feed表示
  post '/stream' do
    query = create_stream_query
    feed = params[:feed]
    method = params[:type] == 'stream' ? :stream : :item_ids
    response = InoreaderApi::Api.send method, token, feed, query

    if params[:output] == 'json'
      json_output response
    else
      output response
    end
  end


  ## tag ##
  get '/tag' do
    @tags = SpecialTags.generate(session[:uid], :read, :starred, :broadcast, :like, :label)
    slim :tag
  end

  # rename
  post '/rename_tag' do
    InoreaderApi::Api.rename_tag token, params[:s], params[:dest]
  end

  # disable
  post '/disable_tag' do
    InoreaderApi::Api.disable_tag token, params[:s]
  end

  # edit
  post '/edit_tag' do
    ids = params[:ids].split(' ')
    tag = params[:tagname]
    label = params[:labelname]
    tag << label if label
    method = params[:type] == 'a' ? :add_tag : :remove_tag
    InoreaderApi::Api.send(method, token, ids, tag)
  end

  # mark all as read
  get '/mark_all_as_read' do
    slim :markRead
  end

  # 一度mark all as readすると、unread状態に戻せない仕様っぽい
  # tsより古いarticleを削除する
  post '/mark_all_as_read' do
    ts = Util.time_to_microsecond(Time.parse(params[:ts]))
    InoreaderApi::Api.mark_all_as_read token, ts, params[:s]
  end

  get '/subscription' do
    if has_token
      @feeds = []
      JSON.parse(InoreaderApi::Api.user_subscription token)['subscriptions'].each do |subscription|
        @feeds << {:id => subscription['id'], :label => subscription['title']}
      end
    end
    slim :subscription
  end

  # add subscription
  post '/add_subscription' do
    json_output InoreaderApi::Api.add_subscription token, params[:quickadd]
  end

  # edit subscription
  post '/edit_subscription' do
    if params[:type] == 'u'
      # unsubscribe
      InoreaderApi::Api.unsubscribe token, params[:s]
    elsif params[:type] == 's'
      # subscribe only
      InoreaderApi::Api.subscribe token, params[:feed], params[:a]
    else
      # edit
      InoreaderApi::Api.edit_subscription token, :edit, params[:s], params[:t], params[:a], params[:r]
    end
  end

  #preferences list
  get '/preferences_list' do
    json_output InoreaderApi::Api.preferences_list token
  end

  get '/stream_preferences_list' do
    json_output InoreaderApi::Api.stream_preferences_list token
  end

  get '/set_subscription_ordering' do
    @labels = []
    data = JSON.parse(InoreaderApi::Api.user_tags_folders token)['tags']
    data.each do |tag|
      if tag['id'].include? 'label'
        @labels << tag['id']
      end
    end
    slim :setStreamPref
  end

  post '/set_subscription_ordering' do
    InoreaderApi::Api.set_subscription_ordering token, params[:s], params[:v]
  end

  not_found do
    slim :'404'
  end

  error do
    @e = env['sinatra.error'].message
    slim :'500'
  end

  private

  #jsonを読める形でhtmlに出力
  def json_output(json)
    @output = "#{Rack::Utils.escape_html JSON.pretty_generate JSON.parse json }"
    slim :renderText
  end

  #json以外を読める形でhtmlに出力
  # @param data
  def output(data)
    @output = "#{Rack::Utils.escape_html data }"
    slim :renderText
  end

  def create_stream_query
    query = {}
    query[:n] = params[:n] unless params[:n].empty?
    query[:r] = params[:r] unless params[:r].empty?
    query[:ot] = params[:ot] unless params[:ot].empty?
    query[:xt] = params[:xt] unless params[:xt].empty?
    query[:it] = params[:it] unless params[:it].empty?
    query[:c] = params[:c] unless params[:c].empty?
    query[:output] = params[:output] unless params[:output].empty?
    query
  end

  def has_token
    session[:auth_token].nil? ? false : true
  end

  # return decrypt token
  def token
    has_token ? AESCrypt.decrypt(session[:auth_token], CRYPT_KEY, nil, "AES-256-CBC") : nil
  end

  def masked_token
    t = token
    view_size = 8
    unless t.nil?
      token.slice(0, view_size) + 'x' * (token.size - view_size)
    end
  end
end
