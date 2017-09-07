class SessionPersistence

	def initialize(session)
		@session = session
		@session[:lists] ||= []	
	end

	def all_lists
		@session[:lists]
	end

	def add_list(list_name)
		id = next_list_id(@session[:lists])
		@session[:lists] << { id: id, name: list_name, todos: [] }
	end

	def delete_list(id)
		@session[:lists].delete_if {|list| list[:id] == id}
	end

	def get_list(id)
		@session[:lists].select{ |list| list[:id] == id}[0]
	end

	def add_todo(list_id, text)
	  list = get_list(list_id)
	  todos = list[:todos]
	  id = next_todo_id(todos)

	  todos << { id: id, name: text, completed: false }
	end

	def complete_all_todos(list_id)
		list = get_list(list_id)
		list[:todos].each{|todo| todo[:completed] = true}
	end

	private

	def next_todo_id(todos)
    	max = todos.map { |todo| todo[:id] }.max || 0
    	max + 1
  	end

  	def next_list_id(lists)
  		max = lists.map { |list| list[:id]}.max || 0
  		max + 1
  	end

end