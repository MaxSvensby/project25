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
    if session[:id] != nil
        db = connect_db()

        item_ids = db.execute('SELECT item_id FROM user_item WHERE user_id = ?', [session[:id]])
        array = item_ids.map(&:values).flatten
        new_ids = []
        i = 0
        while i < array.length
            new_ids << array[i]
            i += 1
        end
        placeholders = new_ids.join(", ")
        p placeholders
        items = db.execute("SELECT * FROM items WHERE id IN (#{placeholders})").map(&:dup)
        items.each_with_index do |item, index|
            i = 0
            amount = 0
            while i < new_ids.length 
                if item["id"] == new_ids[i]
                    amount += 1
                end
                i+=1
            end
            item["amount"] = amount
        end
    else
        items = nil
    end
    slim(:inventory, locals:{items:items})
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
    adding_items.each do |item|
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
    amount = db.execute("SELECT amount FROM case_item WHERE case_id = ?", [id])
    new_ids = []
    i = 0
    while i < ids.length
        new_ids << ids[i][0]
        i += 1
    end
    placeholders = new_ids.join(", ")
    items = db.execute("SELECT * FROM items WHERE id IN (#{placeholders})").map(&:dup)
    items.each_with_index do |item, index|
        item << amount[index][0]
    end
    slim(:cases_open,locals:{result:result, items:items})
end

post ('/get_class') do
    class_name = params[:class_name]
    skin = class_name.split(',')
    skin[0] = skin[0].to_i    # Convert "29" to integer 29
    skin[3] = skin[3].to_f    # Convert "1" to float 1
    skin[4] = skin[4].to_f    # Convert "0.5" to float 0.5
    skin[7] = skin[7].to_i    # Convert "2" to integer 2

    db = SQLite3::Database.new('db/csgo.db')
    item_id = skin[0]
    db.execute('INSERT INTO user_item (user_id, item_id) VALUES (?,?)', [session[:id], item_id])
end

post ('/skin/sell') do



    redirect('/inventory')
end

def add_items()

    db = connect_db()

    Dir.glob("public/img/skins/mirage_2021/*").each do |image|
        filename = File.basename(image, ".*")
        db.execute('INSERT INTO items (name,rarity,value,wear,image,collection) VALUES (?,?,?,?,?,?)', [filename, "common", 1, 0.5, "image","mirage_2021"])
    end
end