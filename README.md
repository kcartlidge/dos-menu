# MENU - An MSDOS menu system

Standalone EXE built from Turbo Pascal 5 source.

- Copyright 2025 K Cartlidge
- Licensed under the [AGPL](./LICENSE.md)

The [`MENU.EXE`](./MENU.EXE) is standalone, pre-built under Turbo Pascal 5.
A [sample menu](./example.ini) is also available (see details further down).

## Contents

- [Screenshots](#screenshots)
- [Usage](#usage)
- [Example Menu File](#example-menu-file)
- [Important Notes](#important-notes)
- [Limitations](#limitations)

## Screenshots

- Top level showing all your loaded menus
![screenshot1](./screenshot1.png)

- Second level menu showing all the options within one of your loaded menus
![screenshot2](./screenshot2.png)

## Usage

The [`MENU.EXE`](./MENU.EXE) is standalone, pre-built under Turbo Pascal 5.

``` dos
menu <menu-file>
```

The menu file is in a `.ini` format, with contents as per the example below.

## Example Menu File

*A [sample menu](./example.ini) is also available.*

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

## Important Notes

All files in DOS should be saved with CRLF line endings, including your menu file.

When running in the Turbo Pascal 5 IDE the menu system will work but you won't be able to launch a menu option.  This is a limitation of the IDE/DOS; run outside the IDE for launching menu options to work.

If you are building the source yourself in Turbo Pascal 5, change the *Options*, *Compiler*, *Memory Sizes* to reduce the *High* heap size to 65536 or less (I build with 16384).  If you don't, then launching a menu option command will fail as DOS will report insufficient memory.  When that happens it will show you the current memory usage.  Note that this is memory held by the menu system *not* memory available to the called application.  Lower is better; we only need enough for the working set of variables and menus.

## Limitations

Due to screen real-estate concerns, the following limits apply:

- No more than 12 menus
- No more than 12 items per menu
- Only one level of menus supported
  - At 12 * 12 that's still 144 options
