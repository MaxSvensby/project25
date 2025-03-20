require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require 'json'

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
        "User not found!"
    else
        pwdigest = result["pwdigest"]
        id = result["id"]
        if BCrypt::Password.new(pwdigest) == password
            session[:id] = id
            redirect('/')
        else
            "WRONG PASSWORD"
        end
    end
end

post ('/logout') do
    session[:id] = nil
    redirect('/')
end

get ('/inventory') do
    slim(:inventory)
end

adding_items = nil
get ('/create') do
    if !adding_items
        adding_items = []
    end
    if params[:add_item]
        parsed_item = JSON.parse(params[:add_item])
        adding_items << parsed_item
    end

    slim(:create, locals:{adding_items: adding_items, item_selected: params[:item_selected]})
end

post ('/item_select') do
    inferno_item = params[:inferno]
    mirage_item = params[:mirage]
    amount_mirage = params[:amount_mirage]
    amount_inferno = params[:amount_inferno]

    if inferno_item == "none" && mirage_item != "none"
        add_item = [mirage_item, amount_mirage]
    elsif mirage_item == "none" && inferno_item != "none"
        add_item = [inferno_item, amount_inferno]
    end

    redirect "/create?add_item=#{add_item}" if add_item
    redirect "/create"
end

post ('/item_confirm') do
    item_selected = true

    redirect "/create?item_selected=#{item_selected}" if item_selected
    redirect "/create"
end

post ('/item_reset') do
    adding_items = nil
    redirect('/create')
end


post ('/case/new') do
    case_name = params[:case_name]
    case_color = params[:case_color]
    case_price = params[:case_price]

    db = SQLite3::Database.new('db/csgo.db')

    db.execute('INSERT INTO cases (name, price, color) VALUES (?,?,?)', [case_name,case_price,case_color])
    case_id = db.execute('SELECT id FROM cases').last
    p adding_items
    adding_items.each do |item|
        p item[0]
        item_id = db.execute('SELECT id FROM items WHERE name = ?', [item[0]])
        db.execute('INSERT INTO case_item (case_id, item_id, amount) VALUES (?,?,?)', [case_id, item_id, item[1]])
    end
    adding_items = nil
    redirect('/create')
end

get ('/case/open/:id') do
    id = params[:id].to_i

    db = connect_db()
    result = db.execute("SELECT * FROM cases WHERE id = ?", [id]).first

    db = SQLite3::Database.new('db/csgo.db')

    ids = db.execute("SELECT item_id FROM case_item WHERE case_id = ?", [id])
    new_ids = []
    i = 0
    while i < ids.length
        new_ids << ids[i][0]
        i += 1
    end
    placeholders = new_ids.join(", ")
    items = db.execute("SELECT * FROM items WHERE id IN (#{placeholders})")
    slim(:cases_open,locals:{result:result, items:items})
end

def add_items()

    db = connect_db()

    Dir.glob("public/img/skins/mirage_2021/*").each do |image|
        filename = File.basename(image, ".*")
        db.execute('INSERT INTO items (name,rarity,value,wear,image,collection) VALUES (?,?,?,?,?,?)', [filename, "common", 1, 0.5, "image","mirage_2021"])
    end
end