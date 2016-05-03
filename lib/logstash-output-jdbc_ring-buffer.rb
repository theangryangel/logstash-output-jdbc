class RingBuffer < Array
  attr_reader :max_size

  def initialize(max_size, enum = nil)
    @max_size = max_size
    enum.each { |e| self << e } if enum
  end

  def <<(el)
    if self.size < @max_size || @max_size.nil?
      super
    else
      self.shift
      self.push(el)
    end
  end

  def not_nil_length
    reject { |i| i.nil? }.count
  end
end
