module GitlabAwesomeRelease
  module ArrayWithinExt
    refine Array do
      def within(from_value, to_value)
        from_index = find_index(from_value)
        to_index   = find_index(to_value)

        raise ArgumentError, "#{from_value} is not included in #{inspect}" unless from_index
        raise ArgumentError, "#{to_value} is not included in #{inspect}"   unless to_index

        self[from_index..to_index]
      end
    end
  end
end
