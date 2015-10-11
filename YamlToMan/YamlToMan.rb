require 'yaml'
require_relative 'SimpleXml'

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

def make_symbol(*args)
  return args.join('_').upcase.tr('^A-Z0-9', '_')
end

def format_list(p, element, list)
  group = (element.to_s + "s").to_sym
  p.add(group) do |c|
    list.each do |element_data|
      c.add(element) do |c|
        yield(c, element_data)
      end
    end
  end
end

def to_man(v)
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
        name = "Multi-Main"
        symbol = make_symbol(name)
        p.guid = "{231CF54B-22A0-49E4-A59A-47052A30FFED}"
        p.name = name
        p.symbol = symbol
        p.messageFileName = "%temp%\TT_Api.dll"
        p.resourceFileName = "%temp%\TT_Api.dll"

        events = contents["events"]

        format_list(p, :channel, [2]) do |c, d|
          type = "Admin"
          c.chid = "c1"
          c.name = "#{name}/#{type}"
          c.type = type
          c.enabled = true
        end

        format_list(p, :template, [2]) do |t, d|
          t.tid = "T_Start"

          t.add(:data) do |d|
            d.inType = "win:AnsiString"
            d.name = "Description"
          end
        end

        format_list(p, :filter, [2]) do |f, d|
          name = "Pid"
          f.name = name
          f.value = "1"
          f.tid = "t1"
          f.symbol = make_symbol(symbol, :filter, name)
        end

        format_list(p, :level, [2]) do |l, d|
          name = "NotValid"
          l.name = name
          l.value = 16 # 16-255
          l.symbol = make_symbol(symbol, :level, name)
          l.message = "message"
        end

        format_list(p, :keyword, [2]) do |k, d|
          k.name = "HighFrequency"
          k.mask = "0x2"
        end

        format_list(p, :opcode, [2]) do |o, d|
          name = "Begin"
          o.name = "Begin"
          o.symbol = make_symbol(symbol, :opcode, name)
          o.value = "10"
          o.message = "message"
        end

        format_list(p, :task, [2]) do |t, d|
          name = "Block"
          t.name = name
          t.symbol = make_symbol(symbol, :task, name)
          t.value = "1"
          t.eventGUID = "{4E9A75EB-4FBA-4BA0-9A1B-2175B671A16D}"
          t.message = "message"
        end


        format_list(p, :event, [2]) do |e, d|
          e.symbol = "Start"
          e.level = "win:Error" # win:Critical win:Error win:Warning win:Informational win:Verbose or NotValid
          e.channel = "c2"
          e.template = "T_Start"
          e.value = "100"
          e.task = "Block"
          e.opcode = "Begin"
          e.keywords = "NormalFrequency"
          e.message = "message"
        end
      end

      #puts name, events
    end
  end

  puts instrumentationManifest.to_xml_document
end

def to_wprp(v)
  data = v.to_ruby

  wprp = Node.new :WindowsPerformanceRecorder
  wprp.Author = "Bruce Dawson"
  wprp.Comments = "Auto generated"
  wprp.Copyright = ""
  wprp.Version = "1.0"
  wprp.Tag = "Enables providers"

  wprp.add(:Profiles) do |p|
    p.add(:EventCollector) do |ec|
      id = 'MultiCollector'
      ec.Id = id
      ec.Name="Sample Event Collector"

      ec.add(:BufferSize) do |bs|
        bs.Value = 64
      end
      ec.add(:Buffers) do |bs|
        bs.Value = 64
      end

      ec.add(:Profile) do |p|
        p.Id = "MultiProvider.Verbose.Memory"
        p.Name = 'MultiProvider'
        p.Description = 'some text'
        p.DetailLevel = 'Verbose'
        p.LoggingMode = 'Memory'

        p.add(:Collectors) do |c|
          c.add(:EventCollectorId) do |ec|
            ec.Value = id

            ec.add(:EventProviders) do |p|
              p.add(:EventProvider) do |p|
                p.Id = "Multi-Main-Provider"
                p.Name = "Multi-Main"
              end
            end
          end
        end
      end
    end
  end

  puts wprp.to_xml_document
end

to_man(YAML.parse(yaml))
to_wprp(YAML.parse(yaml))
