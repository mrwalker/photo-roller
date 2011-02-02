#! /usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'photo_roller'

STDOUT.sync = true

# See: http://www.ruby-forum.com/topic/105212
module Net
  class BufferedIO
    def rbuf_fill
      timeout(@read_timeout, ProtocolError) {
        @rbuf << @io.sysread(BUFSIZE)
      }
    end
  end
end

PhotoRoller.new.upload(YAML.load_file('config/account.yml'))
