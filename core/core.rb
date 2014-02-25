module MenuTree
  def self.get_menu_tree(root_sym = :default)
    case root_sym
    when :default; return [:recognization, :resouce, :motivation]
    when :recognization; return [:purpose, :path]
    when :resouce; return [:time, :money, :tool, :human, :infomation]
    when :motivation; return [:positiveness, :concentration, :patience, :leeway]
    end
  end
  def self.get_menu_name(menu_sym, lang=:ja_JP)
    case lang
    when :ja_JP
      case menu_sym
      when :recognization; return "理解"
      when :resouce; return "資源"
      when :motivation; return "気持ち"
      when :purpose; return "目的"
      when :path; return "やり方"
      when :time; return "時間"
      when :money; return "お金"
      when :tool; return "道具"
      when :human; return "人"
      when :infomation; return "情報"
      when :positiveness; return "やる気"
      when :concentration; return "集中"
      when :patience; return "根気"
      when :leeway; return "ゆとり"
      end
    end
  end
  def self.get_menu_sym(menu_name, lang=:ja_JP)
    case lang
    when :ja_JP
      case menu_name
      when "理解"; return :recognization
      when "資源"; return :resouce
      when "気持ち"; return :motivation
      when "目的"; return :purpose
      when "やり方"; return :path
      when "時間"; return :time
      when "お金"; return :money
      when "道具"; return :tool
      when "人"; return :human
      when "情報"; return :infomation
      when "やる気"; return :positiveness
      when "集中"; return :concentration
      when "根気"; return :patience
      when "ゆとり"; return :leeway
      end
    end
  end
  def self.get_menu_names_with_tree(root_sym = :default, lang = :ja_JP)
    get_menu_tree(root_sym).map{|e| get_menu_name(e, lang)}
  end
end

class Question
  attr_reader :description
  def initialize(description: "")
    @description = description
  end
  def to_s
    @description
  end
end

class SelectAnswerQuestion < Question
  attr_reader :menu
  def initialize(description: "選択肢を選んで回答する質問", menu: [])
    super(description: description)
    throw ArgumentError.new("選択肢のデータが不正です。") if menu.length == 0
    @menu = menu
  end
  def to_s
    str = super
    @menu.each_with_index{|m, i| str += "\n#{convert_index_to_input(i)}. #{m}"}
    str
  end
  def convert_index_to_input(index)
    input_str = ""
    if (index < 9 && index >= 0)
      data_set = []
      data_set[0] = "a"
      data_set[1] = "s"
      data_set[2] = "d"
      data_set[3] = "f"
      data_set[4] = "g"
      data_set[5] = "h"
      data_set[6] = "j"
      data_set[7] = "k"
      data_set[8] = "l"
      input_str = data_set[index]
    else
      throw ArgumentError.new("インデックスが不正です。:#{index}")
    end
    input_str
  end
end

class AnswerManager
  def initialize
    @mode_menu_pair = []
  end
  def add(mode, selected_menu)
    @mode_menu_pair << [mode, selected_menu]
  end
  def first_selected_menu
    @mode_menu_pair[0][1]
  end
  def last_mode
    @mode_menu_pair[@mode_menu_pair.length - 1][0]
  end
  def last_selected_menu
    @mode_menu_pair[@mode_menu_pair.length - 1][1]
  end
  def count
    @mode_menu_pair.length
  end
  def select_with_mode(mode)
    @mode_menu_pair.select{|pair| pair[0] == mode}.map{|pair| pair[1]}
  end
end

class ThinkCompassCore
  attr_reader :answers, :question, :result
  def initialize
    init
  end
  def init
    @received_answers = {}
    @answers = AnswerManager.new
    @current_language = :ja_JP
    @question = go_next_question
    @on_result = false
    @result = nil
  end
  def receive_answer(data)
    if (data != nil)
      selected_index = nil
      if (@question.is_a?(SelectAnswerQuestion))
        selected_index = convert_input_to_index(data)
        @answers.add(@current_question_mode, MenuTree.get_menu_sym(@menu[selected_index], @current_language))
      end
    end
  end
  def go_next_question
    if to_go_result?
      @on_result = true
      @result = build_result
    end
    case @current_question_mode
    when nil, :more
      @current_question_mode = :less
      if @current_tree_root == nil
        @current_tree_root = :default
        @current_tree = MenuTree.get_menu_tree(@current_tree_root)
      else
        @current_tree_root = @answers.select_with_mode(:less)[-1]
        @current_tree = MenuTree.get_menu_tree(@current_tree_root)
      end

      if @current_tree != nil
        @menu = MenuTree.get_menu_names_with_tree(@current_tree_root, @current_language)
        @question = SelectAnswerQuestion.new(description: "一番不足しているのはどれですか？", menu: @menu)
      else
        @question = nil
      end
    when :less
      @current_question_mode = :more
      if @answers.count == 1
        selected_index = MenuTree.get_menu_tree(@current_tree_root).index(@answers.last_selected_menu)
        @menu.slice!(selected_index)
        @question = SelectAnswerQuestion.new(description: "一番余裕があるのはどれですか？", menu: @menu)
      else
        @current_tree_root = @answers.select_with_mode(:more)[-1]
        @current_tree = MenuTree.get_menu_tree(@current_tree_root)
        if @current_tree != nil
          @menu = MenuTree.get_menu_names_with_tree(@current_tree_root, @current_language)
          @question = SelectAnswerQuestion.new(description: "一番余裕があるのはどれですか？", menu: @menu)
        else
          @question = nil
        end
      end
    end
    @question
  end
  def to_go_result?
    @answers.count >= 2
  end
  def go_result
    @on_result = true
    @question = nil
    set_next_question(nil, nil, nil)
  end
  def on_result?
    @on_result
  end
  def continue_question
    @on_result = false
    @current_question_mode = @answers.last_mode == :more ? :less : :more
  end

  private 

  def set_next_question(current_question_mode, menu, next_question)
    @current_question_mode = current_question_mode
    @menu = menu
    @next_question = next_question
  end
  def set_second_enough_question
    next_id = nil
    latest_answer_sym = MenuTree.get_menu_sym(@received_answers[:enough_element], @current_language)
    case latest_answer_sym
    when :resouce
      next_id = :enough_element_資源
    when :motivation
      next_id = :enough_element_気持ち
    when :recognization
      next_id = :enough_element_理解
    end
    menu = MenuTree.get_menu_names_with_tree(latest_answer_sym, :ja_JP)
    set_next_question(next_id, menu, SelectAnswerQuestion.new(description: "一番余裕があるのはどれですか？", menu: menu))
  end
  def nested_key_each(hash, &block)
    hash.each_key{|key|
      block.call(key)
      nested_key_each(hash[key], &block) if hash[key].length != 0
    }
  end
  def convert_input_to_index(data)
    selected_index = 0
    if (data.length == 1)
      data_set = []
      data_set[0] = ["1", "a"]
      data_set[1] = ["2", "s"]
      data_set[2] = ["3", "d"]
      data_set[3] = ["4", "f"]
      data_set[4] = ["5", "g"]
      data_set[5] = ["6", "h"]
      data_set[6] = ["7", "j"]
      data_set[7] = ["8", "k"]
      data_set[8] = ["9", "l"]
      selected_index = data_set.index{|d| d.include?(data)}
    else
      throw ArgumentError.new("回答データが不正です。:#{data}") if selected_index < 0 || selected_index >= @menu.length
    end
    selected_index
  end
  def build_result
    return nil if @answers.count < 2
    return {less: @answers.select_with_mode(:less), more: @answers.select_with_mode(:more)}
  end
end
