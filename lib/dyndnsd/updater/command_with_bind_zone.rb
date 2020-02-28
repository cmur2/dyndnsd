
module Dyndnsd
  module Updater
    class CommandWithBindZone
      # @param domain [String]
      # @param config [Hash{String => Object}]
      def initialize(domain, config)
        @zone_file = config['zone_file']
        @command = config['command']
        @generator = Generator::Bind.new(domain, config)
      end

      # @param db [Dyndnsd::Database]
      # @return [void]
      def update(db)
        Helper.span('updater_update') do |span|
          span.set_tag('dyndnsd.updater.name', self.class.name.split('::').last)

          # write zone file in bind syntax
          File.open(@zone_file, 'w') { |f| f.write(@generator.generate(db)) }
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
end
