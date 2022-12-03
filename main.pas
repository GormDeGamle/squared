unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sdl, sdlfonts, sdlappstates, sdlclasses,
  consts, resources, game, menu;

type
  //****************************************************************************
  //*** Squared application
  //****************************************************************************

  TSquaredApp = class(TStateApp)
  private
    FTitleFont: TSDLFont;
    FScoreFont: TSDLFont;
    FScoreListFont: TSDLFont;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;

    procedure InitCustomResources; override;
    procedure FreeCustomResources; override;

    procedure CreateState(aID: integer); override;

    property TitleFont: TSDLFont read FTitleFont;
    property ScoreFont: TSDLFont read FScoreFont;
    property ScoreListFont: TSDLFont read FScoreListFont;
  end;

implementation

uses
  sdltypes;

//******************************************************************************
// TSquaredApp
//******************************************************************************

constructor TSquaredApp.Create(TheOwner: TComponent);
begin
  inherited;

  FTitleFont := TSDLFont.Create;
  FScoreFont := TSDLFont.Create;
  FScoreListFont := TSDLFont.Create;

  {$IFDEF WINDOWS}
  ScrFlags    := SDL_SWSURFACE;
  {$ELSE}
  ScrFlags    := SDL_HWSURFACE + SDL_FULLSCREEN;
  {$ENDIF}
  ScrWidth    := ScreenWidth;
  ScrHeight   := ScreenHeight;

  Font.Size  := DefaultFontSize;
  Font.Color := Options.FontColor;
  Font.RenderType := frtBlended;
  Font.Load(cDefaultFont);

  TitleFont.Size  := TitleFontSize;
  TitleFont.Color := Options.TitleFontColor;;
  TitleFont.RenderType := frtBlended;
  TitleFont.Load(cTitleFont);

  ScoreFont.Size  := ScoreFontSize;
  ScoreFont.Color := Options.ScoreFontColor;
  ScoreFont.RenderType := frtBlended;
  ScoreFont.Load(cScoreFont);

  ScoreListFont.Size  := ScoreListFontSize;
  ScoreListFont.Color := Options.ScoreFontColor;
  ScoreListFont.RenderType := frtBlended;
  ScoreListFont.Load(cScoreListFont);

  //SysInfo.DoShow := TRUE;

  NextStateID := ST_GAME;
end;

destructor TSquaredApp.Destroy;
begin
  FScoreListFont.Free;
  FScoreFont.Free;
  FTitleFont.Free;
  inherited;
end;

procedure TSquaredApp.InitCustomResources;
begin
  inherited;
  InitResources;
end;

procedure TSquaredApp.FreeCustomResources;
begin
  FreeResources;
  inherited;
end;

//------------------------------------------------------------------------------
// state change
//------------------------------------------------------------------------------

procedure TSquaredApp.CreateState(aID: integer);
begin
  case aID of
    //ST_MENU:
    //  FState := TSquaredMenu.Create(Self, aID);
    ST_GAME:
      FState := TSquaredGame.Create(Self, aID);
    ST_EXIT:
      Terminate;
  end;
end;

end.

