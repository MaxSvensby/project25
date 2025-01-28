require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable:sessions

before do
    p "Körs innan alla routes, kolla om man är inloggad"
end

def connect_db()
    db = SQLite3::Database.new('db/csgo.db')
    db.results_as_hash = true
    return db
end

get ('/') do
    slim(:home)
end

get ('/loginpage') do
    slim(:loginpage)
end

get ('/inventory') do
    slim(:inventory)
end

get ('/create') do
    slim(:create)
end