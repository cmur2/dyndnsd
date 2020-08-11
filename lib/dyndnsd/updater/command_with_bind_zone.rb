# frozen_string_literal: true

module Dyndnsd
  module Updater
    class CommandWithBindZone
      # @param domain [String]
      # @param updater_params [Hash{String => Object}]
      def initialize(domain, updater_params)
        @zone_file = updater_params['zone_file']
        @command = updater_params['command']
        @generator = Generator::Bind.new(domain, updater_params)
      end

      # @param db [Dyndnsd::Database]
      # @return [void]
      def update(db)
        # do not regenerate zone file (assumed to be persistent) if DB did not change
        return if !db.changed?

        Helper.span('updater_update') do |span|
          span.set_tag('dyndnsd.updater.name', self.class.name&.split('::')&.last || 'None')

          # write zone file in bind syntax
          File.open(@zone_file, 'w') { |f| f.write(@generator.generate(db)) }
          # call user-defined command
          pid = fork do
            exec @command
          end

          # detach so children don't become zombies
          Process.detach(pid) if pid
        end
      end
    end
  end
end
