class PropertyContent
  def initialize
    @content = Array.new
  end
  def content
    return nil if @content.empty?
    return @content[0] if @content.length == 1
    @content
  end
  def content=(c)
    @content << c
  end

  def to_json(options)
    content.to_json(options) #.gsub('\"', '')
  end

end

