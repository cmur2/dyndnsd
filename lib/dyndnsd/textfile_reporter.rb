# frozen_string_literal: true

# Adapted from https://github.com/eric/metriks-graphite/blob/master/lib/metriks/reporter/graphite.rb

require 'metriks'

module Dyndnsd
  class TextfileReporter
    # @return [String]
    attr_reader :file

    # @param file [String]
    # @param options [Hash{Symbol => Object}]
    def initialize(file, options = {})
      @file = file

      @prefix = options[:prefix]

      @registry  = options[:registry] || Metriks::Registry.default
      @interval  = options[:interval] || 60
      @on_error  = options[:on_error] || proc { |ex| }
    end

    # @return [void]
    def start
      @thread ||= Thread.new do
        loop do
          sleep @interval

          Thread.new do
            begin
              write
            rescue StandardError => e
              @on_error[e] rescue nil
            end
          end
        end
      end
    end

    # @return [void]
    def stop
      @thread&.kill
      @thread = nil
    end

    # @return [void]
    def restart
      stop
      start
    end

    # @return [void]
    def write
      File.open(@file, 'w') do |f|
        @registry.each do |name, metric|
          case metric
          when Metriks::Meter
            write_metric f, name, metric, [
              :count, :one_minute_rate, :five_minute_rate,
              :fifteen_minute_rate, :mean_rate
            ]
          when Metriks::Counter
            write_metric f, name, metric, [
              :count
            ]
          when Metriks::UtilizationTimer
            write_metric f, name, metric, [
              :count, :one_minute_rate, :five_minute_rate,
              :fifteen_minute_rate, :mean_rate,
              :min, :max, :mean, :stddev,
              :one_minute_utilization, :five_minute_utilization,
              :fifteen_minute_utilization, :mean_utilization
            ], [
              :median, :get_95th_percentile
            ]
          when Metriks::Timer
            write_metric f, name, metric, [
              :count, :one_minute_rate, :five_minute_rate,
              :fifteen_minute_rate, :mean_rate,
              :min, :max, :mean, :stddev
            ], [
              :median, :get_95th_percentile
            ]
          when Metriks::Histogram
            write_metric f, name, metric, [
              :count, :min, :max, :mean, :stddev
            ], [
              :median, :get_95th_percentile
            ]
          end
        end
      end
    end

    # @param file [String]
    # @param base_name [String]
    # @param metric [Object]
    # @param keys [Array{Symbol}]
    # @param snapshot_keys [Array{Symbol}]
    # @return [void]
    def write_metric(file, base_name, metric, keys, snapshot_keys = [])
      time = Time.now.to_i

      base_name = base_name.to_s.gsub(/ +/, '_')
      base_name = "#{@prefix}.#{base_name}" if @prefix

      keys.flatten.each do |key|
        name = key.to_s.gsub(/^get_/, '')
        value = metric.send(key)
        file.write("#{base_name}.#{name} #{value} #{time}\n")
      end

      unless snapshot_keys.empty?
        snapshot = metric.snapshot
        snapshot_keys.flatten.each do |key|
          name = key.to_s.gsub(/^get_/, '')
          value = snapshot.send(key)
          file.write("#{base_name}.#{name} #{value} #{time}\n")
        end
      end
    end
  end
end
