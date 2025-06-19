program Menu;

uses
  Crt, Dos;

type
  { Menu option type }
  PMenuOption = ^TMenuOption;
  TMenuOption = record
    Name: string[40];
    Path: string[80];
    Next: PMenuOption;
  end;

  { Menu type }
  PMenu = ^TMenu;
  TMenu = record
    Title: string[30];
    Options: PMenuOption;
    Next: PMenu;
  end;

var
  Filename: string;
  Ch: Char;
  MenuList: PMenu;
  TopMenu: PMenu;
  OriginalTextColor, OriginalBackgroundColor: Byte;
  GlobalBackgroundColor: Byte;
  GlobalTextColor: Byte;
  GlobalKeyColor: Byte;
  GlobalKeyBackgroundColor: Byte;
  GlobalTitleColor: Byte;
  GlobalTitleBackgroundColor: Byte;

{ Trim whitespace from both ends of a string }
function Trim(S: string): string;
var
  Start, EndPos: integer;
begin
  Start := 1;
  while (Start <= Length(S)) and (S[Start] = ' ') do
    Start := Start + 1;
  
  if Start > Length(S) then
    Trim := ''
  else
  begin
    EndPos := Length(S);
    while (EndPos >= Start) and (S[EndPos] = ' ') do
      EndPos := EndPos - 1;
    Trim := Copy(S, Start, EndPos - Start + 1);
  end;
end;

{ Convert a string to uppercase }
function ToUpper(S: string): string;
var
  I: integer;
  Result: string;
begin
  Result := '';
  for I := 1 to Length(S) do
    Result := Result + UpCase(S[I]);
  ToUpper := Result;
end;

{ Parse a color name and return the corresponding color value }
function ParseColor(ColorName: string): Byte;
var
  UpperColor: string;
begin
  UpperColor := ToUpper(Trim(ColorName));
  if UpperColor = 'BLACK' then ParseColor := 0
  else if UpperColor = 'BLUE' then ParseColor := 1
  else if UpperColor = 'GREEN' then ParseColor := 2
  else if UpperColor = 'CYAN' then ParseColor := 3
  else if UpperColor = 'RED' then ParseColor := 4
  else if UpperColor = 'MAGENTA' then ParseColor := 5
  else if UpperColor = 'BROWN' then ParseColor := 6
  else if UpperColor = 'LIGHTGRAY' then ParseColor := 7
  else if UpperColor = 'DARKGRAY' then ParseColor := 8
  else if UpperColor = 'LIGHTBLUE' then ParseColor := 9
  else if UpperColor = 'LIGHTGREEN' then ParseColor := 10
  else if UpperColor = 'LIGHTCYAN' then ParseColor := 11
  else if UpperColor = 'LIGHTRED' then ParseColor := 12
  else if UpperColor = 'LIGHTMAGENTA' then ParseColor := 13
  else if UpperColor = 'YELLOW' then ParseColor := 14
  else if UpperColor = 'WHITE' then ParseColor := 15
  else ParseColor := 7; { Default to light gray if unknown }
end;

{ Clear the screen with menu colors }
procedure ClearScreenWithMenuColors;
begin
  TextBackground(GlobalBackgroundColor);
  TextColor(GlobalTextColor);
  ClrScr;
end;

{ Clear the screen with (saved) original colors }
procedure ClearScreenWithOriginalColors;
begin
  TextBackground(OriginalBackgroundColor);
  TextColor(OriginalTextColor);
  ClrScr;
end;

{ Load a menu file from disk }
procedure LoadMenuFile(MenuFilename: string);
var
  CurrentMenu: PMenu;
  CurrentOption: PMenuOption;
  Line: string;
  BracketPos, EqualPos: integer;
  MenuTitle: string;
  OptionName, OptionPath: string;
  LineNum: integer;
  TempMenu: PMenu;
  TempOption: PMenuOption;
  F: Text;
  ErrorCode: integer;
  MenuCount: integer;
  OptionCount: integer;
  StopReading: Boolean;
  UpperPath: string;
begin
  { Check if the file has an .ini extension }
  if (Pos('.INI', MenuFilename) = 0) then
  begin
    Writeln('Error: File must have a .INI extension');
    Writeln('Provided: ', MenuFilename);
    Halt(2);
  end;
  
  { Check if file exists }
  Assign(F, MenuFilename);
  {$I-}  { Turn off I/O checking }
  Reset(F);
  {$I+}  { Turn on I/O checking }
  ErrorCode := IOResult;
  
  if ErrorCode <> 0 then
  begin
    Writeln('Error: File not found');
    Writeln('Filename: ', MenuFilename);
    Halt(3);
  end;
  
  MenuList := nil;
  CurrentMenu := nil;
  LineNum := 0;
  MenuCount := 0;
  OptionCount := 0;
  StopReading := False;
  
  { Initialize global colors with defaults }
  GlobalBackgroundColor := Blue;
  GlobalTextColor := Yellow;
  GlobalKeyColor := White;
  GlobalKeyBackgroundColor := Black;
  GlobalTitleColor := White;
  GlobalTitleBackgroundColor := Blue;
  
  Writeln;
  while (not Eof(F)) and (not StopReading) do
  begin
    Readln(F, Line);
    LineNum := LineNum + 1;
    
    { Skip empty lines and comments }
    if (Length(Line) > 0) and (Line[1] <> '#') then
    begin
      { Check if this is a menu section [Title] }
      if (Length(Line) > 2) and (Line[1] = '[') then
      begin
        { Check if we've reached the maximum number of menus }
        if MenuCount >= 12 then
        begin
          Writeln;
          Writeln('Warning: Maximum of 12 menus reached. Stopping file read.');
          StopReading := True;
        end
        else
        begin
          BracketPos := Pos(']', Line);
          if BracketPos > 2 then
          begin
            MenuTitle := Copy(Line, 2, BracketPos - 2);
            
            { Start new line for new menu when showing load progress }
            if CurrentMenu <> nil then Writeln;
            Write(MenuTitle, ' ');
            
            { Create new menu }
            New(CurrentMenu);
            CurrentMenu^.Title := MenuTitle;
            CurrentMenu^.Options := nil;
            CurrentMenu^.Next := nil;
            
            { Link to menu list }
            if MenuList = nil then
              MenuList := CurrentMenu
            else
            begin
              { Find end of menu list and add it there }
              TempMenu := MenuList;
              while TempMenu^.Next <> nil do
                TempMenu := TempMenu^.Next;
              TempMenu^.Next := CurrentMenu;
            end;
            
            MenuCount := MenuCount + 1;
            OptionCount := 0;  { Reset option count for new menu }
          end;
        end;
      end
      else
      begin
        { Check if this is a global property (BACK=, TEXT=, KEYS=) before any menu section }
        EqualPos := Pos('=', Line);
        if (EqualPos > 1) and (CurrentMenu = nil) then
        begin
          OptionName := Trim(Copy(Line, 1, EqualPos - 1));
          OptionPath := Trim(Copy(Line, EqualPos + 1, Length(Line) - EqualPos));
          
          { Parse global color properties }
          if ToUpper(OptionName) = 'TITLE' then 
          begin
            { Parse "textcolor on backgroundcolor" format }
            UpperPath := ToUpper(OptionPath);
            if Pos(' ON ', UpperPath) > 0 then
            begin
              GlobalTitleColor := ParseColor(Trim(Copy(OptionPath, 1, Pos(' ON ', UpperPath) - 1)));
              GlobalTitleBackgroundColor := ParseColor(Trim(Copy(OptionPath, Pos(' ON ', UpperPath) + 4, Length(OptionPath))));
            end;
          end
          else if ToUpper(OptionName) = 'TEXT' then 
          begin
            { Parse "textcolor on backgroundcolor" format }
            UpperPath := ToUpper(OptionPath);
            if Pos(' ON ', UpperPath) > 0 then
            begin
              GlobalTextColor := ParseColor(Trim(Copy(OptionPath, 1, Pos(' ON ', UpperPath) - 1)));
              GlobalBackgroundColor := ParseColor(Trim(Copy(OptionPath, Pos(' ON ', UpperPath) + 4, Length(OptionPath))));
            end;
          end
          else if ToUpper(OptionName) = 'KEYS' then 
          begin
            { Parse "textcolor on backgroundcolor" format }
            UpperPath := ToUpper(OptionPath);
            if Pos(' ON ', UpperPath) > 0 then
            begin
              GlobalKeyColor := ParseColor(Trim(Copy(OptionPath, 1, Pos(' ON ', UpperPath) - 1)));
              GlobalKeyBackgroundColor := ParseColor(Trim(Copy(OptionPath, Pos(' ON ', UpperPath) + 4, Length(OptionPath))));
            end;
          end;
        end
        else if (EqualPos > 1) and (CurrentMenu <> nil) then
        begin
          { Check if we've reached the maximum number of options for this menu }
          if OptionCount >= 12 then
          begin
            { Skip this option and continue reading for next menu }
            { Continue is handled by the loop structure }
          end
          else
          begin
            OptionName := Trim(Copy(Line, 1, EqualPos - 1));
            OptionPath := Trim(Copy(Line, EqualPos + 1, Length(Line) - EqualPos));
            
            { Show dot for each option to indicate loading progress }
            Write('.');
            
            { Create new option }
            New(CurrentOption);
            CurrentOption^.Name := OptionName;
            CurrentOption^.Path := OptionPath;
            CurrentOption^.Next := nil;
            
            { Link to menu options }
            if CurrentMenu^.Options = nil then
              CurrentMenu^.Options := CurrentOption
            else
            begin
              { Find end of options list and add it there }
              TempOption := CurrentMenu^.Options;
              while TempOption^.Next <> nil do
                TempOption := TempOption^.Next;
              TempOption^.Next := CurrentOption;
            end;
            
            OptionCount := OptionCount + 1;
          end;
        end;
      end;
    end;
  end;
  
  Close(F);
  Writeln;
  Writeln;
end;

{ Show an option with a single character prefix }
procedure ShowOption(Letter: Char; Text: string);
begin
  Write(' ');
  TextColor(GlobalKeyColor);
  TextBackground(GlobalKeyBackgroundColor);
  Write(' ', Letter, ' ');
  TextColor(GlobalTextColor);
  TextBackground(GlobalBackgroundColor);
  Writeln(' ', Text);
end;

{ Display a menu (or submenu) }
procedure DisplayMenu(MenuToDisplay: PMenu);
var
  CurrentOption: PMenuOption;
  OptionKey: Char;
  UserChoice: Char;
  ValidChoice: Boolean;
  MaxOption: Char;
  Done: Boolean;
  SelectedOption: PMenuOption;
  OptionIndex: Integer;
  TargetMenu: PMenu;
begin
  Done := False;

  { Display the menu until the user quits }
  while not Done do
  begin
    { Show the menu title }
    ClearScreenWithMenuColors;
    Writeln;
    TextColor(GlobalTitleColor);
    TextBackground(GlobalTitleBackgroundColor);
    Writeln(' ', ToUpper(MenuToDisplay^.Title));
    TextColor(GlobalTextColor);
    TextBackground(GlobalBackgroundColor);
    Writeln;
    
    { Display options with single character prefix }
    CurrentOption := MenuToDisplay^.Options;
    OptionKey := 'A';
    while CurrentOption <> nil do
    begin
      ShowOption(OptionKey, CurrentOption^.Name);
      CurrentOption := CurrentOption^.Next;
      OptionKey := Succ(OptionKey);
    end;
    
    { Calculate the maximum option key (one before the last used) }
    MaxOption := Pred(OptionKey);
    
    { Show the user a prompt }
    Writeln;
    if MenuToDisplay = TopMenu then
    begin
      ShowOption('Q', 'Quit');
    end else begin
      ShowOption('Q', 'Back');
    end;
    Writeln;
    Write(' Your choice? ');
    
    { Loop waiting for valid key }
    repeat
      UserChoice := ReadKey;
      { Convert Escape key to Q }
      if UserChoice = #27 then UserChoice := 'Q'
      else UserChoice := UpCase(UserChoice);  { Always uppercase }
      ValidChoice := (UserChoice = 'Q') or ((UserChoice >= 'A') and (UserChoice <= MaxOption));
      
      if not ValidChoice then
      begin
        Sound(440);  { 440 Hz = A note }
        Delay(100);  { Duration in milliseconds }
        NoSound;
      end;
    until ValidChoice;
    
    { Handle the choice - only Q/Escape exits the loop }
    if UserChoice = 'Q' then
    begin
      Done := True;
    end
    else
    begin
      { Find the selected option }
      OptionIndex := Ord(UserChoice) - Ord('A');
      SelectedOption := MenuToDisplay^.Options;
      while (OptionIndex > 0) and (SelectedOption <> nil) do
      begin
        SelectedOption := SelectedOption^.Next;
        OptionIndex := OptionIndex - 1;
      end;
      
      { Action the selected option }
      if SelectedOption <> nil then
      begin
        { Check if this is a submenu (TopMenu) or a command entry }
        if MenuToDisplay = TopMenu then
        begin
          { This is the TopMenu - find the corresponding submenu }
          TargetMenu := MenuList;
          while (TargetMenu <> nil) and (TargetMenu^.Title <> SelectedOption^.Name) do
            TargetMenu := TargetMenu^.Next;
          
          if TargetMenu <> nil then
          begin
            { Recursively display the submenu }
            DisplayMenu(TargetMenu);
          end;
        end
        else
        begin
          { This is a submenu - execute the command }
          ClearScreenWithOriginalColors;
          Writeln(SelectedOption^.Name);
          Writeln(SelectedOption^.Path);
          Writeln;
          Writeln('COMSPEC: ', GetEnv('COMSPEC'));
          Writeln;
          Writeln('Free Memory: ', MemAvail, ' bytes (', MemAvail div 1024, 'K)');
          Writeln('Largest Block: ', MaxAvail, ' bytes (', MaxAvail div 1024, 'K)');
          Writeln;
          Write('Executing command ... ');
          
          { Execute the command using DOS shell }
          SwapVectors;
          Exec(GetEnv('COMSPEC'), '/C ' + SelectedOption^.Path);
          SwapVectors;
          
          { Check if execution was successful }
          if DosError = 0 then
            Writeln('Command completed successfully.')
          else
          begin
            Writeln('Command execution failed.');
            case DosError of
              2: Writeln('[2] File/path not found');
              3: Writeln('[3] Path not found');
              4: Writeln('[4] Too many files open (no handles left)');
              5: Writeln('[5] Access denied');
              8: Writeln('[8] Not enough memory to load program');
              10: Writeln('[10] Illegal environment (greater than 32K)');
              11: Writeln('[11] Illegal .EXE file format');
              32: Writeln('[32] Sharing violation');
              33: Writeln('[33] Lock violation');
            end;
          end;
          
          Writeln;
          Write('Press any key to continue ... ');
          Ch := ReadKey;
        end;
      end;
    end;
  end;
end;

{ Create the TopMenu by adding each loaded menu as an option }
procedure CreateTopMenu;
var
  CurrentMenu: PMenu;
  CurrentOption: PMenuOption;
  TempOption: PMenuOption;
  MenuKey: Char;
begin
  New(TopMenu);
  TopMenu^.Title := 'Menus';
  TopMenu^.Options := nil;
  TopMenu^.Next := nil;
  
  { Add each loaded menu as an option }
  CurrentMenu := MenuList;
  MenuKey := 'A';
  
  while CurrentMenu <> nil do
  begin
    { Create new option for this menu }
    New(CurrentOption);
    CurrentOption^.Name := CurrentMenu^.Title;
    CurrentOption^.Path := '';  { Not used for menu navigation }
    CurrentOption^.Next := nil;
    
    { Link to TopMenu options }
    if TopMenu^.Options = nil then
      TopMenu^.Options := CurrentOption
    else
    begin
      { Find end of options list and add there }
      TempOption := TopMenu^.Options;
      while TempOption^.Next <> nil do
        TempOption := TempOption^.Next;
      TempOption^.Next := CurrentOption;
    end;
    
    CurrentMenu := CurrentMenu^.Next;
    MenuKey := Succ(MenuKey);
  end;
end;

begin
  { Save original colors }
  OriginalTextColor := TextAttr and $0F;
  OriginalBackgroundColor := (TextAttr shr 4) and $0F;
  ClearScreenWithOriginalColors;
  
  { Check if filename was provided as command line argument }
  if ParamCount = 0 then
  begin
    { No filename provided - display instructions }
    Writeln('MENU');
    Writeln('Copyright 2025 K Cartlidge');
    Writeln;
    Writeln('Usage:  menu <menu-file>');
    Writeln;
    Writeln('The menu file must be an .INI file');
    Writeln('where each section is a menu and each');
    Writeln('item is an option within that menu.');
    Writeln('Up to 12 menus of up to 12 options each.');
    Writeln;
    Writeln('  # My menu file');
    Writeln;
    Writeln('  [Games]');
    Writeln('  Elite+ = C:\GAMES\ELITE');
    Writeln('  Prince of Persia = C:\GAMES\PRINCE');
    Writeln;
    Writeln('The file must use CRLF line endings.');
    Writeln;
    Writeln;
    Write('Press any key to continue ... ');
    Ch := ReadKey;
    Halt(1);
  end
  else
  begin
    { Load the menu file (validation handled inside) }
    Filename := ToUpper(ParamStr(1));
    Writeln('Loading menu file: ', Filename);
    LoadMenuFile(Filename);
    
    { Create and display the TopMenu }
    CreateTopMenu;
    if TopMenu <> nil then DisplayMenu(TopMenu);
  end;
  
  ClearScreenWithOriginalColors;
end. 