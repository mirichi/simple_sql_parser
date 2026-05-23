# lexer.rb
# 超シンプルなSQL字句解析器 (Lexer)
#
# このクラスは、SQLの文字列を受け取り、それを意味のある最小単位である「トークン」の配列に分解します。
# 例: "SELECT id, name FROM users"
#     => [{type: :keyword, value: "SELECT"}, {type: :identifier, value: "id"}, ...]

class SimpleSqlLexer
  # トークンの種類を定義する定数
  # キーワードは大文字小文字を区別せずマッチさせるため、すべて大文字で登録します。
  TOKEN_TYPES = {
    ',' => :comma,
    '=' => :equals,
    '*' => :asterisk,
    'SELECT' => :keyword,
    'FROM' => :keyword,
    'WHERE' => :keyword
  }.freeze

  def initialize(sql)
    @sql = sql
    @position = 0      # 現在読み込んでいる文字の位置（インデックス）
    @length = sql.length
  end

  # SQL文字列全体をスキャンし、トークンの配列を返します
  def tokenize
    tokens = []

    while @position < @length
      char = current_char

      # 1. 空白文字（スペース、タブ、改行）は無視して読み飛ばす
      if char =~ /\s/
        @position += 1
        next
      end

      # 2. 1文字で判定できる記号（カンマ、イコール、アスタリスク）の判定
      if TOKEN_TYPES.key?(char)
        tokens << { type: TOKEN_TYPES[char], value: char }
        @position += 1
        next
      end

      # 3. 文字列リテラル（シングルクォートで囲まれた値）の判定
      # 例: 'admin' など
      if char == "'"
        tokens << read_string_literal
        next
      end

      # 4. 数値リテラルの判定
      # 例: 42 など
      if char =~ /[0-9]/
        tokens << read_number_literal
        next
      end

      # 5. キーワード（SELECTなど）または識別子（カラム名、テーブル名など）の判定
      # アルファベットまたはアンダースコアで始まる単語を対象にします
      if char =~ /[a-zA-Z_]/
        tokens << read_identifier_or_keyword
        next
      end

      # 6. 定義されていない未知の文字が現れたらエラーにする
      raise "エラー: 不明な文字です: '#{char}' (位置: #{@position})"
    end

    tokens
  end

  private

  # 現在ポインタが指している1文字を取得する
  def current_char
    @sql[@position]
  end

  # シングルクォートで囲まれた文字列を終了クォートまで読み進める
  def read_string_literal
    start_pos = @position
    @position += 1 # 開始の "'" をスキップ
    value = ""

    # 終了の "'" が現れるまで文字を蓄積する
    while @position < @length && current_char != "'"
      value << current_char
      @position += 1
    end

    # 終了クォートが見つからずに文字列の末尾に達した場合はエラー
    if current_char == "'"
      @position += 1 # 終了の "'" をスキップ
    else
      raise "エラー: 閉じられていない文字列リテラルがあります (開始位置: #{start_pos})"
    end

    { type: :string, value: value }
  end

  # 連続する数字をまとめて数値トークンにする
  def read_number_literal
    value = ""
    while @position < @length && current_char =~ /[0-9]/
      value << current_char
      @position += 1
    end
    { type: :number, value: value.to_i }
  end

  # 連続する英数字（およびアンダースコア）をまとめて、キーワードか識別子か判定する
  def read_identifier_or_keyword
    value = ""
    # 英数字とアンダースコアが続く限り読み進める
    while @position < @length && current_char =~ /[a-zA-Z0-9_]/
      value << current_char
      @position += 1
    end

    # 大文字に変換して、定義済みのキーワード（SELECT, FROM, WHERE）と一致するか比較する
    uppercase_value = value.upcase
    if TOKEN_TYPES.key?(uppercase_value)
      { type: TOKEN_TYPES[uppercase_value], value: uppercase_value }
    else
      # キーワードに一致しなければ、カラム名やテーブル名などの「識別子 (identifier)」とする
      { type: :identifier, value: value }
    end
  end
end
