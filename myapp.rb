require 'sinatra/base'
require 'sinatra/reloader' #if development?
require 'sinatra/partial'
require 'sinatra/assetpack'
require 'sinatra/json'
require 'slim'
require './lib/util.rb'
require './lib/aes_crypt.rb'
require 'inoreader-api'

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
    #serve '/css', from: 'app/css/'
    #serve '/js', from: 'app/js/'
    css :bootstrap, %w(/css/bootstrap.css /css/app.css)
    js :app, '/js/app.js', %w(/js/lib/angular.min.js /js/lib/ui-bootstrap-tpls.min.js /js/lib/jquery-2.0.3.min.js /js/main.js)
    js :subscription, '', ['/js/subscription.js']
    js :stream, '', ['/js/stream.js']
    js :tag, ['/js/tag.js']
    js :mark, ['/js/mark.js']

    js_compression :jsmin
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
    begin
      ino = InoreaderApi::Api.new(:username => params['un'], :password => params['pw'])
      auth_token = ino.auth_token
      user_id = ino.user_id

      # encrypt token
      session[:auth_token] = AESCrypt.encrypt(auth_token, CRYPT_KEY, nil, 'AES-256-CBC')
      session[:uid] = user_id.userId

      redirect to('/')
    rescue => e
      p e.message
      'login failed!'
    end
  end

  # ユーザ情報を表示
  get '/user' do
    ino = InoreaderApi::Api.new :auth_token => token
    json_output ino.user_info.to_json
  end

  get '/user_id' do
    ino = InoreaderApi::Api.new :auth_token => token
    json_output ino.user_id.to_json
  end

  #トークンを取得
  get '/token' do
    ino = InoreaderApi::Api.new :auth_token => token
    output ino.token
  end

  get '/import' do
    # TODO
  end

  # 未読数:json
  get '/unread' do
    ino = InoreaderApi::Api.new :auth_token => token
    json_output ino.unread_counters.to_json
  end

  # 登録feed
  get '/user_subscription' do
    ino = InoreaderApi::Api.new :auth_token => token
    json_output ino.user_subscription.to_json
  end

  # タグ情報
  get '/user_tags_folders' do
    ino = InoreaderApi::Api.new :auth_token => token
    json_output ino.user_tags_folders.to_json
  end

  get '/stream' do
    slim :stream
  end

  get '/feeds' do
    feeds = []
    ino = InoreaderApi::Api.new :auth_token => token
    if has_token
      ino.user_subscription.subscriptions.each do |subscription|
        feeds << {:id => subscription['id'], :label => subscription['title']}
      end
    end
    feeds.to_json
  end

  # feed itemの表示
  post '/stream' do
    ino = InoreaderApi::Api.new :auth_token => token, :return_httparty_response => true
    method = params[:type] == 'stream' ? :items : :item_ids
    httparty_response = ino.send method, params[:feed], params[:query]
    {
      :url => URI.decode(httparty_response.request.last_uri.to_s),
      :body => httparty_response.body
    }.to_json
  end

  ## tag ##
  get '/tag' do
    slim :tag
  end

  get '/tags' do
    ino = InoreaderApi::Api.new :auth_token => token
    ino.user_tags_folders.tags.select { |tag|
      tag.id.include? 'label' and tag.id[-1] != '/'
    }.map { |tag|
      tag.id.split('/').last
    }.to_json
  end

  # get special tag
  get '/special_tags' do
    SpecialTags.generate(session[:uid], :read, :starred, :broadcast, :like, :label).to_json
  end

  # rename
  post '/rename_tag' do
    ino = InoreaderApi::Api.new :auth_token => token, :return_httparty_response => true
    json_output_with_url(ino.rename_tag params[:s], params[:dest])
  end

  # disable
  post '/disable_tag' do
    ino = InoreaderApi::Api.new :auth_token => token, :return_httparty_response => true
    json_output_with_url(ino.disable_tag params[:s])
  end

  # edit
  post '/edit_tag' do
    ino = InoreaderApi::Api.new :auth_token => token, :return_httparty_response => true
    ids = params[:ids].split(' ')
    tag = params[:tagname]
    label = params[:labelname]
    tag << label unless label.empty?
    method = params[:type] == 'a' ? :add_tag : :remove_tag
    json_output_with_url ino.send(method, ids, tag)
  end

  # mark all as read
  get '/mark_all_as_read' do
    slim :markRead
  end

  # 一度mark all as readすると、unread状態に戻せない仕様っぽい
  # tsより古いarticleを削除する
  post '/mark_all_as_read' do
    ts = Util.time_to_microsecond(Time.parse(params[:ts]))
    ino = InoreaderApi::Api.new :auth_token => token, :return_httparty_response => true
    json_output_with_url(ino.mark_all_as_read ts, params[:s])
  end

  get '/subscription' do
    slim :subscription
  end

  # add subscription
  post '/add_subscription' do
    ino = InoreaderApi::Api.new :auth_token => token, :return_httparty_response => true
    json_output_with_url(ino.add_subscription params[:quickadd])
  end

  # edit subscription
  post '/edit_subscription' do
    ino = InoreaderApi::Api.new :auth_token => token, :return_httparty_response => true
    res = if params[:type] == 'u'
      # unsubscribe
      ino.unsubscribe params[:s]
    elsif params[:type] == 's'
      # subscribe only
      ino.subscribe params[:feed], params[:a]
    else
      # edit
      add = params[:a].empty? ? nil : params[:a]
      remove = params[:r].empty? ? nil : params[:r]
      title = params[:t].empty? ? nil : params[:t]
      ino.edit_subscription :edit, params[:s], title, add ,remove
    end
    json_output_with_url res
  end

  #preferences list
  get '/preferences_list' do
    ino = InoreaderApi::Api.new :auth_token => token
    json_output ino.preferences_list.to_json
  end

  get '/stream_preferences_list' do
    ino = InoreaderApi::Api.new :auth_token => token
    json_output ino.stream_preferences_list.to_json
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

  def pretty_json(json)
    Rack::Utils.escape_html JSON.pretty_generate JSON.parse json
  end

  #jsonを読める形でhtmlに出力
  def json_output(json)
    @output = pretty_json json
    slim :renderText
  end

  #json以外を読める形でhtmlに出力
  # @param data
  def output(data)
    @output = "#{Rack::Utils.escape_html data }"
    slim :renderText
  end

  def has_token
    session[:auth_token].nil? ? false : true
  end

  # return decrypt token
  def token
    has_token ? AESCrypt.decrypt(session[:auth_token], CRYPT_KEY, nil, "AES-256-CBC") : nil
  end

  def json_output_with_url(httparty_response)
    {
      :url => URI.decode(httparty_response.request.last_uri.to_s),
      :body => httparty_response.body
    }.to_json
  end

end
