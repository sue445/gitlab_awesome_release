module GitlabAwesomeRelease
  module GitlabLoggingExt
    def get(path, options={})
      start_time = Time.now

      super(path, options)

    ensure
      end_time = Time.now

      # NOTE: options[:headers] contains PRIVATE-TOKEN
      _options = options.reject{ |k, _v| k == :headers }
      logger.debug "(#{end_time - start_time} sec) GET #{path} #{_options}"
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end
  end
end

Gitlab::Request.class_eval do
  prepend GitlabAwesomeRelease::GitlabLoggingExt
end
