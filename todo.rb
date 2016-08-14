require "sinatra"

require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

require_relative "data_persistence.rb"

configure do
  enable :sessions
  set :erb, :escape_html => true
  set :session_secret, "secret"
end

before do 
  @storage = DatabasePersistence.new(logger)
end

not_found do 
  session[:error] = "URL not found"
  redirect "/lists"
end

###########
# Methods #
###########

def load_list(id)
  list = @storage.findList(id)
  return list if list 

  session[:error] = ("The specified list was not found.")
  redirect "/lists"
  halt
end

def error_for_list_name(list_name)
  if @storage.allLists.any? {|list| list[:name] == list_name}
    "Each list name must be unique."
  elsif !(1..100).cover? list_name.size
    "List name must be between 1 and 100 characters."
  end
end

def error_for_todo_name(todo_name)
  if !(1..100).cover? todo_name.size
    "Todo name must be between 1 and 100 characters."
  end
end

def next_todo_id(todos)
  max = todos.map { |todo| todo[:id] }.max || 0
  max + 1
end

def next_list_id(lists)
  max = lists.map { |list| list[:id]}.max || 0
  max + 1
end


########
# Gets #
########

get "/" do
  redirect "/lists"
end

# View list of lists
get "/lists" do
  @lists = @storage.allLists
  erb :lists, layout: :layout
end

# Render new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# View a single list
get "/lists/:id" do 
  list_id = params[:id].to_i
  @list = load_list(list_id)
  erb :list, layout: :layout
end

# Edit existing todo list...
get "/lists/:id/edit" do
  list_id = params[:id].to_i
  @list = load_list(list_id)
  erb :edit, layout: :layout
end

# Add todos to a list
get "/lists/:id/todos" do 
  erb :todos, layout: :layout
end

#########
# Posts #
#########

# Edit the name of a list
post "/lists/:id" do 
  list_id = params[:id].to_i
  @list = load_list(list_id)
  @list[:name] = params[:list_name].strip

  redirect "/lists/#{params[:id]}"
end 

# Delete a list
post "/lists/:list_id/destroy" do 
  list_id = params[:list_id].to_i
  @list = load_list(list_id)

  @storage.delete!(@list)
  session[:success] = ("The list has been deleted.")
  
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    redirect "/lists"
  end
end

# Create a new list
post '/lists' do 
  list_name = params[:list_name].strip
  
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    @lists = @storage.allLists
    id = next_list_id(@lists)
    @lists << {id: id, name: list_name, todos: []}
    session[:success] = ('The list has been created.')

    redirect "/lists"
  end
end

# Create todos on a list
post "/lists/:list_id/todos" do 
  # Get current list
  list_id = params[:list_id].to_i
  @list = load_list(list_id)
  todo_name = params[:todo].strip

  # Validate todo
  error = error_for_todo_name(todo_name)
  if error
    session[:error] = (error)
    erb :list, layout: :layout
  else
    id = next_todo_id(@list[:todos])
    @list[:todos] << {id: id, name: todo_name, complete: false}
    
    session[:success] = ('The todo has been created.')
    redirect "/lists/#{list_id}"  
  end
end

# Delete a todo on a list
post "/lists/:list_id/todos/:todo_id" do 
  list_id = params[:list_id].to_i
  @list = load_list(list_id)

  todo_id = params[:todo_id].to_i
  @list[:todos].reject! { |todo| todo[:id] == todo_id }

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = ("The todo has been deleted.")
    redirect "/lists/#{list_id}"
  end
end

# Update status of a todo
post "/lists/:list_id/todos/:todo_id/update" do 
  list_id = params[:list_id].to_i
  @list = load_list(list_id)

  todo_id = params[:todo_id].to_i
  todo = @list[:todos].find { |todo| todo[:id] == todo_id }

  is_completed = params[:completed] == "true"
  todo[:complete] = is_completed

  session[:success] = ("The todo has been updated")
  
  redirect "/lists/#{list_id}"
end

# Update the states of all todos to all
post "/lists/:list_id/complete_all" do
  list_id = params[:id].to_i
  @list = load_list(list_id)

  list[:todos].each do |todo|
    todo[:complete] = true
  end
  redirect "/lists/#{params[:list_id]}"
end

###########
# Helpers #
###########

helpers do
  def todos?(list)
    list[:todos].size >= 1
  end

  def todos_complete?(list)
    list[:todos].each do |todo|
      unless todo[:complete] == true
        return false
      end
    end
    true
  end

  def list_complete?(list)
    todos?(list) and todos_complete?(list)
  end

  def list_class(list)
    if list[:todos].size == 0
      "new"
    elsif list_complete?(list)
      "complete"
    else
      ""
    end
  end

  def incomplete_todos(list)
    count = 0
    list[:todos].each do |todo|
      count += 1 if todo[:complete] != true
    end
    count
  end

  def todos_count(list)
    list[:todos].size
  end

  def todo_class(todo)
    "complete" if todo_complete?(todo)
  end

  def todo_complete?(todo)
    todo[:complete] == true
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }
    
    incomplete_lists.each(&block)
    complete_lists.each(&block)
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo_complete?(todo)}
    
    incomplete_todos.each(&block)
    complete_todos.each(&block)
  end
end