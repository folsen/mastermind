require 'rubygems'
require 'eventmachine'
require 'sqlite3'

class MasterMind < EventMachine::Connection
  MaxLinesPerConnection = 10

  def post_init
    puts "Received a new connection"
    @line_count = 0
    @correct = ""
    @complete = false
    4.times { @correct += rand(10).to_s }
    send_data "Ready to play a game?\nType four numbers.\n"
    send_data "(Type 'exit' to exit)\n\n"
    @db = SQLite3::Database.new( "mastermind.db" )
    @db.results_as_hash = true
  end

  def receive_data data
    while data.chomp!
      if @complete
        send_data "\n\nHighscores\n"
        @db.execute( "insert into highscores values(?, ?)", data, @line_count+1)
        @db.execute( "select * from highscores order by score asc limit 10" ).each_with_index do |row, i|
          send_data "##{i+1} #{row['name']} with score #{row['score']} \n"
        end
        send_data "\n"
        close_connection_after_writing
      end
      data.gsub!(/ /, '')
      close_connection_after_writing if data == "exit"
      4.times do |i| 
        send_data "X" if data[i] != @correct[i]
        send_data "O" if data[i] == @correct[i]
        send_data " " if i != 3
      end
      send_data "\n"
      if data == @correct
        send_data "You made it in #{@line_count+1} tries! :D\nPlease enter your name.\n"
        puts "A player just completed the game!"
        @complete = true
      else
        @line_count += 1
      end
      if @line_count == MaxLinesPerConnection 
        send_data "You've run out of attempts.\nYou can connect again if you want.\n\n"
        close_connection_after_writing
      end
    end
  end

end


EM.run {
  EM.start_server "85.224.245.8", 1337, MasterMind
}
