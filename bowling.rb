# encoding: utf-8

#フレーム計算クラス
class Frame

   #定数
   DEFAULT_MAX_THROW_COUNT = 2
   LAST_FRAME_MAX_THROW_COUNT = 3
   LAST_FRAME_NUMBER = 10
   DEFAULT_MAX_SCORE = 10

   public

   #コンストラクタ
   def initialize(frame_number)

     if frame_number < 0 || frame_number > 10
       raise ArgumentError, "フレーム番号が不正です。"
     end

     #プロパティの初期化
     @frame_number = frame_number
     @scores = Array.new
     @current_ball_count = 0
     @next_scores =Array.new

   end

  #メソッド

  #次の投球ができるかどうか
  def has_next_throw?

    next_ball_count = @current_ball_count + 1

    if last_frame?
      return next_ball_count <= LAST_FRAME_MAX_THROW_COUNT &&
             ((strike? || spare?) || next_ball_count <= DEFAULT_MAX_THROW_COUNT)

    else
      return next_ball_count <= DEFAULT_MAX_THROW_COUNT &&
              !(strike? || spare?)
    end

  end

  #投球する
  def throw_ball(score)

      raise ArgumentError, "不正なスコアが渡されました。" unless invalid_score?(score)
      @current_ball_count = @current_ball_count + 1
      @scores.push(score)

  end

   #フレームのスコアが現時点で計算できるか
   def get_score?

      return true if last_frame?

      if spare?
        return @next_scores.length == 1
      elsif strike?
        return @next_scores.length == 2
      end

      true

   end

   #計算のために後続のスコアを入力
   def add_next_score(score)

     @next_scores.push(score)

   end

  #フレームのスコアを計算
   def get_score

      sum_score = @scores.inject {|sum, score| sum + score }
      total_score = sum_score ? sum_score : 0

      if last_frame?
        return total_score
      elsif spare?
        return total_score + @next_scores[0]
      elsif strike?
        return total_score + @next_scores.take(2).inject {|sum, score| sum + score }
      end

      total_score

   end

   private

   #最終フレームかどうか
   def last_frame?

     @frame_number == LAST_FRAME_NUMBER

   end

   #ストライクかどうか
   def strike?

     get_simple_score_of(1) == DEFAULT_MAX_SCORE

   end

   #スペアかどうか
   def spare?

     !strike? &&
     (get_simple_score_of(1) + get_simple_score_of(2)) == DEFAULT_MAX_SCORE

   end

  #計算せずにスコアを取り出す
   def get_simple_score_of(index)

     score = @scores.at(index - 1)
     score ? score : 0

   end

   #計算しないスコアの合計を取り出す
   def get__total_simple_score()

     get_simple_score_of(1) + get_simple_score_of(2) + get_simple_score_of(3)

   end

   #スコアの妥当性判定
   def invalid_score?(number)

     #２球の合計が10点以内か
     total_score = @scores.inject {|sum, score| sum + score }
     sum_score = (total_score ? total_score : 0) + number
     sum_between = last_frame? || sum_score <= 10

     sum_between && (number >= 0 && number <= 10)

   end

end

#ボーリングクラス
class BowlingGame

  #定数
  MAX_FRAMES_COUNT = 10

  public

  #コンストラクタ
  def initialize()

    @current_frame_number = 1
    @frames = (1..MAX_FRAMES_COUNT).map{|i| Frame.new(i)}
    @not_scored_frames =Array.new

  end

  #メソッド

  #ゲームを続けられるか
  def continue?

    last_frame = @frames[MAX_FRAMES_COUNT - 1]
    @current_frame_number <= MAX_FRAMES_COUNT && last_frame.has_next_throw?

  end

  #投球する
  def throw_ball(score)

    #投球する
    current_frame.throw_ball(score)

    #これまで計算できなかったフレームにスコアを渡す
    @not_scored_frames.each do |frame|
      frame.add_next_score(score)
    end

    #計算できるようになったフレームを取り除く
    @not_scored_frames = @not_scored_frames.reject{|frame| frame.get_score?}

    #必要ならフレームを進める
    if (!current_frame.has_next_throw?) &&
       continue?
      @not_scored_frames.push(current_frame) unless current_frame.get_score?
      @current_frame_number = @current_frame_number + 1
    end

  end

  #これまでの得点を計算
  def get_score

    score = 0
    @frames.each do |frame|
      if frame.get_score?
        score = score + frame.get_score
      else
        break
      end
    end

    score

  end

  private

  #現在のフレームを取得
  def current_frame

    @frames[@current_frame_number - 1]

  end

end

#整数判定
def integer_string?(str)
  Integer(str)
  true
rescue ArgumentError
  false
end

#ゲーム開始
game = BowlingGame.new

puts "ゲーム開始！"

#可能な限り、ゲームを継続
while game.continue?

  puts "スコアを入力してください。"
  input = gets.to_s.chomp

  #ゲーム強制終了
  if(input == "quit")
    break
  end

  if !integer_string?(input)
    puts "数値を入力してください。"
    next
  end

  score = input.to_i
  begin
    game.throw_ball(score)
    puts "現在のスコアは#{game.get_score}です。"

  #不正入力対策
  rescue ArgumentError => ex
    puts ex.message
    next
  end

end

#ゲーム終了
puts "ゲーム終了です。最終スコアは#{game.get_score}でした。お疲れ様でした。"

#+++++自動テスト+++++

#条件が満たされない場合エラーにする
def assert(condition)
  raise "Error" if !condition
end

#フレームのテスト

def over_10_frame_number_is_error
  begin
      frame = Frame.new(11)
  rescue
    assert(true)
    return
  end
  assert(false)
end
over_10_frame_number_is_error

def bellow_0_frame_number_is_error
  begin
      frame = Frame.new(-1)
  rescue
    assert(true)
    return
  end
  assert(false)
end
bellow_0_frame_number_is_error

def normal_frame_must_get_score
  frame = Frame.new(1)
  frame.throw_ball(5)
  frame.throw_ball(4)
  assert(frame.get_score?)
  assert(frame.get_score == 9)
end
normal_frame_must_get_score

def frame_has_only_two_throws
  frame = Frame.new(1)
  frame.throw_ball(5)
  assert(frame.has_next_throw?)
  frame.throw_ball(4)
  assert(!frame.has_next_throw?)
end
frame_has_only_two_throws

def spare_frame_cannot_get_score
  frame = Frame.new(1)
  frame.throw_ball(5)
  frame.throw_ball(5)
  assert(!frame.get_score?)
end
spare_frame_cannot_get_score

def spare_frame_has_no_throw
  frame = Frame.new(1)
  frame.throw_ball(5)
  frame.throw_ball(5)
  assert(!frame.has_next_throw?)
end
spare_frame_has_no_throw

def spare_frame_add_next_score
  frame = Frame.new(1)
  frame.throw_ball(5)
  frame.throw_ball(5)
  frame.add_next_score(5)
  assert(frame.get_score == 15)
end
spare_frame_add_next_score

def strike_frame_cannot_get_score
  frame = Frame.new(1)
  frame.throw_ball(10)
  assert(!frame.get_score?)
end
strike_frame_cannot_get_score

def strike_frame_has_no_throw
  frame = Frame.new(1)
  frame.throw_ball(10)
  assert(!frame.has_next_throw?)
end
strike_frame_has_no_throw

def strike_frame_add_next_score
  frame = Frame.new(1)
  frame.throw_ball(10)
  frame.add_next_score(5)
  frame.add_next_score(4)
  assert(frame.get_score == 19)
end
strike_frame_add_next_score

def last_frame_has_two_throws_if_normal
  frame = Frame.new(10)
  frame.throw_ball(5)
  assert(frame.has_next_throw?)
  frame.throw_ball(4)
  assert(!frame.has_next_throw?)
end
last_frame_has_two_throws_if_normal

def last_frame_has_three_throws_if_double
  frame = Frame.new(10)
  frame.throw_ball(10)
  assert(frame.has_next_throw?)
  frame.throw_ball(10)
  assert(frame.has_next_throw?)
  frame.throw_ball(10)
  assert(!frame.has_next_throw?)
end
last_frame_has_three_throws_if_double

def last_frame_has_three_throws_if_spare
  frame = Frame.new(10)
  frame.throw_ball(5)
  assert(frame.has_next_throw?)
  frame.throw_ball(5)
  assert(frame.has_next_throw?)
  frame.throw_ball(8)
  assert(!frame.has_next_throw?)
end
last_frame_has_three_throws_if_spare

def last_frame_sum_three_scores_if_double
  frame = Frame.new(10)
  frame.throw_ball(10)
  frame.throw_ball(10)
  frame.throw_ball(10)
  assert(frame.get_score == 30)
end
last_frame_sum_three_scores_if_double

def last_frame_sum_three_scores_if_spare
  frame = Frame.new(10)
  frame.throw_ball(5)
  frame.throw_ball(5)
  frame.throw_ball(10)
  assert(frame.get_score == 20)
end
last_frame_sum_three_scores_if_spare

def over_score_is_error
  begin
      frame = Frame.new(1)
      frame.throw_ball(11)
  rescue
    assert(true)
    return
  end
  assert(false)
end
over_score_is_error

def under_score_is_error
  begin
      frame = Frame.new(1)
      frame.throw_ball(-1)
  rescue
    assert(true)
    return
  end
  assert(false)
end
under_score_is_error

def over_10_score_is_error
  begin
      frame = Frame.new(1)
      frame.throw_ball(5)
      frame.throw_ball(6)
  rescue
    assert(true)
    return
  end
  assert(false)
end
over_10_score_is_error

def normal_throws_must_get_score
  game = BowlingGame.new
  game.throw_ball(3)
  game.throw_ball(4)
  game.throw_ball(3)
  assert(game.get_score == 10)
end
normal_throws_must_get_score

#ボーリングゲームのテスト

def spare_frame_must_not_get_score
  game = BowlingGame.new
  game.throw_ball(7)
  game.throw_ball(3)
  assert(game.get_score == 0)
end
spare_frame_must_not_get_score

def strike_frame_must_not_get_score
  game = BowlingGame.new
  game.throw_ball(10)
  assert(game.get_score == 0)
end
strike_frame_must_not_get_score

def spare_frame_get_score_after_1throws
  game = BowlingGame.new
  game.throw_ball(7)
  game.throw_ball(3)
  game.throw_ball(5)
  assert(game.get_score == 20)
end
spare_frame_get_score_after_1throws

def strike_frame_get_score_after_2throws
  game = BowlingGame.new
  game.throw_ball(10)
  game.throw_ball(2)
  game.throw_ball(3)
  assert(game.get_score == 20)
end
strike_frame_get_score_after_2throws

def all_4_scores_must_be_80_in_total
  game = BowlingGame.new
  20.times{
    game.throw_ball(4)
  }
  assert(!game.continue?)
  assert(game.get_score == 80)
end
all_4_scores_must_be_80_in_total

def triple_get_score_after_2throws
  game = BowlingGame.new
  game.throw_ball(10)
  game.throw_ball(10)
  game.throw_ball(10)
  game.throw_ball(3)
  game.throw_ball(4)
  assert(game.get_score == 77)
end
triple_get_score_after_2throws

def perfect_game_must_scores_300
  game = BowlingGame.new
  12.times{
    game.throw_ball(10)
  }
  assert(!game.continue?)
  assert(game.get_score == 300)
end
perfect_game_must_scores_300
