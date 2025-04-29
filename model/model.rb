
# Establishes a connection to the SQLite3 database
#
# @return [SQLite3::Database] the database connection
def connect_db()
    db = SQLite3::Database.new('db/csgo.db')
    db.results_as_hash = true
    return db
end

# Checks if a user is an admin
#
# @param [Integer] id the user ID
# @return [Array<Hash>] containing the "admin" column
def checkAdmin(id)
    db = connect_db()
    return db.execute('SELECT admin FROM users WHERE id = ?', [id])
end

# Retrieves all cases from the database
#
# @return [Array<Hash>] list of cases
def getCases()
    return connect_db().execute("SELECT * FROM cases")
end

# Adds a new user to the database
#
# @param [String] username the user's name
# @param [String] password_digest hashed password
# @param [Integer] balance initial balance
# @param [Boolean] admin whether the user is an admin
# @return [void]
def addUser(username, password_digest,balance,admin)
    connect_db().execute('INSERT INTO users (username,pwdigest,balance,admin) VALUES (?,?,?,?)', [username,password_digest,balance,admin])
end

# Retrieves a user by username
#
# @param [String] username
# @return [Hash, nil] user data or nil if not found
def getUser(username)
    return connect_db().execute("SELECT * FROM users WHERE username = ?", [username]).first
end

def getAllUsers()
    return connect_db().execute("SELECT * FROM users")
end

def deleteUser(id)
    db = connect_db()
    db.execute('DELETE FROM user_item WHERE user_id = ?', [id])
    db.execute('DELETE FROM users WHERE id = ?', [id])
end

# Adds a new case to the database
#
# @param [String] case_name
# @param [Float] case_price
# @param [String] case_color
# @return [void]
def addCase(case_name, case_price, case_color)
    connect_db().execute('INSERT INTO cases (name, price, color) VALUES (?,?,?)', [case_name,case_price,case_color])
end

# Gets the ID of the last inserted case
#
# @return [Hash] the last case ID
def getCaseId()
    return connect_db().execute('SELECT id FROM cases').last
end

# Retrieves the ID of an item by its name
#
# @param [Array] item an array where the first element is the item name
# @return [Array<Hash>] list of matching items
def getItemId(item)
    return connect_db().execute('SELECT id FROM items WHERE name = ?', [item[0]])
end

# Links an item to a case with a given amount
#
# @param [Integer] case_id
# @param [Integer] item_id
# @param [Array] item item data with name and amount
# @return [void]
def addItemToCase(case_id, item_id, item)
    connect_db().execute('INSERT INTO case_item (case_id, item_id, amount) VALUES (?,?,?)', [case_id, item_id, item[1]])
end

# Retrieves full data of a case by ID
#
# @param [Integer] id
# @return [Hash, nil] the case data
def getCaseFromId(id)
    return connect_db().execute("SELECT * FROM cases WHERE id = ?", [id]).first
end

# Retrieves item IDs and their amounts for a given case
#
# @param [Integer] id the case ID
# @return [Array<Array<Hash>>] item IDs and amounts
def getIdsAmount(id)
    db = connect_db()
    return db.execute("SELECT item_id FROM case_item WHERE case_id = ?", [id]), db.execute("SELECT amount FROM case_item WHERE case_id = ?", [id])
end

# Retrieves item data from a list of item IDs
#
# @param [String] placeholders comma-separated list of item IDs
# @return [Array<Hash>] list of item data
def getItemFromIds(placeholders)
    return connect_db().execute("SELECT * FROM items WHERE id IN (#{placeholders})").map(&:dup)
end

# Gets the amount of a specific item owned by a user
#
# @param [Integer] id user ID
# @param [Integer] item_id
# @return [Array<Hash>] containing the amount
def getAmountFromUserItem(id, item_id)
    return connect_db().execute('SELECT amount FROM user_item WHERE user_id = ? AND item_id = ?', [id, item_id])
end

# Updates the quantity of a user-owned item
#
# @param [Integer] amount new amount
# @param [Integer] id user ID
# @param [Integer] item_id
# @return [void]
def updateUserItemWithAmount(amount, id, item_id)
    connect_db().execute('UPDATE user_item SET amount = ? WHERE user_id = ? AND item_id = ?', [amount, id, item_id])
end

# Adds an item to a user's inventory
#
# @param [Integer] user_id
# @param [Integer] item_id
# @param [Integer] amount
# @return [void]
def addItemToUser(user_id, item_id, amount)
    connect_db().execute('INSERT INTO user_item (user_id, item_id, amount) VALUES (?,?,?)', [user_id, item_id, amount])
end

# Deletes an item from a user's inventory
#
# @param [Integer] item_id
# @param [Integer] user_id
# @return [void]
def deleteItem(item_id, user_id)
    connect_db().execute('DELETE FROM user_item WHERE item_id = ? AND user_id = ?', [item_id, user_id])
end

# Adds a new item to the item database
#
# @param [String] filename the item name
# @return [void]
def addItem(filename)
    connect_db().execute('INSERT INTO items (name,rarity,value,wear,image,collection) VALUES (?,?,?,?,?,?)', [filename, "common", 1, 0.5, "image","mirage_2021"])
end

# Updates an existing case's information
#
# @param [Integer] id case ID
# @param [String] case_name
# @param [Float] case_price
# @param [String] case_color
# @return [void]
def updateCase(id, case_name,case_price,case_color)
    connect_db().execute('UPDATE cases SET name = ?, price = ?, color = ? WHERE id = ?', [case_name,case_price,case_color,id])
end


# Retrieves all items owned by a specific user
#
# @param [Integer] id user ID
# @return [Array<Hash>] list of user-owned items
def retrieveItemsFromUser(id)
    return connect_db().execute("SELECT * FROM items INNER JOIN user_item ON user_item.item_id = items.id AND user_id = ?",[id])
end


# Retrieves all items associated with a specific case
#
# @param [Integer] id case ID
# @return [Array<Hash>] list of items in the case
def retrieveItemsFromCase(id)
    return connect_db().execute("SELECT * FROM items INNER JOIN case_item ON case_item.item_id = items.id AND case_id = ?", [id])
end