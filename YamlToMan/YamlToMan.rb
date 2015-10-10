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
        p.guid = "{231CF54B-22A0-49E4-A59A-47052A30FFED}"
        p.name = "Multi-Main"
        p.symbol = "MULTI_MAIN"
        p.messageFileName = "%temp%\TT_Api.dll"
        p.resourceFileName = "%temp%\TT_Api.dll"

        events = contents["events"]

        p.add(:templates) do |t|
          t.add(:template) do |t|
            t.tid = "T_Start"

            t.add(:data) do |d|
              d.inType = "win:AnsiString"
              d.name="Description"
            end
          end
        end
        p.add(:keywords) do |k|
          k.add(:keyword) do |k|
            k.name = "HighFrequency"
            k.mask = "0x2"
          end
        end

        p.add(:opcodes) do |o|
          o.add(:opcode) do |o|
            o.name = "Begin"
            o.symbol = "_BeginOpcode"
            o.value = "10"
            o.message = "message"
          end
        end

        p.add(:tasks) do |t|
          t.add(:task) do |t|
            t.name = "Block"
            t.symbol = "Block_Task"
            t.value = "1"
            t.eventGUID = "{4E9A75EB-4FBA-4BA0-9A1B-2175B671A16D}"
            t.message = "message"
          end
        end

        p.add(:events) do |e|
          e.add(:event) do |e|
            e.symbol = "Start"
            e.template = "T_Start"
            e.value = "100"
            e.task = "Block"
            e.opcode = "Begin"
            e.keywords = "NormalFrequency"
            e.message = "message"
          end
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
  wprp.Author="Bruce Dawson"
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
#to_wprp(YAML.parse(yaml))
