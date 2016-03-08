module GiMiScale
  module FixnumExt
    def min
      to_i
    end

    def max
      to_i
    end

    def k
      to_i * 1024
    end

    def M
      k * 1024
    end

    def G
      M * 1024
    end

    def T
      G * 1024
    end

    def P
      T * 1024
    end
  end
end

[Fixnum].each do |klass|
  klass.class_eval do
    include GiMiScale::FixnumExt
  end
end
