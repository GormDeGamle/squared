unit gui;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, sdl, sdltypes, sdlclasses, sdltools, sdlgui, resources,
  tiles, consts, highscores, inifiles;

type

  //****************************************************************************
  // gui elements for Squared!
  //****************************************************************************

  { TSquaredBasicScoreBox }

  TSquaredBasicScoreBox = class(TScoreBox)
  private
    FOrgPos: TVector2DInt;
    FMoving: TMoving;
    procedure SetMoving(aValue: TMoving);
  public
    constructor Create(aX, aY, aWidth, aHeight: integer; aBackgroundColor: TRGBAColor; aTitle: string; aScreen: TSDLScreen);

    procedure Update; override;

    property OrgPos: TVector2DInt read FOrgPos;
    property Moving: TMoving read FMoving write SetMoving;
  end;

  { TSquaredBasicScoreListBox }

  TSquaredBasicScoreListBox = class(TScoreListBox)
  private
    FOrgPos: TVector2DInt;
    FMoving: TMoving;
    procedure SetMoving(aValue: TMoving);
  public
    constructor Create(aX, aY, aWidth, aHeight: integer; aBackgroundColor: TRGBAColor; aTitle: string; aCount: integer; aScreen: TSDLScreen);

    procedure Update; override;

    property OrgPos: TVector2DInt read FOrgPos;
    property Moving: TMoving read FMoving write SetMoving;
  end;

  { TSquaredTileBox }

  TSquaredTileBox = class(TSquaredBasicScoreBox)
  private
    FTileNumber: integer;
    FTile: TSquaredTile;
  protected
    procedure SetTileNumber(aValue: integer);
  public
    constructor Create(aX, aY, aWidth, aHeight: integer; aBackgroundColor: TRGBAColor; aScreen: TSDLScreen);
    destructor Destroy; override;

    procedure RenderTo(aSurface: TSDLSurface); override;

    procedure UpdateTile;

    procedure SetIfLarger(aTileNumber: integer);                                //<- will show the tile value only if it's larger than the current one
    property TileNumber: integer read FTileNumber write SetTileNumber;
  end;

  { TSquaredScoreBox }

  TSquaredScoreBox = class(TSquaredBasicScoreBox)
  private
    FTileNumber: integer;
    FTile: TSquaredTile;
  protected
    procedure SetScore(aValue: integer); override;
    procedure SetTileNumber(aValue: integer);
  public
    constructor Create(aX, aY, aWidth, aHeight: integer; aBackgroundColor: TRGBAColor; aTitle: string; aScreen: TSDLScreen);
    destructor Destroy; override;

    procedure DoSaveTo(aCfg: TIniFile; aSection, aID: string); override;
    procedure DoLoadFrom(aCfg: TIniFile; aSection, aID: string); override;

    procedure RenderTo(aSurface: TSDLSurface); override;

    procedure UpdateTile;

    procedure SetIfLarger(aTileNumber: integer);                                //<- will show the tile value only if it's larger than the current one
    property TileNumber: integer read FTileNumber write SetTileNumber;
  end;

  { TSquaredScoreListBox }

  TSquaredScoreListBox = class(TSquaredBasicScoreListBox)
  private
    FNewTitle: string;
    FNewScores: TScoreList;
    function GetIsChangingScores: boolean;
  protected
    property NewTitle: string read FNewTitle;
    property NewScores: TScoreList read FNewScores;
  public
    constructor Create(aX, aY, aWidth, aHeight: integer; aBackgroundColor: TRGBAColor; aTitle: string; aCount: integer; aScreen: TSDLScreen);

    procedure ChangeScores(aTitle: string; aScores: TScoreList);

    procedure Update; override;

    property isChangingScores: boolean read GetIsChangingScores;
  end;

implementation

//******************************************************************************
// TSquaredBasicScoreListBox
//******************************************************************************

constructor TSquaredBasicScoreBox.Create(aX, aY, aWidth, aHeight: integer; aBackgroundColor: TRGBAColor; aTitle: string; aScreen: TSDLScreen);
begin
  inherited Create(aX, aY, aWidth, aHeight, aBackgroundColor, aTitle, aScreen);

  BorderWidth := 6;

  FOrgPos.x := aX;
  FOrgPos.y := aY;

  Moving := mvHere;
  Update;
end;

//------------------------------------------------------------------------------
// properties
//------------------------------------------------------------------------------

procedure TSquaredBasicScoreBox.SetMoving(aValue: TMoving);
begin
  if aValue <> FMoving then begin

    FMoving := aValue;

    case FMoving of
      mvHere:
        begin
          Pos      := OrgPos;
          Velocity := NullVector2DFloat;
        end;
      mvIn:
        begin
          x    := OrgPos.x + ScreenHeight - 80;
          y    := OrgPos.y;
          VelX := -TitleSpeed;
        end;
      mvOut:
        begin
          Pos  := OrgPos;
          VelX := TitleSpeed;
        end;
      mvAway:
        begin
          x := OrgPos.x + ScreenHeight - 80;
          y := OrgPos.y;
          Velocity := NullVector2DFloat;
        end;
    end;
  end;
end;

//------------------------------------------------------------------------------
// rendering
//------------------------------------------------------------------------------

procedure TSquaredBasicScoreBox.Update;
begin
  inherited Update;

  case Moving of
    mvOut:
      if x >= OrgPos.x + ScreenHeight then
        Moving := mvAway
      ;
    mvIn:
      if x <= OrgPos.x then
        Moving := mvHere
      ;
  end;
end;

//******************************************************************************
// TSquaredBasicScoreBox
//******************************************************************************

constructor TSquaredBasicScoreListBox.Create(aX, aY, aWidth, aHeight: integer; aBackgroundColor: TRGBAColor; aTitle: string; aCount: integer; aScreen: TSDLScreen);
begin
  inherited Create(aX, aY, aWidth, aHeight, aBackgroundColor, aTitle, aCount, aScreen);

  BorderWidth := 6;

  FOrgPos.x := aX;
  FOrgPos.y := aY;

  Moving := mvHere;
  Update;
end;

//------------------------------------------------------------------------------
// properties
//------------------------------------------------------------------------------

procedure TSquaredBasicScoreListBox.SetMoving(aValue: TMoving);
begin
  if aValue <> FMoving then begin

    FMoving := aValue;

    case FMoving of
      mvHere:
        begin
          Pos      := OrgPos;
          Velocity := NullVector2DFloat;
        end;
      mvIn:
        begin
          x    := OrgPos.x + ScreenHeight - 80;
          y    := OrgPos.y;
          VelX := -TitleSpeed;
        end;
      mvOut:
        begin
          Pos  := OrgPos;
          VelX := TitleSpeed;
        end;
      mvAway:
        begin
          x := OrgPos.x + ScreenHeight - 80;
          y := OrgPos.y;
          Velocity := NullVector2DFloat;
        end;
    end;
  end;
end;

//------------------------------------------------------------------------------
// rendering
//------------------------------------------------------------------------------

procedure TSquaredBasicScoreListBox.Update;
begin
  inherited Update;

  case Moving of
    mvOut:
      if x >= OrgPos.x + ScreenHeight then
        Moving := mvAway
      ;
    mvIn:
      if x <= OrgPos.x then
        Moving := mvHere
      ;
  end;
end;

//******************************************************************************
// TSquaredTileBox
//******************************************************************************

constructor TSquaredTileBox.Create(aX, aY, aWidth, aHeight: integer; aBackgroundColor: TRGBAColor; aScreen: TSDLScreen);
begin
  inherited Create(aX, aY, aWidth, aHeight, aBackgroundColor, 'Tile', aScreen);
  FTile := TSquaredTile.Create;

  FTileNumber := 0;
end;

destructor TSquaredTileBox.Destroy;
begin
  FTile.Free;
  inherited;
end;

//------------------------------------------------------------------------------
// properties
//------------------------------------------------------------------------------

procedure TSquaredTileBox.SetTileNumber(aValue: integer);
begin
  if aValue <> FTileNumber then begin
    FTileNumber := aValue;
    Score := Trunc(Power(2, aValue));

    // update tile grphics
    UpdateTile;
  end;
end;

procedure TSquaredTileBox.UpdateTile;
var
  aSaveZoom: double;
begin
  if (TileNumber >= MinTile) and (TileNumber <= MaxTile) then begin
    aSaveZoom := Tile[TileNumber].Zoom;
    try
      Tile[TileNumber].Zoom := 1;
      Tile[TileNumber].Update;
      FTile.Zoom := 1;
      FTile.Update;
      ApplySurface(0, 0, Tile[TileNumber].Surface, FTile.Surface);
      FTile.Zoom := (Height - 2 * Options.BorderWidth) / TemplateWidth;
      FTile.Update;
    finally
      Tile[TileNumber].Zoom := aSaveZoom;
      Tile[TileNumber].Update;
    end;
  end;
end;

//------------------------------------------------------------------------------
// methods
//------------------------------------------------------------------------------

procedure TSquaredTileBox.SetIfLarger(aTileNumber: integer);                    //<- will show the tile value only if it's larger than the current one
begin
  if aTileNumber > TileNumber then
    TileNumber := aTileNumber
  ;
end;

procedure TSquaredTileBox.RenderTo(aSurface: TSDLSurface);
begin
  Clear;
  // title
  if (TitleFont <> nil) then begin
    TitleFont.Color := Font.Color;
    WriteText(BorderWidth, BorderWidth, Title, TitleFont);
  end;
  // tile
  if Assigned then begin
    if (TileNumber >= MinTile) and (TileNumber <= MaxTile) then begin
      FTile.RenderTo(
        Width - FTile.Width - Options.BorderWidth,
        Options.BorderWidth,
        Self
      );
    end;
  end;
  //*** show
  RenderTo(x, y, aSurface);
end;

//******************************************************************************
// TSquaredScoreBox
//******************************************************************************

constructor TSquaredScoreBox.Create(aX, aY, aWidth, aHeight: integer; aBackgroundColor: TRGBAColor; aTitle: string; aScreen: TSDLScreen);
begin
  inherited Create(aX, aY, aWidth, aHeight, aBackgroundColor, aTitle, aScreen);
  FTile := TSquaredTile.Create;

  FTileNumber := 0;
end;

destructor TSquaredScoreBox.Destroy;
begin
  FTile.Free;
  inherited;
end;

//------------------------------------------------------------------------------
// properties
//------------------------------------------------------------------------------

procedure TSquaredScoreBox.SetScore(aValue: integer);
begin
  inherited;
end;

procedure TSquaredScoreBox.SetTileNumber(aValue: integer);
begin
  if aValue <> FTileNumber then begin
    FTileNumber := aValue;

    // update tile grphics
    UpdateTile;

    if (HighScore <> nil) and (HighScore is TSquaredScoreBox) then begin
      //new high score reached?
      if Score >= TSquaredScoreBox(HighScore).Score then begin
        TSquaredScoreBox(HighScore).TileNumber := FTileNumber;
      end;
    end;
  end;
end;

procedure TSquaredScoreBox.UpdateTile;
var
  aSaveZoom: double;
begin
  if (TileNumber >= MinTile) and (TileNumber <= MaxTile) then begin
    aSaveZoom := Tile[TileNumber].Zoom;
    try
      Tile[TileNumber].Zoom := 1;
      Tile[TileNumber].Update;
      FTile.Zoom := 1;
      FTile.Update;
      ApplySurface(0, 0, Tile[TileNumber].Surface, FTile.Surface);
      FTile.Zoom := TinyTileWidth / TemplateWidth;
      FTile.Update;
    finally
      Tile[TileNumber].Zoom := aSaveZoom;
      Tile[TileNumber].Update;
    end;
  end;
end;

//------------------------------------------------------------------------------
// methods
//------------------------------------------------------------------------------

procedure TSquaredScoreBox.SetIfLarger(aTileNumber: integer);                    //<- will show the tile value only if it's larger than the current one
begin
  if aTileNumber > TileNumber then
    TileNumber := aTileNumber
  ;
end;

procedure TSquaredScoreBox.DoSaveTo(aCfg: TIniFile; aSection, aID: string);
begin
  inherited;
  aCfg.WriteInteger(aSection, aID + 'Tile', TileNumber);
end;

procedure TSquaredScoreBox.DoLoadFrom(aCfg: TIniFile; aSection, aID: string);
begin
  inherited;
  TileNumber := aCfg.ReadInteger(aSection, aID + 'Tile', FTileNumber);
end;

procedure TSquaredScoreBox.RenderTo(aSurface: TSDLSurface);
begin
  inherited;
  // tile
  if Assigned then begin
    if (TileNumber >= MinTile) and (TileNumber <= MaxTile) then begin
      FTile.RenderTo(
        Width - TinyBorderWidth - TinyTileWidth,
        TinyBorderWidth,
        Self
      );
    end;
  end;
  //*** show
  RenderTo(x, y, aSurface);
end;

//******************************************************************************
// TSquaredScoreListBox
//******************************************************************************

constructor TSquaredScoreListBox.Create(aX, aY, aWidth, aHeight: integer; aBackgroundColor: TRGBAColor; aTitle: string; aCount: integer; aScreen: TSDLScreen);
begin
  inherited;

  FNewTitle := '';
  FNewScores := nil;
end;

//------------------------------------------------------------------------------
// properties
//------------------------------------------------------------------------------

function TSquaredScoreListBox.GetIsChangingScores: boolean;
begin
  Result := FNewScores <> nil;
end;

//------------------------------------------------------------------------------
// methods
//------------------------------------------------------------------------------

procedure TSquaredScoreListBox.ChangeScores(aTitle: string; aScores: TScoreList);
begin
  // prepare for changing the scores
  FNewTitle := aTitle;
  FNewScores := aScores;
  Moving := mvOut;
end;

procedure TSquaredScoreListBox.Update;
begin
  inherited;

  if isChangingScores then begin
    case Moving of
      mvAway:
        begin
          Scores.Assign(NewScores);
          Title := NewTitle;
          Moving := mvIn;
        end;
      mvIn:
        begin
          FNewScores := nil;
          FNewTitle :='';
        end;
    end;
  end;
end;

end.

