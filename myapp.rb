require 'sinatra/base'
require 'sinatra/reloader' #if development?
require 'sinatra/partial'
require 'sinatra/json'
require 'slim'
require './inoreader_api.rb'
require './util.rb'

# Sinatra app
class App < Sinatra::Base
  enable :sessions
  set :session_secret, 'f93f!ep2_3g'
  configure :development do
    register Sinatra::Reloader
  end

  register Sinatra::Partial
  set :partial_template_engine, :slim


  class SpecialTags
    # ex: SpecialTags::TAGS[:read]
    # TODO User ID
    TAGS = {
        :read => 'user/1005880641/state/com.google/read',
        :starred => 'user/1005880641/state/com.google/starred',
        :broadcast => 'user/1005880641/state/com.google/broadcast',
        :link => 'user/1005880641/state/com.google/like',
        :custom => 'user/1005880641/label/'
    }.freeze
  end

  # root
  get '/' do
    unless session[:auth_token].nil?
      @feeds = []
      JSON.parse(InoreaderApi::Api.user_subscription session[:auth_token])['subscriptions'].each do |subscription|
        @feeds << {:id => subscription['id'], :label => subscription['title']}
      end
    end

    @tags = SpecialTags::TAGS
    slim :index
  end

  # 認証を行う
  post '/auth' do
    session[:auth_token] = InoreaderApi::Api.auth(params['un'], params['pw'])
    # TODO session[:user_id]
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

  get '/user_id' do
    json_output InoreaderApi::Api.user_id session[:auth_token]
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
    query = create_stream_query
    feed = params[:feed]
    if params[:output] == 'json'
      json_output InoreaderApi::Api.stream session[:auth_token], feed, query
    else
      output InoreaderApi::Api.stream session[:auth_token], feed, query
    end
  end

  # id
  get '/item_ids' do
    query = create_stream_query
    feed = params[:feed]
    if params[:output] == 'json'
      json_output InoreaderApi::Api.item_ids session[:auth_token], feed, query
    else
      output InoreaderApi::Api.item_ids session[:auth_token], feed, query
    end
  end

  ## tag ##

  # rename
  get '/rename_tag' do
    InoreaderApi::Api.rename_tag session[:auth_token], params[:s], params[:dest]
  end

  # disable
  get '/disable_tag' do
    InoreaderApi::Api.disable_tag session[:auth_token], params[:s]
  end

  # edit
  get '/edit_tag' do
    ids = params[:ids].split(' ')
    tag_name = params[:tagname]
    if tag_name == SpecialTags::TAGS[:custom]
      tag_name = params[:tagname] + params[:ctagname]
    end
    method = params[:type] == 'a' ? :add_tag : :remove_tag
    InoreaderApi::Api.send(method, session[:auth_token], ids, tag_name)
  end

  # mark all as read
  # 一度mark all as readすると、unread状態に戻せない仕様っぽい
  # tsより古いarticleを削除する
  get '/mark_all_as_read' do
    ts = Util.time_to_microsecond(Time.parse(params[:ts]))
    InoreaderApi::Api.mark_all_as_read session[:auth_token], ts, params[:s]
  end

  # add subscription
  get '/add_subscription' do
    json_output InoreaderApi::Api.add_subscription session[:auth_token], params[:quickadd]
  end

  # edit subscription
  # /edit_subscription?ac=edit&s=feed/http://blog.lofei.info/atom.xml&t=lofei_blog
  post '/edit_subscription' do
    if params[:type] == 'u'
      # unsubscribe
      InoreaderApi::Api.unsubscribe session[:auth_token], params[:s]
    elsif params[:type] == 's'
      # subscribe
      InoreaderApi::Api.subscribe session[:auth_token], params[:feed]
    else
      #remove folder
      #InoreaderApi::Api.remove_folder_subscription session[:auth_token], params[:s], params[:r]

      #add folder
      #InoreaderApi::Api.add_folder_subscription session[:auth_token], params[:s], params[:a]

      #rename subscription
      #InoreaderApi::Api.rename_subscription session[:auth_token], params[:s], params[:t]
    end
  end

  #preferences list
  get '/preferences_list' do
    json_output InoreaderApi::Api.preferences_list session[:auth_token]
  end

  get '/stream_preferences_list' do
    json_output InoreaderApi::Api.stream_preferences_list session[:auth_token]
  end

  post '/set_subscription_ordering' do
    InoreaderApi::Api.set_subscription_ordering session[:auth_token], params[:s], params[:v]
  end

  # TODO  input系は全部POSTにする

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
    "<pre>#{Rack::Utils.escape_html JSON.pretty_generate JSON.parse json }</pre>"
  end

  #json以外を読める形でhtmlに出力
  # @param data
  def output(data)
    "<pre>#{Rack::Utils.escape_html data }</pre>"
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

end
