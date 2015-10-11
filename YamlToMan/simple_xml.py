class Node:
    def __init__(self, type, **kwargs):
        self.type = type
        self.attributes = []
        self.children = []

        self.attrs(**kwargs)

    def add(self, thing, **kwargs):
        if (isinstance(thing, str)):
            return self.add(Node(thing, **kwargs))

        self.children.append(thing)
        return thing

    def attr(self, name, val):
        if val == None:
            return

        val_str = None
        if isinstance(val, bool):
            val_str = "true" if val else "false"
        else:
            val_str = str(val)

        self.attributes.append((name, val_str))

    def attrs(self, *attrs, **kwargs):
        for a in attrs:
            if isinstance(a, dict):
                for k in a:
                    self.attr(k, a[k])

        for k in kwargs:
            self.attr(k, kwargs[k])

    def to_xml_document(self, **kwargs):
        new_line = kwargs.get("new_line", "\n")
        xml = "<?xml version='1.0' encoding='utf-8' standalone='yes'?>"
        return xml + new_line + self.to_xml(**kwargs)

    def to_xml(self, **kwargs):
        tab = kwargs.get("tab", "  ")
        line_start = kwargs.get("line_start", "")
        new_line = kwargs.get("new_line", "\n")

        new_kwargs = kwargs
        new_kwargs["line_start"] = line_start + tab

        children = [c.to_xml(**new_kwargs) for c in self.children ]

        str = line_start + self.opening_xml(close = not children) + new_line

        if children:
            str += "".join(children) + line_start + self.closing_xml() + new_line

        return str

    def opening_xml(self, **kwargs):
        attributes = " ".join(["{}=\"{}\"".format(k[0], self.escape(k[1])) for k in sorted(self.attributes) ])
        if len(attributes):
            attributes = " " + attributes

        closer = ""
        if kwargs["close"]:
            closer = '/'
        return "<{}{}{}>".format(self.type, attributes, closer)

    def closing_xml(self):
        return "</{}>".format(self.type)

    def escape(self, value):
        items = {
            '"': '&quot;',
            "'": '&apos;',
            '<': '&lt;',
            '>': '&gt;',
            '&': '&amp;'
        }

        out = value
        for k in items:
            out = out.replace(k, items[k])
        return out
