
# ThinkCompass Web App
require_relative "../core/core.rb"
require "sinatra"
require "sinatra/reloader"

set :environment, :production
# set :port, 80

configure do
  enable :sessions
end

def receive_value_to_index(receive_value)
  raw_index = session[:value_index_map].index(receive_value.to_sym)
  session[:value_index_map].delete_at(raw_index)
  (raw_index + 1).to_s.tap{|v| p v}
end

def receive_answer(ans)
  p ans
  session[:core].receive_answer(receive_value_to_index(ans))
end

def go_next
  session[:core].go_next_question
end

def on_result?
  session[:core].on_result?
end

def build_result
  result = "りざると\n"
  if (session[:core].received_answers.key?(:enough_element) && session[:core].received_answers.key?(:less_element))
    result += "#{session[:core].received_answers[:enough_element]} を使って #{session[:core].received_answers[:less_element]} を補ってみてはどうでしょうか？\n"
  end
  result
end

def session_init
  session[:core] = ThinkCompassCore.new()
  session[:value_index_map] = [:recognization, :resouce, :motivation]
end

before do
end

get '/' do
  session_init
  erb :top, :locals => {question_mode: :less, present_answer: params[:enough]}
end

get '/less' do
  erb :top, :locals => {question_mode: :less, present_answer: params[:enough]}
end

get '/enough' do
  receive_answer(params[:less])
  go_next
  erb :top, :locals => {question_mode: :enough, present_answer: params[:less]}
end

get '/result' do
  receive_answer(params[:enough])
  go_next

  erb :top, :locals => {
    question_mode: :result, 
    present_answer: params[:enough], 
    built_result: build_result,
    params: params}
end

after do
  cache_control :no_cache
end

# def build_result(core)
#   result = ""
#   enough_element_1st_set = [:enough_element_資源, :enough_element_気持ち, :enough_element_理解]
#   enough_element_1st = (core.received_answers.keys & enough_element_1st_set)
#   enough_element_1st = enough_element_1st[0] if enough_element_1st != nil && enough_element_1st.length == 1
#   less_element_1st_set = [:less_element_資源, :less_element_気持ち, :less_element_理解]
#   less_element_1st = (core.received_answers.keys & less_element_1st_set)
#   less_element_1st = less_element_1st[0] if less_element_1st != nil && less_element_1st.length == 1
#   if (enough_element_1st.empty? == false)
#     result += "#{core.received_answers[:enough_element]} 特に #{core.received_answers[enough_element_1st]} を使って #{core.received_answers[less_element_1st]} を補ってみてはどうでしょうか？\n"
#     result += "もっと続けますか？ [y,a/n,s] > "
#   elsif (less_element_1st.empty? == false)
#     result += "#{core.received_answers[:enough_element]} を使って #{core.received_answers[less_element_1st]} を補ってみてはどうでしょうか？\n"
#     result += "もっと続けますか？ [y,a/n,s] > "
#   elsif (core.received_answers.key?(:enough_element) && core.received_answers.key?(:less_element))
#     result += "#{core.received_answers[:enough_element]} を使って #{core.received_answers[:less_element]} を補ってみてはどうでしょうか？\n"
#     result += "もっと続けますか？ [y,a/n,s] > "
#   end
#   result
# end

# def start_question(core)
#   until (core.on_result?)
#     # p core
#     puts core.question.to_s()
#     puts ""
#     print "> "
#     input_answer = gets().chomp()
#     puts ""
#     core.receive_answer(input_answer)
#     question = core.go_next_question()
#   end

#   print build_result(core)
#   input_answer = gets().chomp()
#   if (input_answer != "y" && input_answer != "a")
#     throw :finish_question
#   end
#   core.continue_question()
#   puts ""
# end

# puts "\n** Think Compass **\n\n"

# catch :finish_question do
#   loop do
#     start_question(core)
#   end
# end
