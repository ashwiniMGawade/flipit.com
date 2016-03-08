module GiMiScale
  module ArrayExt
    def map_with_index &block
      index = 0
      map do |element|
        result = yield element, index
        index += 1
        result
      end
    end
  end
end

[Array, Range].each do |klass|
  klass.class_eval do
    include GiMiScale::ArrayExt
  end
end
