require "pg"


class DatabasePersistence

	def initialize(logger)
		@db = if Sinatra::Base.production?
        		PG.connect(ENV['DATABASE_URL'])
      		else
        		PG.connect(dbname: "todos")
      		end
		@logger = logger
	end

	def query(statement, *params)
		@logger.info("#{statement}: #{params}")
		@db.exec_params(statement, params)
	end

	def all_lists
		sql = "SELECT * FROM list;"
		result = query(sql)

		result.map do |tuple|
			list_id = tuple["id"]
			{id: list_id, name: tuple["name"]}
		end

	end

	def add_list(list_name)
		sql = "INSERT INTO list(name) VALUES($1)"
		query(sql, list_name)
	end

	def delete_list(id)
		sql = "DELETE FROM list WHERE id = $1"
		query(sql, id)
	end

	def get_list(id)
		sql = "SELECT * FROM list WHERE id = $1"
		result = query(sql, id)


		tuple = result.first


		 todo_sql = "SELECT * FROM todo WHERE list_id = $1"

		 todos_result = query(todo_sql, tuple["id"])

		 todos = todos_result.map do |todo_tuple|
		    	{ id: todo_tuple["id"],
		    	 name: todo_tuple["name"], 
		    	 completed: todo_tuple["completed"] == 't' }
		    end


		{id: tuple["id"], name: tuple["name"], todos: todos}
	end

	def count_remaining_todos(list_id)
	  sql = "SELECT COUNT(id) FROM todo WHERE list_id = $1 AND completed IS FALSE"
	  result = query(sql, list_id)

	  count = result.first["count"].to_i
	end

	def count_total_todos(list_id)
	  sql = "SELECT COUNT(id) FROM todo WHERE list_id = $1"
	  result = query(sql, list_id)

	  count = result.first["count"].to_i
	end

	def toggle_todo(todo_id, value)
		sql = "UPDATE todo SET completed = $1 WHERE id = $2"
		query(sql, value, todo_id)
	end

	def add_todo(list_id, text)
	  sql = "INSERT INTO todo(name, list_id) VALUES($1, $2)"
	  query(sql, text, list_id)
	end

	def delete_todo(todo_id)
		sql = "DELETE FROM todo WHERE id = $1"
		query(sql, todo_id)
	end

	def complete_all_todos(list_id)
		sql = "UPDATE todo SET completed = true WHERE list_id = $1"
		query(sql, list_id)
	end

	def update_list_name(list_id, name)
		sql = "UPDATE list SET name = $1 WHERE id = $2"
		query(sql, name, list_id)
	end

	def disconnect
		@db.close
	end
end



