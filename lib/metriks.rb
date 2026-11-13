# Vendored from metriks 0.9.9.8 — https://github.com/eric/metriks
# Copyright (c) 2012 Eric Lindvall, MIT licensed.
# Trimmed to the subset dyndnsd uses (meters + registry + reporters);
# counter/gauge/timer/utilization_timer/histogram support was removed,
# and the 'atomic'/'avl_tree'/'hitimes' dependencies were replaced or dropped.

module Metriks
  VERSION = '0.9.9.8'

  def self.get(name)
    Registry.default.get(name)
  end

  def self.meter(name)
    Registry.default.meter(name)
  end

  def self.registry
    Registry.default
  end
end

require 'metriks/atomic'
require 'metriks/ewma'
require 'metriks/meter'
require 'metriks/registry'
require 'metriks/reporter/proc_title'
