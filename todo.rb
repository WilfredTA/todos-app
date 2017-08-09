require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/reloader' if development?
require 'tilt/erubis'


configure do
	enable :sessions
	set :session_secret, 'secret'
	set :erb, :escape_html => true
end

helpers do
	def list_complete?(list)
		todos_remaining_count(list) == 0 &&
		todos_count(list) > 0
	end

	def list_class(list)
		"complete" if list_complete?(list)
	end

	def todos_count(list)
		list[:todos].size
	end

	def todos_remaining_count(list)
		list[:todos].select {|todo| !todo[:completed]}.size
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
	session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

# View all lists
get '/lists' do
	@lists = session[:lists]
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
	elsif session[:lists].any? { |list| list[:name] == name }
		'List name must be unique.'
	end
end

# Returns an error message if todo is invalid, nil otherwise
def error_for_todo(name)
  if !(1..100).cover? name.size
		'Todo item must be between 1 and 100 characters'
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
		session[:lists] << { name: list_name, todos: [] }
		session[:success] = 'The list has been created!'
		redirect '/lists'
	end
end

get '/lists/:id' do
	@list_id = params[:id].to_i
	@list = session[:lists][@list_id]
	@completed = params[:completed]
	erb :individual_list, layout: :layout
end

# Edit the name existing to do list
get '/lists/:id/edit' do
	@id = params[:id].to_i
	@list = session[:lists][@id]
	erb :edit_list, layout: :layout
end

# Updates an existing todo list
post '/lists/:id' do
	list_name = params[:list_name].strip
	@id = params[:id].to_i
	@list = session[:lists][@id]

	error = error_for_list_name(list_name)
	if error
		session[:error] = error
		erb :edit_list, layout: :layout
  else
		@list[:name] = list_name
		session[:success] = 'The list has been updated!'
		redirect "/lists/#{@id}"
	end
end

# Deletes a todo list
post '/lists/:id/delete' do
	id = params[:id].to_i
	session[:lists].delete_at(id)
	session[:success] = "The list has been deleted."
	redirect "/lists"
end

# Add a new todo item to a list
post '/lists/:list_id/todos' do
	@list_id = params[:list_id].to_i
	@list = session[:lists][@list_id]
	text = params[:todo].strip

	error = error_for_todo(text)
	if error
		session[:error] = error
		erb :individual_list, layout: :layout
	else
		@list[:todos] << { name: text, completed: false }
		session[:success] = "The todo was added!"
		redirect "/lists/#{@list_id}"
	end
end

# Deletes a todo item
post '/lists/:list_id/todos/:todo_id/delete' do
	@list_id = params[:list_id].to_i
	@todo_id = params[:todo_id].to_i
	session[:lists][@list_id][:todos].delete_at(@todo_id)
	session[:success] = "The todo item has been deleted!"
	redirect "/lists/#{@list_id}"
end

# Toggles completion of todo item
post '/lists/:list_id/todos/:todo_id' do
	list_id = params[:list_id].to_i
	completed = params[:completed] == "true"
	list = session[:lists][list_id]
	todo_id = params[:todo_id].to_i
	list[:todos][todo_id][:completed] = completed
	session[:success] = "The todo item has been updated"
	redirect "/lists/#{list_id}"
end

# Toggles all todo items at once
post '/lists/:id/complete_all' do
	id = params[:id].to_i
	list = session[:lists][id]

	list[:todos].each{ |todo| todo[:completed] = true }

	session[:success] = "All todo items have been completed!"
	redirect "/lists/#{id}"
end


