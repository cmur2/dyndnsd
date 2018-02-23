
require 'forwardable'

module Dyndnsd
  class Database
    extend Forwardable

    def_delegators :@db, :[], :[]=, :each, :has_key?

    def initialize(db_file)
      @db_file = db_file
    end

    def load
      if File.file?(@db_file)
        @db = JSON.parse(File.open(@db_file, 'r', &:read))
      else
        @db = {}
      end
      @db_hash = @db.hash
    end

    def save
      File.open(@db_file, 'w') { |f| JSON.dump(@db, f) }
      @db_hash = @db.hash
    end

    def changed?
      @db_hash != @db.hash
    end
  end
end
