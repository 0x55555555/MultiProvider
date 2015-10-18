import simple_xml as xml
import collections, re, uuid, hashlib

def make_symbol(*args):
    return re.sub('[^0-9A-Z]+', '_', '_'.join(args).upper())

class ManifestBase:
    """
    Base to all nameable objects in the manifest.
    """
    def __init__(self, name):
        self._name = name

    @property
    def name(self):
        """
        Identifier for the object
        """
        return self._name

class Profile(ManifestBase):
    def __init__(self, name, gui_name):
        super().__init__(name)
        self._providers = []
        self._gui_name = gui_name

    def add(self, providers, **kwargs):
        self._providers.append((providers, kwargs))

    @property
    def gui_name(self):
        return self._gui_name

    @property
    def providers(self):
        return self._providers

class Provider(ManifestBase):
    """
    Base object which provides instrumentation for an executable
    """
    def __init__(self, name):
        super().__init__(name)
        self.contents = collections.defaultdict(lambda: [])
        self._next_value = 1

    def add(self, obj):
        container = self.contents[obj.__class__.__name__.lower()]
        container.append(obj)

        obj.assign_value(self._next_value)
        self._next_value += 1

    def container(self, name):
        if (name in self.contents):
            return self.contents[name]

        return []

    @property
    def guid(self):
        m = hashlib.md5()
        m.update(bytearray(self.name, 'utf8'))
        uuid_bytes = m.digest()
        return '{%s}' % uuid.UUID(bytes=uuid_bytes)

    @property
    def binary_filename(self):
        return "%temp%/pork.dll"

class ItemBase(ManifestBase):
    def __init__(self, name, **kwargs):
        super().__init__(name)
        self._message = kwargs.get("message", None)
        self._value = 0

    def assign_value(self, value):
        if hasattr(self.__class__, 'minimum_id'):
            value += self.__class__.minimum_id
        self._value = value

    @property
    def value(self):
        return self._value

    @property
    def message(self):
        return self._message

class Event(ItemBase):
    def __init__(self, name, **kwargs):
        super().__init__(name)

        self._channel = kwargs.get("channel", None)
        self._task = kwargs.get("task", None)
        self._opcode = kwargs.get("opcode", None)
        self._keywords = kwargs.get("keywords", None)
        self._level = kwargs.get("level", None)
        self._template = kwargs.get("template", None)

    @property
    def channel(self):
        return self._channel

    @property
    def task(self):
        return self._task

    @property
    def opcode(self):
        return self._opcode

    @property
    def keywords(self):
        return self._keywords

    @property
    def level(self):
        return self._level

    @property
    def template(self):
        return self._template


class Task(ItemBase):
    def __init__(self, name, **kwargs):
        super().__init__(name)

class Opcode(ItemBase):
    minimum_id = 10

    def __init__(self, name, **kwargs):
        super().__init__(name)

class Keyword(ItemBase):
    def __init__(self, name, **kwargs):
        super().__init__(name)

    @property
    def mask(self):
        return "0x1"

class Filter(ItemBase):
    def __init__(self, name, **kwargs):
        super().__init__(name)

    @property
    def template(self):
        return None

class Level(ItemBase):
    minimum_id = 16

    def __init__(self, name, **kwargs):
        super().__init__(name)

class Template(ItemBase):
    def __init__(self, name, **kwargs):
        super().__init__(name)
        self._data = []

    def add_data(self, name, type):
        self._data.append((name, type))

    @property
    def data(self):
        return self._data

class Channel(ItemBase):
    def __init__(self, name, **kwargs):
        super().__init__(name)
        self._type = kwargs.get("type", "Operational")

    @property
    def enabled(self):
        return True

    @property
    def type(self):
        return self._type

def to_manifest_xml(providers):
    root = xml.Node(
        'instrumentationManifest',
        xmlns = "http://schemas.microsoft.com/win/2004/08/events"
        )

    instrumentation = root.add('instrumentation')
    instrumentation.attrs({
        'xmlns:win': "http://manifests.microsoft.com/win/2004/08/windows/events",
        'xmlns:xs': "http://www.w3.org/2001/XMLSchema",
        'xmlns:xsi': "http://www.w3.org/2001/XMLSchema-instance"
    })

    container_root = instrumentation.add('events')
    container_root.attrs(xmlns = "http://schemas.microsoft.com/win/2004/08/events")

    for p in providers:
        provider = container_root.add('provider',
            name = p.name,
            symbol = make_symbol(p.name),
            guid = p.guid,
            messageFileName = p.binary_filename,
            resourceFileName = p.binary_filename
        )

        def build_container(provider, xml, name, build):
            cnt = p.container(name)
            xml_cnt = provider.add(name + 's')
            for o in cnt:
                xml = xml_cnt.add(name)

                build(xml, o)

        def build_event(xml, evt):
            xml.attrs(
                symbol = make_symbol(p.name, "event", evt.name),
                template = evt.template.name if evt.template else None,
                value = evt.value,
                level = evt.level.name if evt.level else None,
                channel = evt.channel.name if evt.channel else None,
                task = evt.task.name if evt.task else None,
                opcode = evt.opcode.name if evt.opcode else None,
                keywords = evt.keywords.name if evt.keywords else None,
                message = evt.message
            )
        build_container(provider, p, 'event', build_event)

        def build_task(xml, task):
            xml.attrs(
                name = task.name,
                symbol = make_symbol(p.name, "task", task.name),
                value = task.value,
                message = task.message
            )
        build_container(provider, p, 'task', build_task)


        def build_opcode(xml, opcode):
            xml.attrs(
                name = opcode.name,
                symbol = make_symbol(p.name, "opcode", opcode.name),
                value = opcode.value,
                message = opcode.message
            )
        build_container(provider, p, 'opcode', build_opcode)

        def build_keyword(xml, keyword):
            xml.attrs(
                name = keyword.name,
                mask = keyword.mask
            )
        build_container(provider, p, 'keyword', build_keyword)

        def build_filter(xml, filter):
            xml.attrs(
                name = filter.name,
                value = filter.value,
                tid = filter.template.name if filter.template else None,
                symbol = make_symbol(p.name, "filter", filter.name),
            )
        build_container(provider, p, 'filter', build_filter)

        def build_level(xml, level):
            xml.attrs(
                name = level.name,
                value = level.value,
                symbol = make_symbol(p.name, "level", level.name),
                message = level.message
            )
        build_container(provider, p, 'level', build_level)

        def build_channel(xml, channel):
            xml.attrs(
                chid = channel.name,
                name = "{}/{}".format(channel.name, channel.type),
                type = channel.type,
                enabled = channel.enabled
            )
        build_container(provider, p, 'channel', build_channel)

        def build_template(xml, template):
            xml.attrs(
                tid = template.name
            )

            for d in template.data:
                data_xml = xml.add(
                    'data',
                    name = d[0],
                    inType = d[1]
                )

        build_container(provider, p, 'template', build_template)

    return root.to_xml_document()

def to_wprp_xml(profiles):

    wprp = xml.Node("WindowsPerformanceRecorder")
    wprp.attrs(Author = "N/A",
        Comments = "Auto generated",
        Copyright = "",
        Version = "1.0",
        Tag = "Enables providers"
    )

    for profile in profiles:
        description = profile.gui_name
        buffer_size = 64
        buffers = 64

        profiles_xml = wprp.add("Profiles")
        ec = profiles_xml.add("EventCollector",
            Id = profile.name,
            Name = "Sample Event Collector"
        )

        ec.add("BufferSize", Value = buffer_size)
        ec.add("Buffers", Value = buffers)

    detail_levels = [ "Verbose", "Light" ]
    logging_types = [ "Memory", "File" ]

    for profile in profiles:
        for detail_level in detail_levels:
            for logging_type in logging_types:
                collector_name = profile.name + "_Profile"

                p = profiles_xml.add("Profile",
                    Id = "{}.{}.{}".format(collector_name, detail_level, logging_type),
                    Name = collector_name,
                    Description = description,
                    DetailLevel = detail_level,
                    LoggingMode = logging_type
                )

                c = p.add("Collectors")
                eci = c.add("EventCollectorId", Value = profile.name)

                providers_xml = eci.add("EventProviders")
                for p, opts in profile.providers:
                    if opts.get(logging_type.lower(), True) == False:
                        continue

                    if opts.get(detail_level.lower(), True) == False:
                        continue

                    provider_xml = providers_xml.add("EventProvider",
                        Id = p.name + "_Provider",
                        Name = p.name
                    )
    return wprp.to_xml_document()

p = Provider("Multi-Main")

task = Task("task1")
p.add(task)

op = Opcode("opcode")
p.add(op)

kw = Keyword("kw")
p.add(kw)

filter = Filter("fil")
p.add(filter)

lev = Level("lev")
p.add(lev)

templ = Template("cha")
templ.add_data("Description", "win:AnsiString")
p.add(templ)

channel = Channel("kchaw")
p.add(channel)

ev = Event("pork",
    channel = channel,
    task = task,
    opcode = op,
    keywords = kw,
    level = lev,
    template = templ
    )
p.add(ev)

ev = Event("pork2",
    template = templ
    )
p.add(ev)


with open('test.man', 'w') as file:
    file.write(to_manifest_xml([p]))

profile_1 = Profile("General", "Sweet test profile")
profile_1.add(p)

with open('test.wprp', 'w') as file:
    file.write(to_wprp_xml([profile_1]))
