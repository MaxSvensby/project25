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
    db = connect_db()

    result = db.execute("SELECT * FROM cases")

    p result

    slim(:"home", locals:{cases:result})
end

get ('/loginpage') do
    slim(:loginpage)
end

post ('/register') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    admin = params[:admin]

    if (password == password_confirm)
        balance = 0
        password_digest = BCrypt::Password.create(password)
        db = SQLite3::Database.new('db/csgo.db')
        db.execute('INSERT INTO users (username,pwdigest,balance,admin) VALUES (?,?,?,?)', [username,password_digest,balance,admin])
        redirect('/')
    else
        redirect('/loginpage')
    end
end

post ('/login') do
    username = params[:username]
    password = params[:password]
    db = connect_db()
    result = db.execute("SELECT * FROM users WHERE username = ?", [username]).first
    if result.nil?
        "User not found"
    else
        pwdigest = result["pwdigest"]
        id = result["id"]
        if BCrypt::Password.new(pwdigest) == password
            session[:id] = id
            redirect('/')
        else
            "FEL LÖSENORD"
        end
    end
end

get ('/inventory') do
    slim(:inventory)
end

get ('/create') do
    slim(:create)
end

post ('/case/new') do
    case_name = params[:case_name]
    case_color = params[:case_color]
    case_price = params[:case_price]

    db = SQLite3::Database.new('db/csgo.db')
    db.execute('INSERT INTO cases (name, price, color) VALUES (?,?,?)', [case_name,case_price,case_color])

    redirect('/create')
end