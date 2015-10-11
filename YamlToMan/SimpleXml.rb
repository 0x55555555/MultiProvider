
class Node
  def initialize(name)
    @name = name
    @attributes = { }
    @children = []
  end

  def add(node)
    if (node.is_a?(Symbol))
      node = Node.new(node)
    end

    yield(node) if block_given?

    @children << node
    return node
  end

  def set_attr(name, value)
    @attributes[name] = value.to_s
  end

  def method_missing(method_sym, *arguments, &block)
    name = method_sym
    if (method_sym.to_s.end_with?('='))
      name = method_sym[0...-1].to_sym
      set_attr(name, arguments[0])
    end

    return @attributes[name]
  end

  def to_xml_document(line_start:'', tab:"  ", new_line:"\n")
    return "<?xml version='1.0' encoding='utf-8' standalone='yes'?>" + new_line +
      to_xml(line_start: line_start, tab: tab, new_line: new_line)
  end

  def to_xml(line_start:'', tab:"  ", new_line:"\n")

    children = @children.map{ |c| c.to_xml(line_start: line_start + tab, tab: tab, new_line: new_line) }

    str = line_start + opening_xml(close: children.empty?) + new_line

    if (!children.empty?)
      str += children.join() +
        line_start + closing_xml() + new_line
    end

    return str
  end

  def opening_xml(close: false)
    attributes = @attributes.map{ |k, v| "#{k}=\"#{escape(v)}\"" }.join(" ")
    attributes.prepend(" ") unless attributes.empty?

    closer = close ? '/' : ''
    return "<#{@name}#{attributes}#{closer}>"
  end

  def closing_xml()
    return "</#{@name}>"
  end

  def escape(value)
    return value
      .gsub('"', '&quot;')
      .gsub("'", '&apos;')
      .gsub('<', '&lt;')
      .gsub('>', '&gt;')
      .gsub('&', '&amp;')
  end
end
