
module Dyndnsd
  module Updater
    class CommandWithBindZone
      def initialize(domain, config)
        @zone_file = config['zone_file']
        @command = config['command']
        @generator = Generator::Bind.new(domain, config)
      end

      def update(zone)
        # write zone file in bind syntax
        File.open(@zone_file, 'w') { |f| f.write(@generator.generate(zone)) }
        # call user-defined command
        pid = fork do
          exec @command
        end
        # detach so children don't become zombies
        Process.detach(pid)
      end
    end
  end
end
