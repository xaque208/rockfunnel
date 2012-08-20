#

require 'redis'

module RockFunnel
  module_function

  class Graphite
    def initialize(server,port)
      @server, @port = server, port
      @s = TCPSocket.open(server,port)
    end

    def send (target,value,time)
      line = "#{target} #{value} #{time}"
      puts line
      @s.puts(line)
    end

    def close
      @s.close
    end
  end


end
