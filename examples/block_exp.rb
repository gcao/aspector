class A
  def self.def_m &block
    define_method :m do |*args|
      block.call self, *args
    end
  end
end

A.def_m do |this, *args|
  p this
  p *args
end

A.new.m 100

