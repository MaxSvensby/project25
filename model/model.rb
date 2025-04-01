def connect_db()
    db = SQLite3::Database.new('db/csgo.db')
    db.results_as_hash = true
    return db
end

def checkAdmin(id)
    db = connect_db()
    return db.execute('SELECT admin FROM users WHERE id = ?', [id])
end

def getCases()
    return connect_db().execute("SELECT * FROM cases")
end

def addUser(username, password_digest,balance,admin)
    connect_db().execute('INSERT INTO users (username,pwdigest,balance,admin) VALUES (?,?,?,?)', [username,password_digest,balance,admin])
end

def getUser(username)
    return connect_db().execute("SELECT * FROM users WHERE username = ?", [username]).first
end

def addCase(case_name, case_price, case_color)
    connect_db().execute('INSERT INTO cases (name, price, color) VALUES (?,?,?)', [case_name,case_price,case_color])
end

def getCaseId()
    return connect_db().execute('SELECT id FROM cases').last
end

def getItemId(item)
    return connect_db().execute('SELECT id FROM items WHERE name = ?', [item[0]])
end

def addItemToCase(case_id, item_id, item)
    connect_db().execute('INSERT INTO case_item (case_id, item_id, amount) VALUES (?,?,?)', [case_id, item_id, item[1]])
end

def getCaseFromId(id)
    return connect_db().execute("SELECT * FROM cases WHERE id = ?", [id]).first
end

def getIdsAmount(id)
    db = SQLite3::Database.new('db/csgo.db')
    return db.execute("SELECT item_id FROM case_item WHERE case_id = ?", [id]), db.execute("SELECT amount FROM case_item WHERE case_id = ?", [id])
end

def getItemFromIds(placeholders)
    db = SQLite3::Database.new('db/csgo.db')
    return db.execute("SELECT * FROM items WHERE id IN (#{placeholders})").map(&:dup)
end

def getAmountFromUserItem(id, item_id)
    return db.execute('SELECT * FROM user_item WHERE user_id = ? AND item_id = ?', [id, item_id])
end

def updateUserItemWithAmount(amount, id, item_id)
    db.execute('UPDATE user_item SET amount = ? WHERE user_id = ? AND item_id = ?', [amount, id, item_id])
end