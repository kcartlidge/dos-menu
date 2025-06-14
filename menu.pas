program Menu;

uses
  Crt, Dos;

type
  PMenuOption = ^TMenuOption;
  TMenuOption = record
    Name: string[40];
    Path: string[80];
    Next: PMenuOption;
  end;

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
begin
  { Check if file has .ini extension }
  if (Pos('.ini', MenuFilename) = 0) and (Pos('.INI', MenuFilename) = 0) then
  begin
    Writeln('Error: File must have .ini extension');
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
  Writeln; { Blank line before first menu }
  
  while not Eof(F) do
  begin
    Readln(F, Line);
    LineNum := LineNum + 1;
    
    { Skip empty lines and comments }
    if (Length(Line) > 0) and (Line[1] <> '#') then
    begin
      { Check if this is a menu section [Title] }
      if (Length(Line) > 2) and (Line[1] = '[') then
      begin
        BracketPos := Pos(']', Line);
        if BracketPos > 2 then
        begin
          MenuTitle := Copy(Line, 2, BracketPos - 2);
          
          { Start new line for new menu }
          if CurrentMenu <> nil then
            Writeln;
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
            { Find end of menu list and add there }
            TempMenu := MenuList;
            while TempMenu^.Next <> nil do
              TempMenu := TempMenu^.Next;
            TempMenu^.Next := CurrentMenu;
          end;
        end;
      end
      else
      begin
        { Check if this is a menu option (contains =) }
        EqualPos := Pos('=', Line);
        if (EqualPos > 1) and (CurrentMenu <> nil) then
        begin
          OptionName := Trim(Copy(Line, 1, EqualPos - 1));
          OptionPath := Trim(Copy(Line, EqualPos + 1, Length(Line) - EqualPos));
          
          { Show dot for each option }
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
            { Find end of options list and add there }
            TempOption := CurrentMenu^.Options;
            while TempOption^.Next <> nil do
              TempOption := TempOption^.Next;
            TempOption^.Next := CurrentOption;
          end;
        end;
      end;
    end;
  end;
  
  Close(F);
  Writeln; { New line at end of loading }
  Writeln; { Blank line after last menu }
end;

procedure DisplayMenu(MenuToDisplay: PMenu);
var
  CurrentOption: PMenuOption;
  OptionKey: Char;
  UserChoice: Char;
  ValidChoice: Boolean;
  MaxOption: Char;
  Done: Boolean;
begin
  Done := False;
  
  while not Done do
  begin
    ClrScr;  { Clear the screen }
    
    { Display menu title (one line down and one character indented) }
    Writeln;
    Writeln(' ', MenuToDisplay^.Title);
    Writeln;  { Blank line }
    
    { Display options with single character prefix }
    CurrentOption := MenuToDisplay^.Options;
    OptionKey := 'A';
    while CurrentOption <> nil do
    begin
      Writeln(' ', OptionKey, ' - ', CurrentOption^.Name);
      CurrentOption := CurrentOption^.Next;
      OptionKey := Succ(OptionKey);
    end;
    
    { Calculate the maximum option key (one before the last used) }
    MaxOption := Pred(OptionKey);
    
    Writeln;  { Blank line }
    Writeln(' Q - Quit');
    Writeln;  { Blank line }
    Write('Your choice? ');  { No CR/LF, just the prompt }
    
    { Loop waiting for valid key }
    repeat
      UserChoice := UpCase(ReadKey);  { Read key and convert to uppercase }
      ValidChoice := (UserChoice = 'Q') or ((UserChoice >= 'A') and (UserChoice <= MaxOption));
      
      if not ValidChoice then
      begin
        { Invalid choice - just wait for another key }
        { Could add a beep or other feedback here }
      end;
    until ValidChoice;
    
    { Handle the choice - only Q exits the loop }
    if UserChoice = 'Q' then
    begin
      Done := True;  { Exit the outer loop }
    end
    else
    begin
      { Valid option selected but not implemented - loop will redisplay menu }
    end;
  end;
end;

procedure CreateTopMenu;
var
  CurrentMenu: PMenu;
  CurrentOption: PMenuOption;
  TempOption: PMenuOption;
  MenuKey: Char;
begin
  { Create the TopMenu }
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
  ClrScr;  { Clear the screen using TP5 library method }
  
  { Check if filename was provided as command line argument }
  if ParamCount = 0 then
  begin
    { No filename provided - display instructions }
    Writeln('MENU - An MSDOS menu system');
    Writeln;
    Writeln('Usage:');
    Writeln('  menu <menu-file>');
    Writeln;
    Writeln('The menu file must be in .ini format');
    Writeln('Example: menu example.ini');
    Writeln;
    Write('Press any key to continue ... ');
    Ch := ReadKey;
    Halt(1);
  end
  else
  begin
    { Filename provided - get it from command line }
    Filename := ParamStr(1);
    
    { Load the menu file (validation handled inside) }
    Writeln('Loading menu file: ', Filename);
    LoadMenuFile(Filename);
    
    { Create the TopMenu with all loaded menus as options }
    CreateTopMenu;
    
    { Display the TopMenu }
    if TopMenu <> nil then
      DisplayMenu(TopMenu);
  end;
  
  ClrScr;  { Clear the screen when exiting }
end. 