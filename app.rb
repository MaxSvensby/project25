require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

get ('/') do
    slim(:home)
end

get ('/inventory') do
    slim(:inventory)
end

get ('/create') do
    slim(:create)
end