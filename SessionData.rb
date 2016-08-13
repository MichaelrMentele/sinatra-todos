require "pg"

class SessionData
	def initialize(session)
		@session = session
		@session[:lists] ||= []
	end

	def findList(id)
		@session[:lists].find{ |list| list[:id] == id }
	end

	def allLists
		@session[:lists]
	end

	def error(message)
		@session[:error] = message
	end

	def success(message)
		@session[:success] = message
	end

	def delete!(list)
		@session[:lists].delete(list)
	end
end