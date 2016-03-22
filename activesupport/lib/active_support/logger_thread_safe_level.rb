require 'concurrent'
require 'logger'

module ActiveSupport
  module LoggerThreadSafeLevel # :nodoc:
    def initialize(*)
      super
      @local_levels = Concurrent::Map.new(initial_capacity: 2)
    end

    def add(severity, message = nil, progname = nil, &block)
      return true if @logdev.nil? || (severity || UNKNOWN) < level
      super
    end

    ::Logger::Severity.constants.each do |severity|
      class_eval(<<-EOT, __FILE__, __LINE__ + 1)
        def #{severity.downcase}?                # def debug?
          ::Logger::#{severity} >= level           #   DEBUG >= level
        end                                      # end
      EOT
    end

    def level
      local_level || super
    end

    def local_log_id
      Thread.current.__id__
    end

    def local_level
      @local_levels[local_log_id]
    end

    def local_level=(level)
      if level
        @local_levels[local_log_id] = level
      else
        @local_levels.delete(local_log_id)
      end
    end
  end
end
