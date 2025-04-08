require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require 'json'
require 'sinatra/flash'
require_relative './model/model.rb'

enable:sessions

admin_paths = ['/cases/new', '/case/:id/edit']
before (admin_paths) do
    result = checkAdmin(session[:id])
    if session[:id] == nil || result[0]["admin"] == nil
        flash[:notice] = "You need admin role to create cases!"
        redirect('/')
    end
end

get ('/') do
    result = getCases()
    slim(:"index", locals:{cases:result})
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
        addUser(username, password_digest, balance, admin)
        redirect('/')
    else
        redirect("/loginpage")
    end
end

post ('/login') do
    username = params[:username]
    password = params[:password]
    result = getUser(username)

    cooldown_period = 60 # seconds
    max_attempts = 3

    # Initialize session storage
    session[:login_attempts] ||= 0
    session[:last_attempt_time] ||= Time.now - cooldown_period
    
    if session[:login_attempts] >= max_attempts
        if Time.now - session[:last_attempt_time] < cooldown_period
            flash[:notice] = "Too many login attempts. Please wait #{(cooldown_period - (Time.now - session[:last_attempt_time])).to_i} #{} seconds."
            redirect('/loginpage')
        else
            # Cooldown has passed, reset attempts
            session[:login_attempts] = 0
        end
    end

    if result.nil?
        session[:login_attempts] += 1
        session[:last_attempt_time] = Time.now
        flash[:notice] = "User not found!"
        redirect("/loginpage")
    else
        pwdigest = result["pwdigest"]
        id = result["id"]
        if BCrypt::Password.new(pwdigest) == password
            session[:id] = id
            session[:login_attempts] = 0 # Reset on success
            redirect('/')
        else
            session[:login_attempts] += 1
            session[:last_attempt_time] = Time.now
            flash[:notice] = "Wrong password!"
            redirect('/loginpage')
        end
    end
end

post ('/logout') do
    session[:id] = nil
    redirect('/')
end

get ('/items/') do
    if session[:id] != nil
        items = retrieveItemsFromUser(session[:id])
    else
        items = nil
    end
    slim(:inventory, locals:{items:items})
end

adding_items = nil
get ('/cases/new') do
    if !adding_items
        adding_items = []
    end
    if params[:add_item]
        parsed_item = JSON.parse(params[:add_item])
        adding_items << parsed_item
    end

    slim(:create, locals:{adding_items: adding_items, item_selected: params[:item_selected]})
end

post ('/item/select') do
    inferno_item = params[:inferno]
    mirage_item = params[:mirage]
    amount_mirage = params[:amount_mirage]
    amount_inferno = params[:amount_inferno]

    if inferno_item == "none" && mirage_item != "none"
        add_item = [mirage_item, amount_mirage]
    elsif mirage_item == "none" && inferno_item != "none"
        add_item = [inferno_item, amount_inferno]
    end

    redirect "/cases/new?add_item=#{add_item}" if add_item
    redirect "/cases/new"
end

post ('/item/confirm') do
    item_selected = true

    redirect "/cases/new?item_selected=#{item_selected}" if item_selected
    redirect "/cases/new"
end

post ('/item/reset') do
    adding_items = nil
    redirect('/cases/new')
end

post ('/cases') do
    case_name = params[:case_name]
    case_color = params[:case_color]
    case_price = params[:case_price]

    addCase(case_name, case_price, case_color)
    case_id = getCaseId()["id"].to_i
    adding_items.each do |item|
        item_id = getItemId(item)[0]["id"].to_i
        addItemToCase(case_id, item_id, item)
    end
    adding_items = nil
    redirect('/cases/new')
end

get ('/case/:id') do
    id = params[:id].to_i

    result = getCaseFromId(id)
    items = retrieveItemsFromCase(id)

    slim(:"case/index",locals:{result:result, items:items})
end

get ('/case/:id/edit') do 
    id = params[:id].to_i
    case_item = getCaseFromId(id)

    slim(:"case/case_update", locals:{case_item:case_item})
end

post ('/case/:id/update') do
    case_name = params[:case_name]
    case_color = params[:case_color]
    case_price = params[:case_price]
    case_id = params[:id]

    updateCase(case_id,case_name,case_price,case_color)

    redirect("/")
end

post ('/items') do
    class_name = params[:class_name]
    skin = class_name.split(',')
    skin[0] = skin[0].to_i    # Convert "29" to integer 29
    item_id = skin[0]
    amount = getAmountFromUserItem(session[:id], item_id)
    if amount != []
        updateUserItemWithAmount(amount[0]["amount"] + 1, session[:id], item_id)
    else
        addItemToUser(session[:id], item_id, 1)
    end
end

post ('/items/skin/:item_id/delete') do
    item_id = params[:item_id].to_i
    user_id = session[:id].to_i

    amount = getAmountFromUserItem(user_id, item_id)[0]["amount"]
    if amount > 1
        updateUserItemWithAmount(amount - 1, user_id, item_id)
    else
        deleteItem(item_id, user_id)
    end

    redirect('/items/')
end

def add_items()

    Dir.glob("public/img/skins/mirage_2021/*").each do |image|
        filename = File.basename(image, ".*")
        addItem(filename)
    end
end