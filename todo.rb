require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

get "/" do
  erb "You have no lists.", layout: :layout
end
