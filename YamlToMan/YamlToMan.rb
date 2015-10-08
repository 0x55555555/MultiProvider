require 'yaml'

yaml = %{
providers:
  test:
    events:
      start:
        data:
        - time: std::uint64_t
        - time2: std::uint8_t
      stop:
  test2:
    events:
      start:
        data:
        - time: std::uint64_t
        - time2: std::uint8_t
      stop:
}

class Node
  def initialize(name)
    @name = name
    @attributes = { }
    @children = []
  end

  def <<(node)
    if (node.is_a?(Symbol))
      node = Node.new(node)
    end

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
    return "<#{@name} #{attributes}>"
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

  top_events = instrumentation.add(:events)
  top_events.xmlns = "http://schemas.microsoft.com/win/2004/08/events"

  providers.each do |name, contents|
    provider = top_events.add(:provider)
    provider.guid = "{231CF54B-22A0-49E4-A59A-47052A30FFED}"
    provider.name = "Multi-Main"
    provider.symbol = "MULTI_MAIN"
    provider.messageFileName = "%temp%\TT_Api.dll"
    provider.resourceFileName = "%temp%\TT_Api.dll"

    events = contents["events"]

    #puts name, events
  end

  puts instrumentationManifest.to_xml
end

dump(YAML.parse(yaml))
