Generating Event Manifests
==========================

You'll need the Windows SDK installed to generate and edit the .man files.

Editing man files
-----------------

Use ECManGen.exe

https://msdn.microsoft.com/en-us/library/windows/desktop/dd996930(v=vs.85).aspx

Specifying the location of messageFileName and resourceFileName in the .man file is how the WPA application finds the event meta information for the UI.

Compiling man files
-------------------

Use mc.exe to generate header and resource files from the man file.

https://msdn.microsoft.com/en-us/library/windows/desktop/aa385638(v=vs.85).aspx

> # -um option generates function calls to record the events
>
> mc -um man_file.man

Installing the manifest
-----------------------

Use the following command to install the manifest on a machine
> wevtutil im man_file.man

Use the following command to remove the manifest from a machine
> wevtutil im man_file.man

Recording the correct providers
-------------------------------

Generate a .wprp file in order to add the providers to WPR and select them for recording.
