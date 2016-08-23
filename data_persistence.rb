require "pg"

class DatabasePersistence
	def initialize(logger)
		@db = PG.connect(dbname: "todos")
		@logger = logger
	end

	def findList(id)
		sql = <<-SQL 
			SELECT lists.*,
				COUNT(todos.id) AS todos_count,
				COUNT(NULLIF(todos.complete, true)) AS todos_remaining_count
				FROM lists
				LEFT OUTER JOIN todos ON todos.list_id = lists.id 
				WHERE lists.id = $1
				GROUP BY lists.id
				ORDER BY lists.id;
		SQL
		result = query(sql, id)
		tuple_to_list_hash(result.first)
	end

	def allLists
		sql = <<-SQL 
			SELECT lists.*,
				COUNT(todos.id) AS todos_count,
				COUNT(NULLIF(todos.complete, true)) AS todos_remaining_count
				FROM lists
				LEFT OUTER JOIN todos ON todos.list_id = lists.id 
				GROUP BY lists.id
				ORDER BY lists.id;
		SQL

		result = query(sql)

		result.map do |tuple|
			tuple_to_list_hash(tuple)
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

	def getListTodos(list_id)
		todo_sql = "SELECT * FROM todos WHERE list_id = $1"
		todo_result = query(todo_sql, list_id)

		todos = todo_result.map do |todo_tuple|
			{ id: todo_tuple["id"].to_i, 
				name: todo_tuple["name"], 
				completed: todo_tuple["complete"] == "t"}				
		end
	end

	private

	def tuple_to_list_hash(tuple)
		{ id: tuple["id"], 
			name: tuple["name"], 
			todos_count: tuple["todos_count"].to_i,
			todos_remaining_count: tuple["todos_remaining_count"].to_i
		}
	end

	def query(sql, *params)
		@logger.info "#{sql}: #{params}"
		@db.exec_params(sql, params)
	end
end