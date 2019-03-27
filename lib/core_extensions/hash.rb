class Hash
  def deep_symbolize_all_keys
    deep_transform_all{ |key| key.to_sym rescue key }
  end

  private

  def deep_transform_all(&block)
    _deep_transform_all_in_object(self, &block)
  end

  # support methods for deep transforming nested hashes and arrays
  def _deep_transform_all_in_object(object, &block)
    case object
    when Hash
      object.each_with_object({}) do |(key, value), result|
        result[yield(key)] = _deep_transform_all_in_object(value, &block)
      end
    when Array
      object.map { |e| _deep_transform_all_in_object(e, &block) }
    else
      object
    end
  end
end
