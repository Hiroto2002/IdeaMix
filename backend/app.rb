require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require './models'
require 'dotenv/load'
require 'json'
require 'sinatra'
require 'sinatra/cross_origin'
require "openai"

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
    # posts = Post.where(is_open:true).order(id: "DESC")
    posts = Post.where(is_open:false).order(id: "DESC")
    
    new_posts = []
    
     posts.each do |_post|
          
        if params[:keyword]
            unless _post.title.include?(params[:keyword]) || _post.categories.name.include?(params[:keyword])
                next
            end
        end
        
        # いいねした人達の数
        like =  Like.where(post_id: _post.id)
        isLike = session[:user] ? Like.find_by(user_id: session[:user][:id],post_id: _post.id) : false 
        user = User.find_by(id: _post.user_id)
       
        new_posts << _post.attributes.merge(
                                            "like_count": like.count,
                                            "user_img": user.img,
                                            "user_name": user.name,
                                            "isLike": isLike ? "like" : "dislike"
                                            )
    end
    
    @posts = new_posts
    erb :index
end

get '/signup' do
    if session[:user]
        redirect '/'
    end
    erb :signup
end

get '/signout' do
    session[:user] = nil
    redirect '/siginin'
end

get '/signin' do
    if session[:user]
        redirect '/'
    end
    erb:signin
end

get '/createIdea' do
     if session[:user].nil?
        redirect '/signin'
    end
    erb :createIdea
end

get '/createPost' do
    unless session[:user]
        redirect '/signin'
    end
    noun = Noun.find_by(id: params[:noun_id])
    verb = Verb.find_by(id: params[:verb_id])
    @noun_name = noun.name
    @verb_name = verb.name
    erb :createPost
end

get '/random_noun' do
    noun = Noun.order("RANDOM()").first
    content_type:json    
    {noun: noun.name}.to_json
end


get '/random_verb' do
    verb = Verb.order("RANDOM()").first
    content_type:json    
    {verb: verb.name}.to_json
end

get '/random_idea' do
    noun = Noun.order("RANDOM()").first
    verb = Verb.order("RANDOM()").first 
    content_type:json    
    {noun: noun.name,verb: verb.name}.to_json
end

get '/post/:id/edit' do
    
    erb :edit
end

get '/post/:id/delete' do
    _post = Post.find_by(id: params[:id])
    
    if session[:user][:name] === _post.user.name
        _post.delete
        redirect '/'    
    end
    
end

get '/post/:id' do
    _post = Post.find_by(id: params[:id])
    like = Like.where(post_id: params[:id])
    comments = Comment.where(post_id: params[:id].to_i).order(id:"DESC")
    @comments = comments
    @post = _post
    @user = _post.user
    @like_count = like.count.to_i
    erb :post
end

get '/profile' do
    unless session[:user]
        redirect '/signin'
    end
    posts = []
    new_posts = []
    
    if params[:tab] === "post"
        posts = Post.where(user_id:session[:user][:id]).order(id: "DESC")
        posts.each do |_post|
            # いいねした人達の数
            isLike = session[:user] ? Like.find_by(user_id: session[:user][:id],post_id: _post.id) : false 
            like_count = Like.where(post_id: _post.id).count
            user = User.find_by(id: _post.user_id)
            new_posts << _post.attributes.merge("like_count": like_count,"user_img": user.img,"user_name": user.name,"isLike": isLike ? "like" : "dislike")
        end
    else
        likes = Like.where(user_id:session[:user][:id]).order(id: "DESC")
          likes.each do |like|
            post_info = like.post
            isLike = session[:user] ? Like.find_by(user_id: session[:user][:id],post_id: post_info.id) : false 
            like_count = Like.where(post_id: post_info.id).count
            user = User.find_by(id: post_info.user_id)
            new_posts << post_info.attributes.merge("like_count": like_count,"user_img": user.img,"user_name": user.name,"isLike": isLike ? "like" : "dislike")
        end
    end
    
    
     
    
    @posts = new_posts
    erb :profile
end

get '/logout' do
    session[:user] = nil
    redirect '/signin'
end

post '/signin' do
    user = User.find_by(email: params[:email])
    
    if user && user.authenticate(params[:password])
      session[:user] = {
        name: user.name,
        id: user.id,
        img: user.img,
      }
        redirect '/'
    else
       redirect '/signin' 
    end
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
    
    img_url = '/assets/img/default.svg'
    img = params[:file]
    tempfile = img[:tempfile]
    upload = Cloudinary::Uploader.upload(tempfile.path)
    img_url = upload['url']
    
    user = User.create(
        name: params[:name],
        email: params[:email],
        password: params[:password],
        password_confirmation: params[:password_confirm],
        img: img_url
    )
    # session[:user] = {
    #     name: params[:name],
    #     id: user.id,
    #     img: img_url,
    # }
    if user.persisted?
        redirect '/signin'
    end
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

post '/autoPost' do
    
    body = request.body.read
    

    title = JSON.parse(body)['title']
    content_type :json
    
    prompt = <<-"EOS"
        "#{title}"サービスに付いて考えます。次の各項目をkeyにしjsonで生成してください
        overview:具体的な手法を含めた概要を200文字以下
        solution:.このサービスが解決する課題を200文字以下
    EOS
    
    # p prompt
    
    client = OpenAI::Client.new(access_token: ENV['GPT_API_KEY'])
    
    response = client.chat(
        parameters: {
            model: "gpt-3.5-turbo",
            messages: [{ role: "user", content: prompt}],
            temperature: 0.7,
    })
    
    { message: response.dig("choices", 0, "message", "content")}.to_json
end

post '/createPost' do
    category = Category.find_by(name: params[:category])
    is_open = false
    
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

post '/like' do
    body = request.body.read
    

    id = JSON.parse(body)['id']
    count = JSON.parse(body)['count']
    content_type :json
    
    like = Like.where(user_id: session[:user][:id],post_id: id).first
    
    if like.nil?
        Like.create(
            user_id:session[:user][:id],
            post_id: id
        )
        count+=1
        isLike = "/assets/img/like.svg"
    else 
        like.delete
        count-=1
        isLike = '/assets/img/dislike.svg'
    end
    
    { count: count,isLike: isLike}.to_json

    
end

post '/post/:id/edit' do
    post_obj = Post.find_by(id: params[:id])
    post_obj.comment = params[:comment]
    post_obj.save
    
    redirect '/home'
end

post '/comment/:id' do
    Comment.create(
        comment: params[:comment],
        user_id: session[:user][:id],
        post_id:params[:id]
    )
    redirect "/post/#{params[:id]}#post_comment"
end

