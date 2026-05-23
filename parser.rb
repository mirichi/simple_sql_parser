# parser.rb
# 超シンプルなSQL構文解析器 (Parser)
#
# このクラスは、Lexerが分割した「トークン列」を受け取り、SQLの構文ルールに従って解析します。
# ルールに合致していれば、構造化したデータ（抽象構文木: AST）を返します。
# ルールから外れている場合（構文エラー）は、分かりやすいエラーメッセージを投げます。
#
# 対応する文法：
#   SELECT (カラム名1, カラム名2... または *) FROM (テーブル名) [WHERE (カラム名) = (値)]

class SimpleSqlParser
  def initialize(tokens)
    @tokens = tokens   # Lexerから渡されたトークン配列
    @position = 0      # 現在解析しているトークンのインデックス
  end

  # 解析を開始し、構文木（RubyのHash）を返します
  def parse
    # 1. 最初の単語は絶対に "SELECT" キーワードでなければならない
    consume(:keyword, "SELECT")

    # 2. SELECTの次は、取得したい「カラム名リスト」（または '*'）を解析する
    columns = parse_columns

    # 3. カラムの次は、絶対に "FROM" キーワードでなければならない
    consume(:keyword, "FROM")

    # 4. FROMの次は、対象の「テーブル名」（識別子）でなければならない
    table_token = consume(:identifier)
    table = table_token[:value]

    # 5. オプション（省略可能）の "WHERE" 句を解析する
    where_clause = nil
    if current_token && current_token[:type] == :keyword && current_token[:value] == "WHERE"
      consume(:keyword, "WHERE")
      where_clause = parse_where_clause
    end

    # 6. すべてのトークンを消費し終わっているか確認する
    # 余分なトークンが残っている場合は、構文エラーとする（例: SELECT a FROM b EXTRA_WORD）
    if @position < @tokens.length
      raise "構文エラー: SQLの末尾に予期しない記述があります: '#{current_token[:value]}'"
    end

    # 最終的な解析結果を「構文木 (AST)」としてHash形式で返します
    {
      select: columns,
      from: table,
      where: where_clause
    }
  end

  private

  # 現在ポインタが指しているトークンを取得する
  def current_token
    @tokens[@position]
  end

  # 特定のタイプ（および特定の値）のトークンを消費（読み飛ばして次に進める）する。
  # もし期待したトークンと異なる場合は、分かりやすい構文エラーを発生させる。
  def consume(expected_type, expected_value = nil)
    token = current_token

    # すでにトークンを全て読み終わってしまっている場合
    if token.nil?
      expected_desc = expected_value ? "'#{expected_value}'" : expected_type.to_s
      raise "構文エラー: SQLが途中で途切れています。期待されていたトークン: #{expected_desc}"
    end

    # トークンのタイプ、または値が一致しない場合
    if token[:type] != expected_type || (expected_value && token[:value] != expected_value)
      expected_desc = expected_value ? "'#{expected_value}'" : expected_type.to_s
      raise "構文エラー: 予期しない単語です: '#{token[:value]}' (期待されていた単語: #{expected_desc})"
    end

    # ポインタを1つ進めて、消費したトークンを返す
    @position += 1
    token
  end

  # カラムリストをパースする（例: `*` または `id` または `id, name, age`）
  def parse_columns
    columns = []

    # '*'（すべて）が指定された場合
    if current_token && current_token[:type] == :asterisk
      consume(:asterisk)
      return ["*"]
    end

    # 最初（1つ目）のカラム名をパースする
    first_col = consume(:identifier)
    columns << first_col[:value]

    # カンマが続く限り、繰り返し次のカラム名を読み込む
    while current_token && current_token[:type] == :comma
      consume(:comma) # カンマを消費
      next_col = consume(:identifier) # 次のカラム名を消費
      columns << next_col[:value]
    end

    columns
  end

  # WHERE句の条件式をパースする（例: `role = 'admin'`）
  # 簡易化のため「(カラム名) = (文字列リテラル または 数値)」のみを対象とします。
  def parse_where_clause
    # 1. カラム名（識別子）
    column_token = consume(:identifier)

    # 2. イコール（比較演算子）
    operator_token = consume(:equals)

    # 3. 比較する値（文字列リテラル または 数値リテラル）
    value_token = current_token
    if value_token && (value_token[:type] == :string || value_token[:type] == :number)
      @position += 1 # トークンを消費して進める
    else
      raise "構文エラー: WHERE句のイコールの後には、文字列（'値'）または数値を指定してください。"
    end

    {
      column: column_token[:value],
      operator: operator_token[:value],
      value: value_token[:value]
    }
  end
end
