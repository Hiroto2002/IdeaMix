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
    posts = []
    
    Post.all.each do |value|
        like_text = "いいねする"
        # 投稿者
        post_user_name = value.user.name
        
        # いいねした人達
        like_users = Like.where(post_id: value.id)
        p like_users
        p "---------------------"
        # 投稿にいいねしているのが自分だったら
        unless session[:user].nil?
            like_users.each do |like_user|
                if like_user.user_id == session[:user][:id]
                    like_text = "いいねを解除する"
                end
            end
        end
    
        # いいねした人たちのimage
        user_imges = like_users.map{|like_user|like_user.user.img}
       
        # 全てを配列に
        posts << value.attributes.merge(user_imges: user_imges,user_name: post_user_name,like_text: like_text)
    end
    
    @posts = posts
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
    erb :createPost
end

get '/random_idea' do
    noun = Noun.order("RANDOM()").first
    verb = Verb.order("RANDOM()").first 
    content_type:json    
    {noun: noun.name,verb: verb.name}.to_json
end





get '/search' do
    unless params[:keyword].to_s.empty?
        @musics = ITunesSearchAPI.search(
              :term    => params[:keyword],
              :country => 'jp',
              :media   => 'music',
              :lang    => 'ja_jp',
              :limit  => '10'
        )
    end
    erb :search
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
        { success: 'Data received and stored successfully' }.to_json
    else
        { error: 'Failed to store data' }.to_json
    end

    response_body
    # redirect "/createPost?noun=#{noun}&verb=#{verb}" 
end

post '/post' do
    Post.create(
        artist: params[:artistName],
        album: params[:collectionName],
        music: params[:trackName],
        link: params[:previewUrl],
        img: params[:artworkUrl100],
        comment: params[:comment],
        user_id: session[:user][:id]
    )
    redirect '/home'
end

post '/post/:id/edit' do
    post_obj = Post.find_by(id: params[:id])
    post_obj.comment = params[:comment]
    post_obj.save
    
    redirect '/home'
end
