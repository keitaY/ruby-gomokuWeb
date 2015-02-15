require 'em-websocket'
# requires the twitter-stream gem
require 'json'

#
# broadcast all ruby related tweets to all connected users!
#

connections = 0
lobby = []
room = []

def showConnections(lobby,room,connections)
     puts "\nlobby:"
     puts lobby
     puts "\nroom:"  
     puts room
     print(room)
     puts "\nconnections:"
     puts connections
end

def lobbyToRoom(lobby,room)
  if lobby.count>=2 then 
    puts "\n----------------------------------------------------shift to room\n"
    room << lobby.take(2)
    lobby.shift(2)
  end
end

EventMachine.run {
  @channel = EM::Channel.new
  @@connected = Hash.new

  EventMachine::WebSocket.start(:host => "192.168.179.5", :port => 3333, :debug => true) do |ws|

    ws.onopen {
               sid = @channel.subscribe { |msg| ws.send msg }
             # @channel.push "#{sid} connected!"
              connections = connections+1
              ws.send "{\"id\":#{sid},\"bw\":-1,\"gy\":-1,\"gx\":-1}"#send id to client
              lobby << ws
              
	      lobbyToRoom(lobby,room)
              showConnections(lobby,room,connections)
              
              ws.onmessage { |msg|
                             printf("<#{sid}>")
                           roomnumber = room.assoc(ws)
                           if roomnumber==nil then roomnumber = room.rassoc(ws) end
			     roomnumber.each{|roomsocket| roomsocket.send "#{msg}"
                                                 print("#")}
                           }
              
              ws.onclose {
                          connections = connections-1
                         lobby.delete(ws)
                         room.delete(ws)
                         @channel.unsubscribe(sid)
                         printf("<#{sid}> closed\n")
                         showConnections(lobby,room,connections)
                         }
              
              }
  end

  puts "Server started"
}