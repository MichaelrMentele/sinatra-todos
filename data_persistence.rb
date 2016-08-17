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

	def createNewList(name)
		sql = "INSERT INTO lists (name) VALUES ($1);"
		result = query(sql, name)
		return true
	end

	def createNewTodo(list_id, name)
		sql = "INSERT INTO todos (name, list_id) VALUES ($1, $2)"
		query(sql, name, list_id)
	end

	def deleteList!(id)
		query("DELETE FROM todos WHERE list_id = $1", id)
		query("DELETE FROM lists WHERE id = $1", id)
	end

	def deleteTodo!(id)
		query("DELETE FROM todos WHERE id = $1", id)
	end

	def updateListName(id, name)
		sql = "UPDATE lists SET name = $1 WHERE id = $2"
 		query(sql, name, id)
	end

	def updateTodoStatus(id, status)
		sql = "UPDATE todos SET complete = $2 WHERE id = $1"
		query(sql, id, status)
	end

	def markAllTodosComplete(list_id)
		sql = "UPDATE todos SET complete = true WHERE list_id = $1"
		query(sql, list_id)
	end

	private

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