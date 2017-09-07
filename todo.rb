require 'sinatra'
require 'sinatra/content_for'

require 'tilt/erubis'
require_relative "database_persistence"


configure do
	enable :sessions
	set :session_secret, 'secret'
	set :erb, :escape_html => true
end

configure(:development) do
	require 'sinatra/reloader'
	also_reload "database_persistence.rb"

end

helpers do
	def list_complete?(list)
		#todos_remaining_count(list) == 0 && todos_count(list) > 0
		list[:todos_remaining_count] == 0 && list[:todos_count] > 0
	end

	def list_class(list)
		"complete" if list_complete?(list)
	end

	def todos_count(list)
		list[:todos].size
	end

	def todos_remaining_count(list)
		list[:todos].count {|todo| !todo[:complete]}
	end

	def sort_lists(lists, &block)
		incomplete_lists = {}
		complete_lists = {}

		complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list)}
		

		incomplete_lists.each { |list| yield(list, lists.index(list))}
		complete_lists.each { |list| yield(list, lists.index(list))}
	end

	def sort_todos(todos, &block)
		complete_todos = {}
		incomplete_todos = {}

		todos.each_with_index do |todo, index|
			if todo[:completed]
				complete_todos[todo] = index
			else
				incomplete_todos[todo] = index
			end
		end

		incomplete_todos.each(&block)
		complete_todos.each(&block)
	end
end

before do
	@storage = DatabasePersistence.new(logger)
end


get '/' do
  redirect '/lists'
end

# View all lists
get '/lists' do
  @lists = @storage.all_lists
  erb :list, layout: :layout
end

# Render the new list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

# Returns an error message if the name is invalid. Returns nil otherwise.
def error_for_list_name(name)
  if !(1..100).cover? name.size
		'List name must be between 1 and 100 characters'
	elsif @storage.all_lists.any? { |list| list[:name] == name }
		'List name must be unique.'
	end
end

# Returns an error message if todo is invalid, nil otherwise
def error_for_todo(name)
  if !(1..100).cover? name.size
		'Todo item must be between 1 and 100 characters'
	end
end

def load_list(id)
	list = @storage.get_list(id)
	return list if list

	session[:error] = "The specified list was not found"
	redirect "/lists"
	halt
end

# Create a new list
post '/lists' do
	list_name = params[:list_name].strip

	error = error_for_list_name(list_name)
	if error
		session[:error] = error
		erb :new_list, layout: :layout
  else
		@storage.add_list(list_name)
		session[:success] = 'The list has been created!'
		redirect '/lists'
	end
end

# View a single todo list
get '/lists/:id' do
	@list_id = params[:id].to_i
	@list = load_list(@list_id)
	erb :individual_list, layout: :layout
end

# Edit the name existing to do list
get '/lists/:id/edit' do
	@id = params[:id].to_i
	@list = @storage.get_list(@id)
	erb :edit_list, layout: :layout
end

# Updates an existing todo list
post '/lists/:id' do
	list_name = params[:list_name].strip
	@id = params[:id].to_i
	@list = @storage.get_list(@id)

	error = error_for_list_name(list_name)
	if error
		session[:error] = error
		erb :edit_list, layout: :layout
    else
		@storage.update_list_name(@id, list_name)
		session[:success] = 'The list has been updated!'
		redirect "/lists/#{@id}"
	end
end

# Deletes a todo list
post '/lists/:id/delete' do
	id = params[:id].to_i
	@storage.delete_list(id)
	session[:success] = "The list has been deleted."
	redirect "/lists"
end

# Add a new todo item to a list
post '/lists/:list_id/todos' do
	@list_id = params[:list_id].to_i
	@list = @storage.get_list(@list_id)
	text = params[:todo].strip

	error = error_for_todo(text)
	if error
		session[:error] = error
		erb :individual_list, layout: :layout
	else
		@storage.add_todo(@list_id, text)
		session[:success] = "The todo was added!"
		redirect "/lists/#{@list_id}"
	end
end

# Deletes a todo item
post '/lists/:list_id/todos/:todo_id/delete' do
	@list_id = params[:list_id].to_i
	@todo_id = params[:todo_id].to_i
	@storage.delete_todo(@todo_id)
	session[:success] = "The todo item has been deleted!"
	redirect "/lists/#{@list_id}"
end

# Toggles completion of todo item
post '/lists/:list_id/todos/:todo_id' do
	list_id = params[:list_id].to_i
	completed = params[:completed] == "true"
	list = @storage.get_list(list_id)
	todo_id = params[:todo_id].to_i

	@storage.toggle_todo(todo_id, completed)
	session[:success] = "The todo item has been updated"
	redirect "/lists/#{list_id}"
end

# Toggles all todo items at once
post '/lists/:id/complete_all' do
	list_id = params[:id].to_i

	@storage.complete_all_todos(list_id)

	session[:success] = "All todo items have been completed!"
	redirect "/lists/#{list_id}"
end

after do
	@storage.disconnect
end


