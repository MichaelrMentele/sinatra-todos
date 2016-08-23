require 'sequel'

DB = Sequel.connect("postgres://michael:password@localhost/todos")

class SequelPersistence
	def initialize(logger)
		DB.logger = logger
	end

	def findList(id)
		allLists.where(lists__id: id).first
		# first actually executes the sequel query
	end

	def allLists
		DB[:lists].left_join(:todos, list_id: :id).
			select_all(:lists).
			select_append do
				# block, using append so the previous select isn't overwritten
				# return array to return multiple columns
				[	count(todos__id).as(todos_count), 
					count(nullif(todos__complete, true)).as(todos_remaining_count) ]
			end.
			group(:lists__id).
			order(:lists__name)
	end

	def createNewList(name)
		DB[:lists].insert(:name => name)
		return true
	end

	def createNewTodo(list_id, name)
		DB[:todos].insert(name: name, list_id: list_id)
	end

	def deleteList!(id)
		DB[:todos].where(list_id: id).delete
		DB[:lists].where(id: id).delete
	end

	def deleteTodo!(id)
		DB[:todos].where(id: id).delete
	end

	def updateListName(id, name)
		DB[:lists].where(id: id).update(name: name)
	end

	def updateTodoStatus(id, status)
		DB[:todos].where(id: id).update(complete: status)
	end

	def markAllTodosComplete(list_id)
		DB[:todos].where(list_id: list_id).update(complete: true)
	end

	def getListTodos(list_id)
		DB[:todos].where(list_id: list_id)
	end

end