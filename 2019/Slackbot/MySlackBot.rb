$LOAD_PATH.unshift(File.dirname(__FILE__))
#coding: utf-8
require 'sinatra'
require 'SlackBot'

class MySlackBot < SlackBot
  # cool code goes here
  # メッセージの受け取り
  # メッセージのパース
  # メッセージに応じた処理
  # post_message
  def parrot(msg)
    s = msg.split("と言って")
    string = s[0]
    post_message(string[8.. s[0].length-1].strip)
  end

  def build_param(name, value)
    return "" if value == nil || value == ""
    return "&#{name}=" + URI.encode(value)
  end

  def build_sort_param(name, value)
    table = {
            "人気" => 'sales',
            "古い" => '%2BreleaseDate',
            "新しい" => '-releaseDate',
            "安い" => '%2BitemPrice',
            "高い" => '-itemPrice',
          }
    return build_param(name ,table[value])
  end

  def API_rakuten(request)
    request.gsub!("　"," ")
    request.gsub!("，",",")

    p s = request.split(',')
    title,hard,sort = request.split(',').map(&:strip)


    title_p = build_param("title",title)
    hard_p = build_param("hardware",hard)
    sort_p = build_sort_param("sort", sort)
    find = "[ タイトル：#{title}, 機種：#{hard}, ソート：#{if (sort_p) && (sort_p != "")then sort else "標準" end} ]で検索します．\n"
    post_message(find)

    base = 'https://app.rakuten.co.jp/services/api/BooksGame/Search/20170404?format=json&booksGenreId=006&hits=3'
    settings_file_path = "settings.yml"
    config = YAML.load_file(settings_file_path) if File.exist?(settings_file_path)
    applicationId = ENV['APPLICATION_ID']||config['applicationId']
    base = "#{base}&applicationId=#{applicationId}"
    p uri = URI.parse(base + title_p + hard_p + sort_p)
    json = Net::HTTP.get(uri)
    result = JSON.parse(json)
    p result
    if result["Items"].empty?
      message = "購入できる商品はありませんでした．\n"
      post_message(message)
    else
      for i in 0..2 do
        if  result["Items"][i] != nil
        message = "---- " + (i+1).to_s + " ----\n"
        message += "タイトル：" + result["Items"][i]["Item"]["title"]
        message += "\n対応機種：" + result["Items"][i]["Item"]["hardware"]
        message += "\n発売日　：" + result["Items"][i]["Item"]["salesDate"]
        message += "\n価格　　：" + result["Items"][i]["Item"]["itemPrice"].to_s+ "円"
        message += "\n評価平均：" + result["Items"][i]["Item"]["reviewAverage"] + "/ 5.0"
        message += "（評価件数：" + result["Items"][i]["Item"]["reviewCount"].to_s + "）"
        message += "\n楽天ブックスURL：" + result["Items"][i]["Item"]["itemUrl"]
        post_message(message)
        end
      end
      post_message("以上です．\n")
    end
  end

  def show_help()
    help = "こんにちは！私はhamabotです．私には2つの機能が備わっています．\n"
    help += "機能(1)\n"
    help += "「○○と言って」と入力すると「○○」と発言します．\n"
    help += "機能(2)\n"
    help += "楽天ブックスで販売しているゲームに関する商品を検索し，上位3件を表示します．\n"
    help += "＜検索フォーマット => @hamabot [タイトル],[機種],[ソート]で検索＞\n"
    help += "　｜[タイトル]...2文字以上で入力してください．\n"
    help += "　｜[機種]...Swich，DS，PS3など，機種名をアルファベットと数字で入力してください．\n"
    help += "　｜[ソート]...人気，古い，新しい，安い，高い　のうちから一つ選ぶことができます．（それ以外の場合は標準のソートを行います．）\n"
    help += "なお，販売していない商品は検索の対象外となっております．\n"
    post_message(help)
  end
end

slackbot = MySlackBot.new

set :environment, :production

get '/' do
  "SlackBot Server"
end

post '/slack' do
  return nil if params[:user_name] == "slackbot" || params[:user_id] == "USLACKBOT"
  content_type :json
  if params[:text].include?('と言って')
    slackbot.parrot(params[:text])

  elsif params[:text].include?('で検索')
    s = params[:text]
    slackbot.API_rakuten(s[8.. s.length-4].strip)

else
  slackbot.show_help
  # @hamabot マリオ，DS,人気
  # slackbot.naive_respond(params, username: "")
  end
end
