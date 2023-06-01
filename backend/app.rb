require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require './models'
require 'dotenv/load'
require 'json'
require 'sinatra'
require 'sinatra/cross_origin'

enable :sessions

before do
    Dotenv.load
    Cloudinary.config do |config|
        config.cloud_name = ENV['CLOUD_NAME']
        config.api_key = ENV['CLOUDINARY_API_KEY']
        config.api_secret = ENV['CLOUDINARY_API_SECRET']
    end
end

get '/api/data' do
  # データの取得や処理を行う
  data = [
    { id: 1, name: 'Item 1' },
    { id: 2, name: 'Item 2' },
    { id: 3, name: 'Item 3' }
  ]
  
  # レスポンスデータをJSONとして返す
  json_response = data.to_json
  content_type :json
  json_response
end


get '/' do
    @posts = Post.all
    erb :index
end

get '/signup' do
    erb :signup
end

get '/signout' do
    session[:user] = nil
    redirect '/'
end

get '/createIdea' do
    
    erb :createIdea
end

get '/createPost' do
    noun = Noun.find_by(id: params[:noun_id])
    verb = Verb.find_by(id: params[:verb_id])
    @noun_name = noun.name
    @verb_name = verb.name
    erb :createPost
end

get '/random_idea' do
    noun = Noun.order("RANDOM()").first
    verb = Verb.order("RANDOM()").first 
    content_type:json    
    {noun: noun.name,verb: verb.name}.to_json
end

get '/home' do
    likes = Like.where(user_id: session[:user][:id]).includes(:post)
    posts = []
    like_posts = []
    
    # userが投稿したもの
    Post.where(user_id: session[:user][:id]).each do |user_post|
        # いいねした人達
        like_users = Like.where(post_id: user_post.id)
        p like_users
        # いいねした人たちのimage
        user_imges = like_users.map{|like_user|like_user.user.img}
        posts << user_post.attributes.merge("user_imges": user_imges)
    end
    
    #いいねした投稿
    likes.map(&:post).each do |like|
        # いいねした人達
        like_users = Like.where(post_id: like.id)
        # # いいねした人たちのimage
        user_imges = like_users.map{|like_user|like_user.user.img}
        like_posts << like.attributes.merge("user_imges": user_imges)
    end
    
    @posts = posts
    @like_posts = like_posts
    erb :home
end

get '/post/:id/delete' do
    post_obj = Post.find_by(id:params[:id])
    post_obj.delete
    redirect "/home"
end

get '/post/:id/edit' do
    
    erb :edit
end

get '/post/:id/like' do
    like = Like.where(user_id: session[:user][:id],post_id: params[:id]).first
    
    if like.nil?
        Like.create(
            user_id:session[:user][:id],
            post_id: params[:id]
        )
    else 
        like.delete
    end
    redirect '/home'
end


post '/signin' do
    user = User.find_by(name: params[:name])
    
    if user && user.authenticate(params[:password])
      session[:user] = {
        name: params[:name],
        id: user.id,
        img: user.img,
      }
    end
    redirect '/search'
end

post '/signup' do
    
     # password validation
    if params[:password] != params[:password_confirm]
         redirect '/signup'
    end    
    
    # file validation
    unless params[:file]
         redirect '/signup'
    end    
    
    img_url = ''
    img = params[:file]
    tempfile = img[:tempfile]
    upload = Cloudinary::Uploader.upload(tempfile.path)
    img_url = upload['url']
    
    user = User.create(
        name: params[:name],
        password: params[:password],
        password_confirmation: params[:password_confirm],
        img: img_url
    )
    
    session[:user] = {
        name: params[:name],
        id: user.id,
        img: img_url,
    }
    
    redirect '/search'
end

post '/idea' do
    noun = Noun.find_by(name: params[:noun])
    verb = Verb.find_by(name: params[:verb])
    content_type :json
    success = true

    if noun.nil? 
      noun = Noun.create(name: params[:noun])
      unless noun.persisted?
        success = false
      end
    end

    if verb.nil?
      verb = Verb.create(name: params[:verb])
      unless verb.persisted?
        success = false
      end
    end

    response_body = 
    if success
        { success: 'Data received and stored successfully',noun_id: noun.id,verb_id: verb.id }.to_json
    else
        { error: 'Failed to store data' }.to_json
    end

    response_body
    # redirect "/createPost?noun=#{noun}&verb=#{verb}" 
end

post '/createPost' do
    category = Category.find_by(name: params[:category])
    is_open = false
    session[:user] ={ id:1}
    
    if params[:is_open]
        is_open = true
    end
    
    if category.nil?
       category = Category.create(name: params[:category])
    end
    postData = Post.create(
        title: params[:title],
        noun_id: params[:noun_id].to_i,
        verb_id: params[:verb_id].to_i,
        context: params[:context],
        question: params[:question],
        category_id: category.id,
        is_open: is_open,
        user_id: session[:user][:id].to_i
    )
    
    if postData.persisted?
        redirect '/'
    end
end

post '/post/:id/edit' do
    post_obj = Post.find_by(id: params[:id])
    post_obj.comment = params[:comment]
    post_obj.save
    
    redirect '/home'
end
