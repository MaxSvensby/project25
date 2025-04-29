require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require 'json'
require 'sinatra/flash'
require_relative './model/model.rb'

enable:sessions

admin_paths = ['/cases/new', '/case/:id/edit', '/users/']

# Before filter to restrict access to admin-only routes
#
# @param [Integer] session[:id] the current user's ID
#
# @return [void]
before (admin_paths) do
    result = checkAdmin(session[:id])
    if session[:id] == nil || result[0]["admin"] == nil
        flash[:notice] = "You need admin role to create cases!"
        redirect('/')
    end
end

# Displays the home page with all cases
#
# @return [Slim] the rendered homepage
get ('/') do
    result = getCases()
    slim(:"index", locals:{cases:result})
end

# Renders the login and registration page
#
# @return [Slim]
get ('/loginpage') do
    slim(:loginpage)
end

# Handles user registration and creates a new user if passwords match
#
# @param [String] username
# @param [String] password
# @param [String] password_confirm
# @param [String] admin
#
# @return [Redirect]
post ('/register') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    admin = params[:admin]

    if username.strip.empty? || password.strip.empty? || password_confirm.strip.empty?
        flash[:notice] = "Fill in the fields"
        redirect('/loginpage')
    end

    if (password == password_confirm)
        balance = 0
        password_digest = BCrypt::Password.create(password)
        addUser(username, password_digest, balance, admin)
        redirect('/')
    else
        redirect("/loginpage")
    end
end

# Handles user login and applies rate limiting after failed attempts
#
# @param [String] username
# @param [String] password
#
# @return [Redirect]
post ('/login') do
    username = params[:username]
    password = params[:password]

    if username.strip.empty? || password.strip.empty?
        flash[:notice] = "Fill in the fields"
        redirect('/loginpage')
    end

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

# Logs out the user by clearing session
#
# @return [Redirect]
post ('/logout') do
    session[:id] = nil
    redirect('/')
end

# Displays the current user's item inventory
#
# @return [Slim]
get ('/items/') do
    if session[:id] != nil
        items = retrieveItemsFromUser(session[:id])
    else
        items = nil
    end
    slim(:inventory, locals:{items:items})
end

get ('/users/') do
    all_users = getAllUsers()
    slim(:users, locals:{users:all_users})
end

post ('/user/:id/delete') do
    user_id = params[:id]
    if session[:id] == user_id.to_i
        session[:id] = nil
    end
    deleteUser(user_id)
    redirect('/users/')
end

adding_items = nil

# Renders the case creation page with optionally added items
#
# @return [Slim]
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

# Adds an item selection from the form to the current case-in-progress
#
# @return [Redirect]
post ('/item/select') do
    inferno_item = params[:inferno]
    mirage_item = params[:mirage]
    amount_mirage = params[:amount_mirage]
    amount_inferno = params[:amount_inferno]

    if inferno_item == "none" && mirage_item != "none"
        if amount_mirage == ""
            amount_mirage = "1"
        end
        add_item = [mirage_item, amount_mirage]
    elsif mirage_item == "none" && inferno_item != "none"
        if amount_inferno == ""
            amount_inferno = "1"
        end
        add_item = [inferno_item, amount_inferno]
    else
        flash[:notice] = "You need to select an item"
        redirect("/cases/new")
    end

    redirect "/cases/new?add_item=#{add_item}" if add_item
    redirect "/cases/new"
end

# Confirms the currently selected items for the case
#
# @return [Redirect]
post ('/item/confirm') do
    if adding_items == [] || adding_items == nil
        flash[:notice] = "You need to add an item"
        redirect("/cases/new")
    end
    item_selected = true

    redirect "/cases/new?item_selected=#{item_selected}" if item_selected
    redirect "/cases/new"
end

# Resets the currently added items during case creation
#
# @return [Redirect]
post ('/item/reset') do
    adding_items = nil
    redirect('/cases/new')
end

# Finalizes case creation and adds it along with items to the database
#
# @return [Redirect]
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

# Shows the details and contents of a case
#
# @param [Integer] id the case ID
#
# @return [Slim]
get ('/case/:id') do
    id = params[:id].to_i

    result = getCaseFromId(id)
    items = retrieveItemsFromCase(id)
    
    slim(:"case/index",locals:{result:result, items:items})
end

# Renders the case edit form for admins
#
# @param [Integer] id
#
# @return [Slim]
get ('/case/:id/edit') do 
    id = params[:id].to_i
    case_item = getCaseFromId(id)

    slim(:"case/case_update", locals:{case_item:case_item})
end


# Updates a case with new data from the form
#
# @param [Integer] id
#
# @return [Redirect]
post ('/case/:id/update') do
    case_name = params[:case_name]
    case_color = params[:case_color]
    case_price = params[:case_price]
    case_id = params[:id]

    updateCase(case_id,case_name,case_price,case_color)

    redirect("/")
end

# Adds an item to the current user's inventory
#
# @param [String] class_name the item string including ID and name
#
# @return [void]
post ('/items') do
    item_id = params[:class_name].to_i
    amount = getAmountFromUserItem(session[:id], item_id)
    
    if amount != []
        updateUserItemWithAmount(amount[0]["amount"] + 1, session[:id], item_id)
    else
        addItemToUser(session[:id], item_id, 1)
    end
end

# Removes an item from a user's inventory
#
# @param [Integer] item_id the ID of the item to delete
#
# @return [Redirect]
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


# Adds all items found in the Mirage 2021 skin directory to the database
#
# @return [void]
def add_items()

    Dir.glob("public/img/skins/mirage_2021/*").each do |image|
        filename = File.basename(image, ".*")
        addItem(filename)
    end
end