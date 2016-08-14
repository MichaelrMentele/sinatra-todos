require "pg"

class DatabasePersistence
	def initialize(logger)
		@db = PG.connect(dbname: "todos")
		@logger = logger
	end

	def findList(id)
		sql = "SELECT * FROM lists WHERE id = $1"
		result = query(sql, id)
		
		tuple = result.first
		list_id = tuple["id"].to_i
		todos = getListTodos(list_id)

		{id: tuple["id"], name: tuple["name"], todos: todos}
	end

	def allLists
		sql = "SELECT * FROM lists"
		result = query(sql)

		result.map do |tuple|
			list_id = tuple["id"].to_i
			
			todos = getListTodos(list_id)

			{id: list_id, name: tuple["name"], todos: todos}
		end
	end

	def delete!(list)
		# @session[:lists].delete(list)
	end

	def getListTodos(list_id)
		todo_sql = "SELECT * FROM todos WHERE list_id = $1"
		todo_result = query(todo_sql, list_id)

		todos = todo_result.map do |todo_tuple|
			{ id: todo_tuple["id"].to_i, 
				name: todo_tuple["name"], 
				completed: todo_tuple["complete"] == "t"}				
		end
	end

	def query(sql, *params)
		@logger.info "#{sql}: #{params}"
		@db.exec_params(sql, params)
	end
end