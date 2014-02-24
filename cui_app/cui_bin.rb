
# ThinkCompass CUI App
require_relative "../core/core.rb"

core = ThinkCompassCore.new()

def build_result(core)
  result = ""
  # enough_element_1st_set = [:enough_element_資源, :enough_element_気持ち, :enough_element_理解]
  # enough_element_1st = core.received_answers.keys & enough_element_1st_set
  # if (enough_element_1st.length == 1)
  #   less_element_1st_set = [:less_element_資源, :less_element_気持ち, :less_element_理解]
  #   less_element_1st = (core.received_answers.keys & less_element_1st_set)
  #   enough_element_1st = enough_element_1st[0] if enough_element_1st.length == 1
  #   less_element_1st = less_element_1st[0] if less_element_1st.length == 1
  #   if (core.received_answers.key?(enough_element_1st) && core.received_answers.key?(less_element_1st))
  #     result += "#{core.received_answers[enough_element_1st]} を使って #{core.received_answers[less_element_1st]} を補ってみてはどうでしょうか？\n"
  #     result += "もっと続けますか？ [y,a/n,s] > "
  #   end

  enough_element_1st_set = [:enough_element_資源, :enough_element_気持ち, :enough_element_理解]
  enough_element_1st = (core.received_answers.keys & enough_element_1st_set)
  enough_element_1st = enough_element_1st[0] if enough_element_1st != nil && enough_element_1st.length == 1
  less_element_1st_set = [:less_element_資源, :less_element_気持ち, :less_element_理解]
  less_element_1st = (core.received_answers.keys & less_element_1st_set)
  less_element_1st = less_element_1st[0] if less_element_1st != nil && less_element_1st.length == 1
  if (enough_element_1st.empty? == false)
    result += "#{core.received_answers[:enough_element]} 特に #{core.received_answers[enough_element_1st]} を使って #{core.received_answers[less_element_1st]} を補ってみてはどうでしょうか？\n"
    result += "もっと続けますか？ [y,a/n,s] > "
  elsif (less_element_1st.empty? == false)
    result += "#{core.received_answers[:enough_element]} を使って #{core.received_answers[less_element_1st]} を補ってみてはどうでしょうか？\n"
    result += "もっと続けますか？ [y,a/n,s] > "
  elsif (core.received_answers.key?(:enough_element) && core.received_answers.key?(:less_element))
    result += "#{core.received_answers[:enough_element]} を使って #{core.received_answers[:less_element]} を補ってみてはどうでしょうか？\n"
    result += "もっと続けますか？ [y,a/n,s] > "
  end

  result = ""
  more_base_name = MenuTree.get_menu_name(core.result[:more][0])
  less_base_name = MenuTree.get_menu_name(core.result[:less][0])
  more_name = MenuTree.get_menu_name(core.result[:more][-1])
  less_name = MenuTree.get_menu_name(core.result[:less][-1])
  if (more_base_name == more_name)
    result += "#{more_base_name}"
  else
    result += "#{more_base_name} 特に #{more_name}"
  end
  result += " を使って、"
  if (less_base_name == less_name)
    result += "#{less_base_name}"
  else
    result += "#{less_base_name} 特に #{less_name}"
  end
  result += " を補ってみてはどうでしょうか？\n"
  result += "もっと続けますか？ [y,a/n,s] > "

  result
end

def start_question(core)
  until (core.on_result?)
    # p core
    throw :finish_question if core.question == nil
    puts core.question.to_s
    puts ""
    print "> "
    input_answer = gets().chomp()
    puts ""
    core.receive_answer(input_answer)
    question = core.go_next_question()
  end

  print build_result(core)
  input_answer = gets().chomp()
  if (input_answer != "y" && input_answer != "a")
    throw :finish_question
  end
  core.continue_question()
  puts ""
end

puts "\n** Think Compass **\n\n"

catch :finish_question do
  loop do
    start_question(core)
  end
end
