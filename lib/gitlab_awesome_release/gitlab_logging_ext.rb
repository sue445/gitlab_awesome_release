module GitlabAwesomeRelease
  module GitlabLoggingExt
    [:get, :post, :put, :delete].each do |method|
      define_method method do |path, options = {}|
        begin
          start_time = Time.now

          super(path, options)
        ensure
          end_time = Time.now

          # NOTE: options[:headers] contains PRIVATE-TOKEN
          _options = options.reject{ |k, _v| k == :headers }
          logger.debug "(#{end_time - start_time} sec) #{method.upcase} #{path} #{_options}"
        end
      end
    end
  end
end

Gitlab::Request.class_eval do
  prepend GitlabAwesomeRelease::GitlabLoggingExt
  cattr_accessor :logger
end
