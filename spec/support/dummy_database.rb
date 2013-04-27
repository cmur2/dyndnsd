
require 'forwardable'

module Dyndnsd
  class DummyDatabase
    extend Forwardable
  
    def_delegators :@db, :[], :[]=, :each, :has_key?

    def initialize(db_init)
      @db_init = db_init
    end

    def load
      @db = @db_init
      @db_hash = @db.hash
    end

    def save
      @db_hash = @db.hash
    end

    def changed?
      @db_hash != @db.hash
    end
  end
end

      
