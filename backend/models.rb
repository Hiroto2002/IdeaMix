require 'bundler/setup'
Bundler.require

ActiveRecord::Base.establish_connection

class Post < ActiveRecord::Base
    has_many:likes
    has_many:users, :through => :likes
    belongs_to :user
end

class User < ActiveRecord::Base
    has_secure_password
    validates :name,
        presence:true
    validates :password,
        format: {with:/(?=.*?[a-z])(?=.*?[0-9])/},
        length:{in: 5..10}
    has_many:likes
    has_many:post,:through => :likes
end

class Like < ActiveRecord::Base
    belongs_to:user
    belongs_to:post
end