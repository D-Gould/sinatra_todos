require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

get '/lists' do
  @lists = session[:lists]
  erb :lists
end

get '/lists/new' do
  erb :new_list
end

# Returns error message if the list name causes an error. Else returns nil.
def error_message_finder(name)
  if !(1..100).cover? name.size
    'The list name must be between 1 and 200 characters.'
  elsif session[:lists].any? { |list| list[:name] == name }
    'The list name must be unique.'
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
