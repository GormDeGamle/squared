unit fx;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sdl, sdlsprites, sdlfonts, sdltypes, sdlclasses, sdltools,
  consts;

type

  //****************************************************************************
  // Title animation
  //****************************************************************************

  TTitle = class(TMovingSprite)
  private
    FFont: TSDLFont;
    FText: string;
    FMoving: TMoving;
    procedure SetMoving(aValue: TMoving);
  public
    constructor Create(aText: string; aFont: TSDLFont);

    procedure Update; override;

    property Font:TSDLFont read FFont write FFont;
    property Text: string read FText write FText;
    property Moving: TMoving read FMoving write SetMoving;
  end;

  //****************************************************************************
  // game over animation
  //****************************************************************************

  TGameOver = class(TMovingSprite)
  private
    FFont: TSDLFont;
    FText: string;
  public
    constructor Create(aText: string; aFont: TSDLFont);

    property Font:TSDLFont read FFont write FFont;
    property Text: string read FText write FText;
  end;

implementation

//******************************************************************************
// TTitle
//******************************************************************************

constructor TTitle.Create(aText: string; aFont: TSDLFont);
begin
  inherited Create;

  FFont := aFont;
  FText := aText;

  Surface := Font.Render(FText);
  Angle   := 90;
  Moving := mvAway;

  Update;
end;

//------------------------------------------------------------------------------
// properties
//------------------------------------------------------------------------------

procedure TTitle.SetMoving(aValue: TMoving);
begin
  if aValue <> FMoving then begin

    FMoving := aValue;

    case FMoving of
      mvHere:
        begin
          Pos      := NullVector2DInt;
          Velocity := NullVector2DFloat;
        end;
      mvIn:
        begin
          x    := 0;
          y    := -ScreenHeight;
          VelY := TitleSpeed;
        end;
      mvOut:
        begin
          Pos  := NullVector2DInt;
          VelY := -TitleSpeed;
        end;
      mvAway:
        begin
          x := 0;
          y := -ScreenHeight;
          Velocity := NullVector2DFloat;
        end;
    end;
  end;
end;

//------------------------------------------------------------------------------
// animation
//------------------------------------------------------------------------------

procedure TTitle.Update;
begin
  inherited Update;

  case Moving of
    mvOut:
      if y <= - ScreenHeight then
        Moving := mvAway
      ;
    mvIn:
      if y >= 0 then
        Moving := mvHere
      ;
  end;
end;

//******************************************************************************
// TGameOver
//******************************************************************************

constructor TGameOver.Create(aText: string; aFont: TSDLFont);
var
  aMsg1, aMsg2: PSDL_Surface;
begin
  inherited Create;

  FFont := aFont;
  FText := aText;

  Font.RenderType := frtBlended;
  FFont.Color := scBlack;
  aMsg1 := FFont.Render(aText);
  try
    Surface := SDL_CreateRGBSurface(
      0,
      aMsg1^.w,
      aMsg1^.h,
      aMsg1^.format^.BitsPerPixel,
      aMsg1^.format^.RMask,
      aMsg1^.format^.GMask,
      aMsg1^.format^.BMask,
      aMsg1^.format^.AMask
    );
    SDL_FillRect(Surface, nil, MapRGBA(0, 0, 0, $FF));

    FFont.Color := scWhite;
    aMsg2 := FFont.Render(aText);
    try
      if (aMsg2 <> nil) then begin
        ApplySurface(-2,  0, aMsg2, Surface);
        ApplySurface( 2,  0, aMsg2, Surface);
        ApplySurface( 0, -2, aMsg2, Surface);
        ApplySurface( 0,  2, aMsg2, Surface);
      end;
    finally
      SDL_FreeSurface(aMsg2);
    end;

    if (aMsg1 <> nil) then begin
      ApplySurface(0,  0, aMsg1, Surface);
    end
  finally
    SDL_FreeSurface(aMsg1);
  end;

  ReplaceAlpha(Surface, scNone, 0);
  Update;
end;

end.

