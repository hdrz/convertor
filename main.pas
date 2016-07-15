{ Convertor - A free & open sorce unit converter

  Copyright (C) 2012 H. Raz hadaraz@gmail.com

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}
unit main;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Forms, Controls, Dialogs, StdCtrls, Menus, ExtCtrls, IniPropStorage,
  Buttons, Classes, types, LResources, ClipBrd, fpexprpars2, unit1;

type

  { TForm1 }

  TForm1 = class(TForm)
    Edit1: TEdit;
    Edit2: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    IniFile: TIniPropStorage;
    AutoClose: TMenuItem;
    Panel1: TPanel;
    arrow: TImage;
    Toggle: TSpeedButton;
    U1: TStaticText;
    U2: TStaticText;
    CatListBox: TListBox;
    UnitListBox: TListBox;
    Panel2: TPanel;
    StayOnTop: TMenuItem;
    About: TMenuItem;
    PopupMenu1: TPopupMenu;
    SysTrayIcon: TTrayIcon;
    procedure AboutClick(Sender: TObject);
    procedure CatListBoxMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: integer);
    procedure CatListBoxMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure EditEditingDone(Sender: TObject);
    procedure EditChange(Sender: TObject);
    procedure EditEnter(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormWindowStateChange(Sender: TObject);
    procedure IniFileRestoreProperties(Sender: TObject);
    procedure AutoCloseClick(Sender: TObject);
    procedure StayOnTopClick(Sender: TObject);
    procedure SysTrayIconClick(Sender: TObject);
    procedure ToggleChange(Sender: TObject);
    procedure UnitListBoxContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: boolean);
    procedure UnitListBoxMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: integer);
    procedure UnitListBoxMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure ChangeValue;
    procedure ChooseUnit(UCat: TUnitCategory; i: integer; side: string);
    procedure ToggleUnitsPanel(shw: shortstring);
  private
    { private declarations }
    FExpParser: TFPExpressionParser;
    FParserResult: TFPExpressionResult;
    FFromVal: TEdit;
    FToVal: TEdit;
    FFromUnit: TUnitData;
    FToUnit: TUnitData;
    FUCat: TUnitCategory;
  public
    { public declarations }
  end;

const
  cABOUT =
    'Convertor is a free unit converter.' + sLineBreak +
    'By H. Raz ©2016' + sLineBreak +
    'http://www.moosht.org/convertor' + sLineBreak +
    sLineBreak +
    'Simple expressions are supported:' + sLineBreak +
    '  +, -, *, /,' + sLineBreak +
    '  cos, sin, arctan, abs, sqr, sqrt, exp,' + sLineBreak +
    '  ln, log, frac, int, round, trunc' + sLineBreak +
    '  Angles are in radians.' + sLineBreak +
    sLineBreak +
    'Using:' + sLineBreak +
    ' - Up && Down blue arrows by' + sLineBreak +
    '   Yusuke Kamiyamane (CC BY 3.0)' + sLineBreak +
    ' - Other icons by RRZE (CC BY-SA 3.0)';

var
  Form1: TForm1;
  ActiveSide: string;  // 'left' or 'right'
  Shrink: boolean;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormWindowStateChange(Sender: TObject);
// change visibility of window and tray icon
begin
  if Form1.WindowState = wsMinimized then
  begin
    Form1.WindowState := wsMinimized;
    Form1.Hide;
    SysTrayIcon.Show;
  end
  else
  begin
    Form1.WindowState := wsNormal;
    Form1.Show;
    SysTrayIcon.Hide;
  end;
end;

procedure TForm1.AboutClick(Sender: TObject);
// about message
begin
  ShowMessage(cABOUT);
end;

procedure TForm1.CatListBoxMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: integer);
// show hints for categories
var
  Item: integer;
begin
  Item := CatListBox.ItemAtPos(Point(X, Y), True);
  if item >= 0 then
    CatListBox.Hint := CatListBox.Items[item]
  else
    CatListBox.Hint := '';
end;

procedure TForm1.CatListBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
// select unit category, show units in list
var
  i: integer;
  Ucat: TUnitCategory;
begin
  i := CatListBox.GetIndexAtY(Y);
  if (i >= 0) and (Button = mbLeft) then
  begin
    UCat := (CatList.Objects[i] as TUnitCategory);
    UnitListBox.Items := UCat.UnitList;
    Form1.Caption := UCat.Name + ' Convertor';
    ChooseUnit(UCat, UCat.LIndx, 'L');
    ChooseUnit(UCat, UCat.RIndx, 'R');
    IniFile.StoredValue['activecat'] := IntToStr(i);
  end;
end;

procedure TForm1.EditEditingDone(Sender: TObject);
// copy result to clipboard
begin
  if ActiveSide = 'left' then
    Clipboard.AsText := Edit2.Text
  else
    Clipboard.AsText := Edit1.Text;
end;

procedure TForm1.EditChange(Sender: TObject);
// convert one value to the other
begin
  ChangeValue;
end;

procedure TForm1.EditEnter(Sender: TObject);
// hide the lists when typing
begin
  if Shrink then
  begin
    ToggleUnitsPanel('hide');
  end;
  if Form1.ActiveControl.Name = 'Edit1' then
  begin
    arrow.Picture.LoadFromLazarusResource('right');
    ActiveSide := 'left';
  end
  else
  begin
    arrow.Picture.LoadFromLazarusResource('left');
    ActiveSide := 'right';
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  // read the .xml file and populate the string lists
  UnitInit;
  // show categories
  CatListBox.Items := CatList;
  CatListBox.Selected[0] := True;
  arrow.Picture.LoadFromLazarusResource('right');
  Toggle.LoadGlyphFromLazarusResource('up');
  ActiveSide := 'left';
  Shrink := False;
  FExpParser := TFPExpressionParser.Create(nil);
  FExpParser.Builtins := [bcMath];
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FExpParser.Free;
end;


procedure TForm1.IniFileRestoreProperties(Sender: TObject);
// restore application properties from .ini file
var
  UCat: TUnitCategory;
begin
  if StrToBool(IniFile.StoredValue['ontop']) then
  begin
    Form1.formstyle := fsSystemStayOnTop;
    StayOnTop.Checked := True;
  end
  else
  begin
    Form1.formstyle := fsNormal;
  end;
  Shrink := StrToBool(IniFile.StoredValue['shrink']);
  AutoClose.Checked := Shrink;
  if not StrToBool(IniFile.StoredValue['unitsopen']) then
    ToggleUnitsPanel('hide');
  Edit1.Text := IniFile.StoredValue['value'];
  CatListBox.Selected[StrToInt(IniFile.StoredValue['activecat'])] := True;
  UCat := (CatListBox.Items.Objects[CatListBox.ItemIndex] as TUnitCategory);
  UnitListBox.Items := UCat.UnitList;
  ChooseUnit(UCat, StrToInt(IniFile.StoredValue['leftunit']), 'L');
  ChooseUnit(UCat, StrToInt(IniFile.StoredValue['rightunit']), 'R');
  {SpecialDate;  // change dialogs if special date..}
end;

procedure TForm1.AutoCloseClick(Sender: TObject);
begin
  Shrink := not Shrink;
  IniFile.StoredValue['shrink'] := BoolToStr(Shrink);
end;

procedure TForm1.StayOnTopClick(Sender: TObject);
// toggle the 'stay on top' state
begin
  if Form1.FormStyle = fsSystemStayOnTop then
  begin
    Form1.formstyle := fsNormal;
    IniFile.StoredValue['ontop'] := BoolToStr(False);
  end
  else
  begin
    Form1.formstyle := fsSystemStayOnTop;
    IniFile.StoredValue['ontop'] := BoolToStr(True);
  end;
end;

procedure TForm1.SysTrayIconClick(Sender: TObject);
// restore application from the tray icon
begin
  Form1.WindowState := wsNormal;
  Form1.Show;
  SysTrayIcon.Hide;
end;

procedure TForm1.ToggleChange(Sender: TObject);
// show and hide units panel with click
begin
  ToggleUnitsPanel('toggle');
end;

procedure TForm1.UnitListBoxContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: boolean);
// disable popup menu on unit listbox
begin
  Handled := True;
end;

procedure TForm1.UnitListBoxMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: integer);
// show hints for units
var
  item: integer;
  obj: TUnitData;
begin
  item := UnitListBox.GetIndexAtY(Y);
  if item >= 0 then
  begin
    obj := UnitListBox.Items.Objects[item] as TUnitData;
    if obj.Info <> '' then
      UnitListBox.Hint := obj.Info
    else
      UnitListBox.Hint := UnitListBox.Items[item];
  end
  else
    CatListBox.Hint := '';
end;

procedure TForm1.UnitListBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
// select left and right units for conversion
var
  i: integer;
  UCat: TUnitCategory;
  abbr: string;
  side: string;
begin
  UCat := (CatListBox.Items.Objects[CatListBox.ItemIndex] as TUnitCategory);
  i := UnitListBox.GetIndexAtY(Y);
  if i >= 0 then
  begin
    if Button = mbLeft then
    begin
      side := 'L';
      IniFile.StoredValue['leftunit'] := IntToStr(i);
    end
    else if Button = mbRight then
    begin
      side := 'R';
      IniFile.StoredValue['rightunit'] := IntToStr(i);
    end;
    ChooseUnit(UCat, i, side);
  end;
end;

procedure TForm1.ChangeValue;
// convert one value to the other
var
  resultValue: double;
begin
  FUCat := (CatListBox.Items.Objects[CatListBox.ItemIndex] as TUnitCategory);
  if (FUCat.LeftUnit <> nil) and (FUCat.RightUnit <> nil) then
  begin
    if ActiveSide = 'left' then
    begin
      FFromVal := Edit1;
      FToVal := Edit2;
      FFromUnit := FUCat.LeftUnit;
      FToUnit := FUCat.RightUnit;
    end
    else
    begin
      FFromVal := Edit2;
      FToVal := Edit1;
      FFromUnit := FUCat.RightUnit;
      FToUnit := FUCat.LeftUnit;
    end;
    // convert:
    try
      FExpParser.Expression := FFromVal.Text;
      resultValue := ArgToFloat(FExpParser.Evaluate);
      FToVal.Text := FloatToStr(FToUnit.ToUnit(FFromUnit.FromUnit(resultValue)));
    except
      FToVal.Text := '';
    end;
  end;
  IniFile.StoredValue['value'] := Edit1.Text;
end;

procedure TForm1.ChooseUnit(UCat: TUnitCategory; i: integer; side: string);
var
  item: TUnitData;
  abbr: string;
begin
  item := (UnitListBox.Items.Objects[i] as TUnitData);
  if item.abbr <> '' then
    abbr := item.ABBR
  else
    abbr := item.Name;
  if side = 'L' then
  begin
    U1.Caption := abbr;
    if UCat.LeftUnit <> nil then
      UnitListBox.Items[UCat.LIndx] := UCat.LeftUnit.Name;
    UCat.LeftUnit := item;
    UCat.LIndx := i;
    ChangeValue;
  end
  else
  begin
    U2.Caption := abbr;
    (UnitListBox as TCustomListBox).Selected[i] := True;
    if UCat.RightUnit <> nil then
      UnitListBox.Items[UCat.RIndx] := UCat.RightUnit.Name;
    UCat.RightUnit := item;
    UCat.RIndx := i;
    ChangeValue;
  end;
  UnitListBox.Items[i] := item.Name + ' (' + side + ')';
end;

procedure TForm1.ToggleUnitsPanel(shw: shortstring);
// show and hide units panel
begin
  if Panel2.Visible or (shw = 'hide') then
  begin
    Panel2.Hide;
    Toggle.LoadGlyphFromLazarusResource('down');
    IniFile.StoredValue['unitsopen'] := BoolToStr(False);
  end
  else
  begin
    Panel2.Show;
    Toggle.LoadGlyphFromLazarusResource('up');
    IniFile.StoredValue['unitsopen'] := BoolToStr(True);
  end;
end;

// load icons resource file
initialization
  {$I icons.lrs}

end.

