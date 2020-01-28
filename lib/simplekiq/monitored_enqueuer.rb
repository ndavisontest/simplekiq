require 'simplekiq/worker'
require 'simplekiq/monitoring_setup'

module Simplekiq
  module MonitoredEnqueuer
    def self.included(base)
      base.include Simplekiq::Worker
      base.prepend MonitoringSetup

      base.sidekiq_options monitoring_enabled: true
    end
  end
end
