# typed: true

require 'forwardable'

module Dyndnsd
  class Database
    extend Forwardable

    def_delegators :@db, :[], :[]=, :each, :has_key?

    # @param db_file [String]
    def initialize(db_file)
      @db_file = db_file
    end

    # @return [void]
    def load
      if File.file?(@db_file)
        @db = JSON.parse(File.read(@db_file, mode: 'r'))
      else
        @db = {}
      end
      @db_hash = @db.hash
    end

    # @return [void]
    def save
      Helper.span('database_save') do |_span|
        File.open(@db_file, 'w') { |f| JSON.dump(@db, f) }
        @db_hash = @db.hash
      end
    end

    # @return [Boolean]
    def changed?
      @db_hash != @db.hash
    end
  end
end
