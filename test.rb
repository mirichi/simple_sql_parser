# test.rb
# 超シンプルSQLパーサー自動テストスクリプト
#
# このスクリプトは、LexerとParserが意図通りに動作しているかを検証します。
# 外部ライブラリ（rspecやminitest）を一切使わず、純粋なRubyだけでテストを実行します。

require_relative 'lexer'
require_relative 'parser'

# アサーション（期待値と実際の値が一致するか確認する）用のヘルパー
def assert_equal(expected, actual, description)
  if expected == actual
    puts "  ✅ PASS: #{description}"
  else
    puts "  ❌ FAIL: #{description}"
    puts "     期待値: #{expected.inspect}"
    puts "     実際の値:   #{actual.inspect}"
    exit 1 # テスト失敗時は非ゼロのコードで終了
  end
end

# エラーが意図通り発生するか確認するヘルパー
def assert_raise(description)
  begin
    yield
    puts "  ❌ FAIL: #{description} (エラーが発生しませんでした)"
    exit 1
  rescue => e
    puts "  ✅ PASS: #{description} (エラー発生: #{e.message})"
  end
end

puts "================================================="
# テスト実行開始
puts "🧪 テストスイートを開始します..."
puts "================================================="

# --- 1. 字句解析 (Lexer) のテスト ---
puts "\n[1] 字句解析 (Lexer) の検証:"

lexer = SimpleSqlLexer.new("SELECT id, name FROM users WHERE role = 'admin'")
tokens = lexer.tokenize
expected_tokens = [
  { type: :keyword, value: "SELECT" },
  { type: :identifier, value: "id" },
  { type: :comma, value: "," },
  { type: :identifier, value: "name" },
  { type: :keyword, value: "FROM" },
  { type: :identifier, value: "users" },
  { type: :keyword, value: "WHERE" },
  { type: :identifier, value: "role" },
  { type: :equals, value: "=" },
  { type: :string, value: "admin" }
]
assert_equal(expected_tokens, tokens, "SQLが正しいトークン配列に分解されること")

# --- 2. 構文解析 (Parser) のテスト (正常系) ---
puts "\n[2] 構文解析 (Parser) の検証 (正常系):"

parser = SimpleSqlParser.new(tokens)
ast = parser.parse
expected_ast = {
  select: ["id", "name"],
  from: "users",
  where: { column: "role", operator: "=", value: "admin" }
}
assert_equal(expected_ast, ast, "WHERE句があるSQLを正しい構文木 (AST) に変換できること")

# アスタリスク (*) 指定のパース
lexer_star = SimpleSqlLexer.new("SELECT * FROM products")
tokens_star = lexer_star.tokenize
parser_star = SimpleSqlParser.new(tokens_star)
ast_star = parser_star.parse
expected_ast_star = {
  select: ["*"],
  from: "products",
  where: nil
}
assert_equal(expected_ast_star, ast_star, "SELECT * FROM ... が正しくパースできること")

# 数値条件のパース
lexer_num = SimpleSqlLexer.new("SELECT name FROM items WHERE price = 1500")
tokens_num = lexer_num.tokenize
parser_num = SimpleSqlParser.new(tokens_num)
ast_num = parser_num.parse
expected_ast_num = {
  select: ["name"],
  from: "items",
  where: { column: "price", operator: "=", value: 1500 }
}
assert_equal(expected_ast_num, ast_num, "WHERE句の数値リテラル条件が正しくパースできること")

# --- 3. エラー処理 (異常系) のテスト ---
puts "\n[3] エラー処理 (異常系) の検証:"

# SELECT直後にカラム名がないエラー
assert_raise("SELECTの直後にカラム名がない場合にエラーになること") do
  tokens_err = SimpleSqlLexer.new("SELECT FROM users").tokenize
  SimpleSqlParser.new(tokens_err).parse
end

# 文字列のクォーテーション閉じ忘れエラー
assert_raise("シングルクォートが閉じられていない場合にLexerがエラーを出すこと") do
  SimpleSqlLexer.new("SELECT name FROM users WHERE role = 'admin").tokenize
end

# 未定義文字（例えばセミコロンなどのサポート外記号）のエラー
assert_raise("未定義の文字（例: ;）が含まれる場合にLexerがエラーを出すこと") do
  SimpleSqlLexer.new("SELECT * FROM users;").tokenize
end

# 構文に余分な単語があるエラー
assert_raise("SQLの末尾に余計な単語がある場合にParserがエラーを出すこと") do
  tokens_extra = SimpleSqlLexer.new("SELECT * FROM users EXTRA").tokenize
  SimpleSqlParser.new(tokens_extra).parse
end

puts "\n================================================="
puts "🎉 すべてのテストケースをクリアしました！(All Green)"
puts "================================================="
