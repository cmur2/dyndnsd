# Minimal pure-Ruby replacement for the 'atomic' gem, covering the exact API
# the vendored metriks code uses (Atomic.new, #value, #value=, #update,
# #compare_and_swap). Mutex-guarded instead of relying on a native extension.
module Metriks
  class Atomic
    def initialize(value = nil)
      @value = value
      @mutex = Mutex.new
    end

    def value
      @mutex.synchronize { @value }
    end

    def value=(new_value)
      @mutex.synchronize { @value = new_value }
    end

    def update
      @mutex.synchronize { @value = yield(@value) }
    end

    def compare_and_swap(expected, new_value)
      @mutex.synchronize do
        if @value == expected
          @value = new_value
          true
        else
          false
        end
      end
    end
  end
end
