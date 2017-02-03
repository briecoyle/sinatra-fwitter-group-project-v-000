require './config/environment'

class ApplicationController < Sinatra::Base

  configure do
    set :public_folder, 'public'
    set :views, 'app/views'

    enable :sessions unless test?
    set :session_secret, "secret"
  end

  get '/' do
    erb :index
  end

  get '/tweets' do
    if logged_in?
      @user = current_user
      @tweets = Tweet.all
      erb :'tweets/tweets'
    else
      redirect to '/login'
    end
  end

  get '/tweets/new' do
    if logged_in?
      erb :"tweets/create_tweet"
    else
      redirect to '/login'
    end
  end

  post '/tweets/new' do
    if !params[:content].empty?
      @tweet = Tweet.create(content: params[:content], user_id: session[:id])
      redirect to '/tweets'
    end
  end

  get '/users/:username_slug' do
    @user = User.find_by_slug(params[:username_slug])
    @tweets = @user.tweets.all
    erb :'/users/show_tweets'
  end

  get '/tweets/:id' do
    if logged_in?
      @tweet = Tweet.find(params[:id])
      erb :'/tweets/show_tweet'
    else
      redirect to '/login'
    end
  end

  get '/tweets/:id/edit' do
    if logged_in?
      @tweet = Tweet.find(params[:id])
      erb :'/tweets/edit_tweet'
    else
      redirect to '/login'
    end
  end

  patch '/tweets/:id' do
    @tweet = Tweet.find(params[:id])
    if @tweet.user_id == session[:id] && !params[:content].empty?
      @tweet.content = params[:content]
      @tweet.save
      redirect to '/tweets'
    elsif @tweet.user_id == session[:id] && params[:content].empty?
      redirect to "tweets/#{@tweet.id}/edit"
    elsif @tweet.user_id != session[:id]
      redirect to '/login'
    end
  end

  delete '/tweets/:id' do
    if logged_in?
      @tweet = Tweet.find(params[:id])
      if @tweet.user.id == session[:id]
        @tweet.delete
        redirect to '/tweets'
      else
        redirect to '/tweets'
      end
    else
      redirect to '/login'
    end
  end

  get '/signup' do
    if logged_in?
      redirect to '/tweets'
    else
      erb :'/users/create_user'
    end
  end

  post '/signup' do
    @user = User.create(params)
    if params[:username].empty? || params[:email].empty? || params[:password].empty?
      redirect to '/signup'
    else
      session[:id] = @user.id
      redirect to '/tweets'
    end
  end

  get '/login' do
    if logged_in?
      redirect to '/tweets'
    else
      erb :'/users/login'
    end
  end

  post '/login' do
    @user = User.find_by(username: params[:username])
    if @user && @user.authenticate(params[:password])
      session[:id] = @user.id
      redirect to '/tweets'
    else
      redirect to '/login'
    end
  end

  get '/logout' do
    if logged_in?
      session.clear
      redirect to '/login'
    else
      redirect to '/'
    end
  end

  helpers do
    def logged_in?
      !!session[:id]
    end

    def current_user
      User.find(session[:id])
    end
  end
end
