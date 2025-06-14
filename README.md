# MENU - An MSDOS menu system

Standalone EXE built from Turbo Pascal 5 source.

## Usage

``` dos
menu <menu-file>
```

The menu file is in a `.ini` format, with contents as per the example below.

## Example Menu File

``` ini
# Example INI file for the menu program

[Applications]
Word Perfect 4.2  = c:\wp42\wp.exe
Dataease 4.53     = c:\dataease\deasel
Lotus 1-2-3       = c:\lotus\123.exe
dBase III Plus    = c:\dbase\dbase.exe

[Games]
Elite+  = c:\games\elite\elite.exe
Digger  = c:\games\digger\digger.exe

[Development]
Turbo Pascal 5         = c:\dev\tp5\turbo.exe
JPI TopSpeed Modula-2  = c:\dev\jpi\m2.exe
MASM 5.0              = c:\dev\masm\masm.exe

[Utilities]
Norton Utilities  = c:\utils\norton\nu.exe
PC Tools          = c:\utils\pctools\pctools.exe
SideKick Plus     = c:\utils\sidekick\sk.exe
ProComm Plus      = c:\utils\procomm\procomm.exe
```

- Lining up the `=` is not required, but helps visually
- Menus are displayed in the order they appear
- Menu items within menus are also displayed in the order they appear

## Limitations

Due to screen real-estate concerns, the following limits apply:

- No more than 12 menus
- No more than 12 items per menu

## Child Menus

This is an edge case for my own usage so I haven't implemented it (yet).
