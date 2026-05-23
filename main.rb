# main.rb
# 超シンプルSQLパーサー体験デモ・CLIスクリプト
#
# このスクリプトは、lexer.rb と parser.rb を使用して、
# SQL文字列がどのように「トークン」に分解され、「構文木(AST)」に組み立てられるのかを視覚的に体験できるツールです。

require_relative 'lexer'
require_relative 'parser'
require 'json' # 構文木（Hash）をきれいにインデントして表示するため

# ターミナル画面を綺麗にする関数
def clear_screen
  if Gem.win_platform?
    system("cls")
  else
    system("clear")
  end
end

# SQLの解析を実行し、そのプロセスと結果を表示するメイン処理
def execute_parsing(sql)
  puts "\n" + "━" * 65
  puts "  🔍 解析対象のSQL:"
  puts "     \"#{sql}\""
  puts "━" * 65

  # ----- STEP 1: 字句解析 (Lexing) -----
  puts "\n 【STEP 1: 字句解析 (Lexer) の処理】"
  puts " 文字列を走査し、「意味のある最小の単語（トークン）」に分解します。"
  
  begin
    lexer = SimpleSqlLexer.new(sql)
    tokens = lexer.tokenize
  rescue => e
    puts "\n ❌ [字句解析エラー] 文字の分解中にエラーが発生しました："
    puts "    #{e.message}"
    puts "━" * 65
    return
  end

  puts "\n  生成されたトークン一覧:"
  tokens.each_with_index do |token, index|
    # 見やすく揃えて出力
    type_str = ":#{token[:type]}"
    printf("    [%02d]  種類: %-12s 値: %s\n", index + 1, type_str, token[:value].inspect)
  end

  # ----- STEP 2: 構文解析 (Parsing) -----
  puts "\n 【STEP 2: 構文解析 (Parser) の処理】"
  puts " トークンの並びを検証し、意味のある構造（構文木: AST）に組み立てます。"

  begin
    parser = SimpleSqlParser.new(tokens)
    ast = parser.parse
  rescue => e
    puts "\n ❌ [構文解析エラー] 文法の検証中にエラーが発生しました："
    puts "    #{e.message}"
    puts "━" * 65
    return
  end

  puts "\n  組み立てられた抽象構文木 (AST):"
  # JSONを使ってRubyのHashオブジェクトを綺麗にインデント表示
  puts JSON.pretty_generate(ast)
  puts "━" * 65
  puts "  🎉 解析に成功しました！ 構文木は有効です。"
  puts "━" * 65
end

# サンプルSQLのリスト
SAMPLES = [
  "SELECT name FROM users",
  "SELECT id, name, email FROM members WHERE role = 'admin'",
  "SELECT * FROM products WHERE price = 100",
  "SELECT FROM tables", # エラーになるサンプル (SELECTの直後にカラム名がない)
  "SELECT name FROM users WHERE status =", # エラーになるサンプル (WHERE値が足りない)
  "SELECT name FROM users EXTRA_TOKEN" # エラーになるサンプル (余計な単語がある)
].freeze

# メインループ
def start_demo
  clear_screen
  puts "================================================================="
  puts "    💎 Rubyで作る超シンプルなSQLパーサー デモプログラム 💎"
  puts "================================================================="
  puts " 言語処理系（パーサー）が「字句解析」と「構文解析」を経て、"
  puts " コードを構造化する仕組みを目で見て確認できます。"
  puts "================================================================="

  loop do
    puts "\n【メニュー】実行したい番号を入力してください："
    SAMPLES.each_with_index do |sample, index|
      puts "  #{index + 1}. サンプル: #{sample}"
    end
    puts "  c. 自分でSQLを直接入力する"
    puts "  q. 終了する"
    print "\n入力 > "
    choice = gets.chomp.strip

    case choice.downcase
    when 'q'
      puts "\nデモを終了します。パーサー作りの最初の一歩を楽しんでいただけましたか？"
      break
    when 'c'
      puts "\n簡易SQLを入力してください (例: SELECT id, title FROM posts WHERE category = 'ruby')"
      puts "※このパーサーは、SELECT ... FROM ... [WHERE ... = ...] 形式のみサポートしています。"
      print "SQL > "
      custom_sql = gets.chomp.strip
      if custom_sql.empty?
        puts "⚠️ SQLが入力されませんでした。"
      else
        execute_parsing(custom_sql)
      end
    else
      index = choice.to_i - 1
      if index >= 0 && index < SAMPLES.length
        execute_parsing(SAMPLES[index])
      else
        puts "⚠️ 無効な入力です。もう一度選んでください。"
      end
    end

    puts "\n何かキーを押すとメニューに戻ります..."
    gets
    clear_screen
  end
end

# デモを開始
start_demo
