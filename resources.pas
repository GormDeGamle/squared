unit resources;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, sdltypes, sdlfonts, consts, tiles;

procedure InitResources;                                                        //<- initialize global resources
procedure FreeResources;

var
  // tiles with numbers on them
  Tile: array[MinTile..MaxTile] of TSquaredTile;

implementation

//******************************************************************************
// helper procedures/functions
//******************************************************************************

procedure CreateTiles;
var
  ii: integer;
  aFont: TSDLFont;
  aX, aY: integer;
begin
  //*** init tiles
  aFont := TSDLFont.Create;
  try
    for ii := MinTile to MaxTile do begin
      Tile[ii] := TSquaredTile.Create;
      Tile[ii].BackgroundColor := Options.TileColor[ii];

      if ii = 1 then begin
        aFont.Size := TemplateLargeFontSize;
        aFont.Load(cTileFont);
        aX := 36;
        ay := 12;
      end;

      if ii = 4 then begin
        aFont.Size := TemplateMediumFontSize;
        aFont.Load(cTileFont);
        aX := 12;
        ay := 20;
      end;

      if ii = 7 then begin
        aFont.Size := TemplateSmallFontSize;
        aFont.Load(cTileFont);
        aX := 8;
        ay := 34;
      end;

      if ii = 10 then begin
        aFont.Size := TemplateSmallestFontSize;
        aFont.Load(cTileFont);
        aX := 8;
        ay := 40;
      end;

      if ii = 14 then begin
        aFont.Size := TemplateTinyFontSize;
        aFont.Load(cTileFont);
        aX := 8;
        ay := 48;
      end;

      aFont.Color := Options.TileFontColor[ii];
      aFont.Rendertype := frtBlended;

      Tile[ii].Clear;
      Tile[ii].WriteText(aX, aY, IntToStr(Trunc(Power(2, ii))), aFont);

      Tile[ii].Update;
    end;
  finally
    aFont.Free;
  end;
end;

procedure FreeTiles;
var
  ii: integer;
begin
  for ii := MinTile to MaxTile do begin
    Tile[ii].Free;
  end;
end;

//******************************************************************************
// interface procedures/functions
//******************************************************************************

procedure InitResources;
begin
  CreateTiles;
end;

procedure FreeResources;
begin
  FreeTiles;
end;

end.

