# Vendored from metriks 0.9.9.8 — https://github.com/eric/metriks
# Copyright (c) 2012 Eric Lindvall, MIT licensed.
# Trimmed to the subset dyndnsd uses (meters + registry + reporters).

require 'metriks/meter'

module Metriks
  # Public: A collection of metrics
  class Registry
    # Public: The default registry for the process.
    #
    # Returns the default Registry for the process.
    def self.default
      @default ||= new
    end

    # Public: Initializes a new Registry.
    def initialize
      @mutex = Mutex.new
      @metrics = {}
    end

    # Public: Clear all of the metrics in the Registry. This ensures all
    # metrics that have been added are stopped.
    #
    # Returns nothing.
    def clear
      @mutex.synchronize do
        @metrics.each do |key, metric|
          metric.stop if metric.respond_to?(:stop)
        end

        @metrics = {}
      end
    end

    # Public: Clear all of the metrics in the Registry. This has the same
    # effect as calling #clear.
    #
    # Returns nothing.
    def stop
      clear
    end

    # Public: Iterate over all of the counters.
    #
    # Examples
    #
    #   registry.each do |name, metric|
    #     puts name
    #   end
    #
    # Returns nothing.
    def each(&block)
      metrics = @mutex.synchronize do
        @metrics.dup
      end

      metrics.each(&block)
    end

    # Public: Fetch or create a new meter metric. Meters are a counter that
    # tracks throughput along with the count.
    #
    # name - The String name of the metric to define or fetch
    #
    # Examples
    #
    #   registry.meter('resque.calls')
    #
    # Returns the Metriks::Meter identified by the name.
    def meter(name)
      add_or_get(name, Metriks::Meter)
    end

    # Public: Fetch an existing metric.
    #
    # name - The String name of the metric to fetch
    #
    # Examples
    #
    #   registry.get('rack.utilization')
    #
    # Returns the metric or nil.
    def get(name)
      @mutex.synchronize do
        @metrics[name]
      end
    end

    # Public: Add a new metric.
    #
    # name - The String name of the metric to add
    # metric - The metric instance to add
    #
    # Examples
    #
    #   registry.add('method.calls', Metriks::Counter.new)
    #
    # Returns nothing.
    # Raises RuntimeError if the metric name is already defined
    def add(name, metric)
      @mutex.synchronize do
        if @metrics[name]
          raise "Metric '#{name}' already defined"
        else
          @metrics[name] = metric
        end
      end
    end

    protected
    def add_or_get(name, klass, &create_metric)
      @mutex.synchronize do
        if metric = @metrics[name]
          if !metric.is_a?(klass)
            raise "Metric already defined as '#{metric.class}'"
          else
            return metric
          end
        else
          @metrics[name] = create_metric ? create_metric.call : klass.new
        end
      end
    end
  end
end
