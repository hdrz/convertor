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
unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DOM, XMLRead, Dialogs;

type

  { unit object will be attached to string }
  TUnitData = class(TObject)
  private
    FName: string;
    FLF: double;
    FCF: double;
    FABBR: string;
    FInfo: string;
  public
    property Name: string read FName;
    property LF: double read FLF;
    property CF: double read FCF;
    property ABBR: string read FABBR;
    property Info: string read FInfo;
    function ToUnit(x: double): double;
    function FromUnit(x: double): double;
  end;

  { category will be attached to string, and will hold the relevant
    units inside a TStringList object }
  TUnitCategory = class(TObject)
  private
    FName: string;
    FUnitList: TStringList;
    FLeftUnit: TUnitData;
    FRightUnit: TUnitData;
    FLIndx: integer;
    FRIndx: integer;
  public
    property UnitList: TStringList read FUnitList;
    property Name: string read FName;
    property LeftUnit: TUnitData read FLeftUnit write FLeftUnit;
    property RightUnit: TUnitData read FRightUnit write FRightUnit;
    property LIndx: integer read FLIndx write FLIndx;
    property RIndx: integer read FRIndx write FRIndx;
  end;

procedure UnitInit;


var
  CatList: TStringList;  // global list to hold the categories and units

implementation

function TUnitData.FromUnit(x: double): double;
begin
  Result := x * Self.LF + Self.CF;
end;

function TUnitData.ToUnit(x: double): double;
begin
  Result := (x - Self.CF) / Self.LF;
end;

procedure UnitInit;
var
  Doc: TXMLDocument;
  Child: TDOMNode;
  i, j, k, Childs: integer;
  atr, val: string;
  UCat: TUnitCategory;
  UDat: TUnitData;
begin
  try
    // Read in xml file from disk
    ReadXMLFile(Doc, 'UnitData.xml');
    // process nodes
    Childs := Doc.DocumentElement.ChildNodes.Count;
    CatList := TStringList.Create;
    for i := 0 to (Childs - 1) do
    begin
      Child := Doc.DocumentElement.ChildNodes[i];
      UCat := TUnitCategory.Create;
      UCat.FUnitList := TStringList.Create;
      Ucat.FName := Child.Attributes.Item[0].NodeValue;
      // using ChildNodes method
      with Child.ChildNodes do
      begin
        try
          for j := 0 to (Count - 1) do
          begin
            UDat := TUnitData.Create;
            for k := 0 to (Item[j].Attributes.Length - 1) do
            begin
              atr := Item[j].Attributes.Item[k].NodeName;
              val := AnsiToUTF8(Item[j].Attributes.Item[k].NodeValue);
              case UpCase(atr[1]) of
                'C': UDat.FCF := StrToFloat(val); // cf
                'L': UDat.FLF := StrToFloat(val); // lf
                'I': UDat.FInfo := WrapText(val, 60); // info
                'A': UDat.FABBR := val; // abbr
                'N': UDat.FName := val; // name
                else
                  ShowMessage('Wrong attribute: ' + atr);
              end;
            end;
            if UDat.FInfo <> '' then
              UDat.FName := '(i) ' + UDat.FName;
            UCat.FUnitList.AddObject(UDat.FName, UDat);
          end;
        finally
          Free;
        end;
      end;
      // populate the category list and add the units as objects
      CatList.AddObject(UCat.FName, UCat);
    end;
  finally
    Doc.Free;
    CatList.Sort;
  end;
end;


end.

