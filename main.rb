require 'sqlite3'
require 'active_record'
require 'sinatra'
require 'sinatra/reloader'
require 'erb'

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection(:development)

enable :sessions

class Wasuremono < ActiveRecord::Base
end
class User < ActiveRecord::Base
end
class Family < ActiveRecord::Base
end
class Item < ActiveRecord::Base
end

get '/' do 
    if session[:user_id] == nil
        erb :home0 
    else 
        db = SQLite3::Database.new('Wasuremono.db')
        sql = "SELECT * FROM families WHERE user_id = ?"
        @families = db.execute(sql, session[:user_id])
        sql = "SELECT * FROM items WHERE family_id = ?"
        if session[:family_id] 
            @items = db.execute(sql, session[:family_id])
            if session[:done]==1
                if session[:voice]==2
                    session[:voice]=1
                end
                p session[:voice]
                erb :home
            else
                if session[:voice]!=2
                    session[:voice]=2
                end
                p session[:voice]
                erb :about
            end
        end
        if session[:done]==1
            erb :home
        else
            erb :about
        end
    end
end
get '/signup' do 
    erb :signup 
end
post '/signup' do 
    db = SQLite3::Database.new('Wasuremono.db')
    sql = 'SELECT * FROM users WHERE family_id = ?'
    already = db.execute(sql,params['family_id'])
    if already.empty?
        User.create(
            name: params['family_name'],
            password: params['password'],
            family_id: params['family_id']
        )
        sql = 'SELECT * FROM users WHERE family_id = ?'
        user = db.execute(sql,params['family_id']).first
        session[:user_id] = user[0]
        session[:user_name] = user[1]
        p session[:user_id]
        redirect '/'
    end
    redirect '/signup2'
end
get '/signup2' do
    erb :signup2
end
get '/login' do 
    erb :login 
end
post '/login' do 
    session[:already]=0
    session[:voice]=0
    db = SQLite3::Database.new('Wasuremono.db')
    sql = "SELECT * FROM users WHERE family_id = ? AND password = ?"
    user = db.execute(sql,params['family_id'],params['password']).first
    if user==nil
        redirect '/login2'
    else
        session[:user_id] = user[0]
        session[:user_name] = user[1]
        redirect '/'
    end
end
get '/login2' do
    erb :login2
end
get '/logout' do
    session.clear
    redirect '/'
end
post '/family_create' do
    Family.create(
        name: params['name'],
        user_id: session[:user_id],
        done: 0
    )
    redirect '/'
end
get '/about' do
    db = SQLite3::Database.new('Wasuremono.db')
    sql = "SELECT * FROM families WHERE user_id = ?"
    @families = db.execute(sql,session[:user_id]);
    erb :about
end
post '/family_item' do
    session[:family_id] = params[:family_id]
    db = SQLite3::Database.new('Wasuremono.db')
    sql = "SELECT * FROM families WHERE id = ?"
    family = db.execute(sql, session[:family_id]).first
    session[:done] = family[3]
    session[:family_name] = family[1]
    redirect '/'
end
post '/add_item' do
    db = SQLite3::Database.new('Wasuremono.db')
    Item.create(
        name: params['name'],
        family_id: session[:family_id],
        done: 0
    )
    redirect '/'
end
post '/done' do
    arr = params[:selected_items]
    if arr
        db = SQLite3::Database.new('Wasuremono.db')
        arr.each do |z|
            sql = "UPDATE items SET done = 1 WHERE id = ?"
            db.execute(sql, z.to_i)
        end
        db.close
    end
    redirect '/'
end
get '/switch' do
    if session[:done]==0
        db = SQLite3::Database.new('Wasuremono.db')
        session[:done] = 1 
        sql = "UPDATE families SET done = 1 WHERE id = ?"
        db.execute(sql, session[:family_id])
        p "inm" 
    elsif session[:done]==1
        db = SQLite3::Database.new('Wasuremono.db')
        sql = "UPDATE families SET done = 0 WHERE id = ?"
        db.execute(sql, session[:family_id])
        sql = "UPDATE items SET done = 0 WHERE family_id = ?"
        db.execute(sql, session[:family_id])
        session[:done]=0
        p "Rubyコードが実行されました"
    end
    redirect '/'
end
get '/credit' do
    erb :credit
end
get '/readme' do
    erb :readme;
end
post '/sakujo' do
    arr = params[:selected_items]
    if arr
        db = SQLite3::Database.new('Wasuremono.db')
        arr.each do |z|
            sql = "DELETE FROM items WHERE id = ?"
            db.execute(sql, z.to_i)
        end
        db.close
    end
    redirect '/'
end