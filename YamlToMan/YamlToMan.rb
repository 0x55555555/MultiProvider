require 'yaml'

yaml = %{
types:
  position:
  - x: int32_t
  - y: int32_t
providers:
  test:
    events:
      start:
        data:
        - time: std::uint64_t
        - time2: std::uint8_t
      stop:
        task: x
        opcode: y
        keywords:
        - u
        - v
  test2:
    events:
      start:
        data:
        - time: std::uint64_t
        - time2: std::uint8_t
        task: x
        opcode: y
        keywords:
        - u
        - v
      stop:
}

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
    @attributes[name] = value
  end

  def method_missing(method_sym, *arguments, &block)
    name = method_sym
    if (method_sym.to_s.end_with?('='))
      name = method_sym[0...-1].to_sym
      @attributes[name] = arguments[0]
    end

    return @attributes[name]
  end

  def to_xml(line_start:'', tab:"  ", new_line:"\n")

    children = @children.map{ |c| c.to_xml(line_start: line_start + tab, tab: tab, new_line: new_line) }

    return line_start + opening_xml() + new_line +
        children.join() +
      line_start + closing_xml() + new_line
  end

  def opening_xml()
    attributes = @attributes.map{ |k, v| "#{k}=\"#{escape(v)}\"" }.join(" ")
    attributes.prepend(" ") unless attributes.empty?
    return "<#{@name}#{attributes}>"
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

def dump(v)
  data = v.to_ruby
  providers = data["providers"]

  instrumentationManifest = Node.new :instrumentationManifest
  instrumentationManifest.xmlns = "http://schemas.microsoft.com/win/2004/08/events"

  instrumentation = instrumentationManifest.add(:instrumentation)
  instrumentation.set_attr 'xmlns:win', "http://manifests.microsoft.com/win/2004/08/windows/events"
  instrumentation.set_attr 'xmlns:xs', "http://www.w3.org/2001/XMLSchema"
  instrumentation.set_attr 'xmlns:xsi', "http://www.w3.org/2001/XMLSchema-instance"

  instrumentation.add(:events) do |tl|
    tl.xmlns = "http://schemas.microsoft.com/win/2004/08/events"

    providers.each do |name, contents|
      tl.add(:provider) do |p|
        p.guid = "{231CF54B-22A0-49E4-A59A-47052A30FFED}"
        p.name = "Multi-Main"
        p.symbol = "MULTI_MAIN"
        p.messageFileName = "%temp%\TT_Api.dll"
        p.resourceFileName = "%temp%\TT_Api.dll"

        events = contents["events"]

        templates = p.add(:templates)
        keywords = p.add(:keywords)
        opcodes = p.add(:opcodes)
        tasks = p.add(:tasks)
        events = p.add(:events)
      end

      #puts name, events
    end
  end

  puts instrumentationManifest.to_xml
end

dump(YAML.parse(yaml))
