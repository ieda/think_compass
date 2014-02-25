
# ThinkCompass Web App
require_relative "../core/core.rb"
require "sinatra"
require "sinatra/reloader"

set :environment, :production
# set :port, 80

configure do
  enable :sessions
end

def update_menu_sym_pair
  @menu_sym_name_pair = session[:core].question.menu.map{|m| [MenuTree.get_menu_sym(m), m]}
end

def delete_selected_menu(receive_value)
  @menu_sym_name_pair.delete_if{|sym, name| sym == receive_value.to_sym}
end

def receive_value_to_index(receive_value)
  raw_index = @menu_sym_name_pair.index{|sym, name| sym == receive_value.to_sym}
  (raw_index + 1).to_s
end

def receive_answer(ans)
  return if ans == nil
  session[:core].receive_answer(receive_value_to_index(ans))
end

def go_next
  session[:core].go_next_question
end

def continue_question
  session[:core].continue_question
end

def on_result?
  session[:core].on_result?
end

def build_result
  result = ""
  core = session[:core]
  p core
  result_more = core.result[:more]
  more_base_name = MenuTree.get_menu_name(session[:core].result[:more][0])
  less_base_name = MenuTree.get_menu_name(session[:core].result[:less][0])
  more_name = MenuTree.get_menu_name(session[:core].result[:more][-1])
  less_name = MenuTree.get_menu_name(session[:core].result[:less][-1])
  if (more_base_name == more_name)
    result += "#{more_base_name}"
  else
    result += "#{more_base_name}（#{more_name}）"
  end
  result += "を使って、"
  if (less_base_name == less_name)
    result += "#{less_base_name}"
  else
    result += "#{less_base_name}（#{less_name}）"
  end
  result += "を補ってみてはどうですか？\n"

  # if (session[:core].received_answers.key?(:enough_element) && session[:core].received_answers.key?(:less_element))
  #   result += "#{session[:core].received_answers[:enough_element]} を使って #{session[:core].received_answers[:less_element]} を補ってみてはどうでしょうか？\n"
  # end
  result
end

def session_init
  session.clear
  session[:core] = ThinkCompassCore.new()
end

before do
end

get '/' do
  session_init
  update_menu_sym_pair
  erb :top, :locals => {question_mode: :less, present_answer: params[:more]}
end

get '/less' do
  update_menu_sym_pair if session[:core] != nil
  receive_answer(params[:more]) if params[:more] != nil
  go_next if session[:core].to_go_result? == false
  update_menu_sym_pair
  erb :top, :locals => {question_mode: :less, present_answer: params[:more]}
end

get '/more' do
  update_menu_sym_pair if session[:core] != nil
  receive_answer(params[:less]) if params[:less] != nil
  go_next #if session[:core].to_go_result? == false
  update_menu_sym_pair
  if session[:core].answers.count < 2
    delete_selected_menu(params[:less]) if params[:less] != nil
  end
  erb :top, :locals => {question_mode: :more, present_answer: params[:less]}
end

get '/result' do
  update_menu_sym_pair if session[:core] != nil
  receive_answer(params[:more]) if params[:more] != nil
  go_next
  continue_question
  erb :top, :locals => {
    question_mode: :result, 
    present_answer: params[:more], 
    built_result: build_result,
    params: params,
    core: session[:core]}
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
