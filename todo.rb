require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

#methods to be used in the views
helpers do
  def list_complete?(list)
    list[:todos].all? {|todo| todo[:completed]} && list[:todos].size > 0
  end

  def todos_count(list)
    list[:todos].count
  end

  def remaining_todos(list)
    list[:todos].count {|todo| todo[:completed] == false}
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def sort_list(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }

    incomplete_lists.each { |list| yield(list, lists.index(list)) }
    complete_lists.each { |list| yield(list, lists.index(list)) }
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each { |todo| yield(todo, todos.index(todo)) }
    complete_todos.each { |todo| yield(todo, todos.index(todo)) }
  end
end

get '/' do
  redirect '/lists'
end

get '/lists' do
  @lists = session[:lists]
  erb :lists
end

get '/lists/new' do
  @lists = session[:lists]
  erb :new_list
end

get '/lists/:id' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  erb :list
end

get '/lists/:id/edit' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  erb :edit_list
end

# Returns error message if the list name causes an error. Else returns nil.
def error_message_finder(name)
  if !(1..100).cover? name.size
    'The list name must be between 1 and 200 characters.'
  elsif session[:lists].any? { |list| list[:name] == name }
    'The list name must be unique.'
  end
end

# Returns error message if the todo name causes an error. Else returns nil.
def error_message_finder(name)
  if !(1..100).cover? name.size
    'Todo name must be between 1 and 200 characters.'
  end
end

post '/lists' do
  list_name = params[:list_name].strip
  error = error_message_finder(list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# Update an existing todo list
post '/lists/:id' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  list_name = params[:list_name].strip
  error = error_message_finder(list_name)
  if error
    session[:error] = error
    erb :edit_list
  else
    @list[:name] = list_name
    session[:success] = 'The list has been updated.'
    redirect "/lists/#{@list_id}"
  end
end

# Delete a list
post '/lists/:id/delete' do
  @list_id = params[:id].to_i
  session[:lists].delete_at(@list_id)
  session[:success] = 'List successfully deleted.'
  redirect '/lists'
end

# Add a new todo to a list
post '/lists/:id/todos' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  text = params[:todo].strip

  error = error_message_finder(text)
  if error
    session[:error] = error
    erb :list
  else
    @list[:todos] << {name: text, completed: false}
      session[:success] = 'The todo has been added.'
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo from a list
post '/lists/:id/todos/:todo_id/delete' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  @todo_id = params[:todo_id].to_i
  @list[:todos].delete_at(@todo_id)
  session[:success] = 'Todo successfully deleted.'
  redirect "/lists/#{@list_id}"
end

# Mark todo complete
post '/lists/:id/todos/:todo_id' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  @todo_id = params[:todo_id].to_i

  is_completed = params[:completed] == "true"
  @list[:todos][@todo_id][:completed] = is_completed

  session[:success] = 'Todo has been updated.'
  redirect "/lists/#{@list_id}"
end

post '/lists/:id/complete_all' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  @list[:todos].each { |todo| todo[:completed] = true }
  session[:success] = "All todos have been completed."
  redirect "/lists/#{@list_id}"
end
