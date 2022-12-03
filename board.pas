unit board;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sdl, sdlfonts, sdlclasses, sdltypes, sdlsprites, sdlappstates,
  consts, gui, math, tiles, resources, inifiles;

type

  //****************************************************************************
  //*** Squared board
  //****************************************************************************

  TSquaredBoard = class(TMovingGfxSprite)
  private
    FOwner: TBaseState;
    FMoving: TMoving;
    FOrgPos: TVector2DInt;
    FSize: integer;
    FTileWidth: integer;
    FBorderWidth: integer;
    FScore: TSquaredScoreBox;
    FMoveDirection: TDirection;
    FGameOver: TGameOverAnimations;

    FData: array of integer;
    FNewData: array of integer;
    FMolten: array of integer;
    FDelta: array of TVector2DInt;
    FAnimation: array of TSquaredAnimation;

    procedure SetMoving(aValue: TMoving);

    function GetMaxData: integer;
    function GetData(aIndex: integer): integer;
    procedure SetData(aIndex, aValue: integer);
    function GetNewData(aIndex: integer): integer;
    procedure SetNewData(aIndex, aValue: integer);
    function GetMolten(aIndex: integer): integer;
    procedure SetMolten(aIndex, aValue: integer);
    function GetDelta(aIndex: integer): TVector2DInt;
    procedure SetDelta(aIndex: integer; aValue: TVector2DInt);
    function GetFieldCount: integer;
    function GetField(aX, aY: integer): integer;
    procedure SetField(aX, aY, aValue: integer);
    function GetNewField(aX, aY: integer): integer;
    procedure SetNewField(aX, aY, aValue: integer);
    function GetMoltenField(aX, aY: integer): integer;
    procedure SetMoltenField(aX, aY, aValue: integer);
    function GetAnimations(aIndex: integer): TSquaredAnimation;
    procedure SetAnimations(aIndex: integer; aValue: TSquaredAnimation);
    function GetAnimation(aX, aY: integer): TSquaredAnimation;
    procedure SetAnimation(aX, aY: integer; aValue: TSquaredAnimation);
    function GetIsAnimating: boolean;
    function GetIsSliding: boolean;
    function GetIsSlideFinished: boolean;
    function GetFreeFieldCount: integer;
    function GetFreeField(aIndex: integer): integer;
  protected
    // animation helpers
    function FindSlideTo(aToX, aToY: integer): TSlideAnimation;
    procedure StartSlide(aX, aY, aFrom, aTo: integer; aDirection: TSlideDirection);
    procedure DecSlideDestination(aX, aY, aLimit: integer);
    procedure DecSlideToDestination(aX, aY, aToField: integer);
    procedure IncSlideDestination(aX, aY, aLimit: integer);
    procedure IncSlideToDestination(aX, aY, aToField: integer);

    property Owner: TBaseState read FOwner;
    property NewData[aIndex: integer]: integer read GetNewData write SetNewData;//<- temporary data while calculating moves
  public
    constructor Create(aOwner: TBaseState);
    destructor Destroy; override;

    procedure Save;
    procedure Load;
    procedure SaveTo(aFile, aSection, aID: string);
    procedure LoadFrom(aFile, aSection, aID: string);

    procedure Reset;
    procedure ResetData;
    procedure ResetNewData;
    procedure ResetMolten;
    procedure ResetAnimations;
    procedure UpdateData;

    // moves
    function CanMove: boolean; overload;
    function CanMove(aDirection: TDirection): boolean; overload;
    function CanMoveUp: boolean;
    function CanMoveDown: boolean;
    function CanMoveLeft: boolean;
    function CanMoveRight: boolean;
    procedure MoveTiles(aDirection: TDirection);
    procedure MoveUp;
    procedure MoveDown;
    procedure MoveLeft;
    procedure MoveRight;
    procedure DoMoveUp(aPhase: integer);
    procedure DoMoveDown(aPhase: integer);
    procedure DoMoveLeft(aPhase: integer);
    procedure DoMoveRight(aPhase: integer);
    procedure DoSumUp;
    procedure DoSumDown;
    procedure DoSumLeft;
    procedure DoSumRight;

    // display the board
    procedure Update; override;
    procedure UpdateAnimations;
    procedure RenderTo(aSurface: TSDLSurface); override;

    property Moving: TMoving read FMoving write SetMoving;                      //<- is the whole board moving due to an animation?
    property OrgPos: TVector2DInt read FOrgPos;                                 //<- original position of the board
    property Size: integer read FSize;                                          //<- width/height of the board (no. of tiles)
    property TileWidth: integer read FTileWidth;                                //<- width/height of a tile
    property BorderWidth: integer read FBorderWidth;                            //<- width of the border between tiles
    property Score: TSquaredScoreBox read FScore write FScore;                  //<- info box for the current score
    property GameOver: TGameOverAnimations read FGameOver;                      //<- pretty game over animation
    property MoveDirection: TDirection read FMoveDirection;                     //<- direction of the current move
    property Data[aIndex: integer]: integer read GetData write SetData;         //<- index in the tile array for every field
    property MaxData: integer read GetMaxData;                                  //<- best tile
    property Molten[aIndex: integer]: integer read GetMolten write SetMolten;   //<- contains only the just summed up tiles of the last move
    property Animations[aIndex: integer]: TSquaredAnimation read GetAnimations write SetAnimations; //<- currently running animation for every tile
    property Animation[aX, aY: integer]: TSquaredAnimation read GetAnimation write SetAnimation;
    property isAnimating: boolean read GetIsAnimating;                          //<- at least one animation is still running
    property isSliding: boolean read GetIsSliding;                              //<- slide animations currently running
    property isSlideFinished: boolean read GetIsSlideFinished;                  //<- have all slide animations reached their goals?
    property FieldCount: integer read GetFieldCount;
    property Field[aX, aY: integer]: integer read GetField write SetField;      //<- 2D access to field data
    property NewField[aX, aY: integer]: integer read GetNewField write SetNewField;
    property MoltenField[aX, aY: integer]: integer read GetMoltenField write SetMoltenField;
    property FreeFieldCount: integer read GetFreeFieldCount;
    property FreeField[aIndex: integer]: integer read GetFreeField;             //<- array containing onlys free fields
  end;

implementation

uses
  game;

//******************************************************************************
// TSquaredBoard
//******************************************************************************

constructor TSquaredBoard.Create(aOwner: TBaseState);
var
  ii, jj: integer;
  aX, aY: integer;
begin
  inherited Create;

  FOwner := aOwner;

  FMoving := mvHere;
  FMoveDirection := dirNone;

  FScore    := nil;

  // create a surface for the empty board
  Surface := SDL_CreateRGBSurface(
    0,
    Options.BoardWidth,
    Options.BoardWidth,
    Screen.Surface^.format^.BitsPerPixel,
    Screen.Surface^.format^.RMask,
    Screen.Surface^.format^.GMask,
    Screen.Surface^.format^.BMask,
    Screen.Surface^.format^.AMask
  );
  FOrgPos.x := (Screen.Width  - Width)  div 2;
  FOrgPos.y := (Screen.Height - Height) div 2;

  Pos := FOrgPos;

  FSize        := Options.BoardSize;
  FTileWidth   := Options.TileWIdth;
  FBorderWidth := Options.BorderWIdth;

  BackgroundColor := Options.GridColor;
  Color           := Options.FieldColor;
  Clear;

  for ii := 0 to Size - 1 do begin
    for jj := 0 to Size - 1 do begin
      aX := BorderWidth + ii * (TileWidth + BorderWidth);
      aY := BorderWidth + jj * (TileWidth + BorderWidth);
      Box(aX, aY, aX + TileWidth - 1, aY + TileWidth - 1);
    end;
  end;

  FGameOver := TGameOverAnimations.Create(Self);

  //*** init board
  SetLength(FData, Size * Size);
  SetLength(FNewData, Length(FData));
  SetLength(FMolten, Length(FData));
  SetLength(FDelta, Length(FData));
  SetLength(FAnimation, Length(FData));
  Reset;
end;

destructor TSquaredBoard.Destroy;
var
  ii: integer;
begin
  for ii := 0 to Length(FAnimation) - 1 do begin
    FreeAndNil(FAnimation[ii]);
  end;

  FGameOver.Free;

  inherited;
end;

//------------------------------------------------------------------------------
// properties
//------------------------------------------------------------------------------

procedure TSquaredBoard.SetMoving(aValue: TMoving);
begin
  if aValue <> FMoving then begin
    FMoving := aValue;

    case FMoving of
      mvHere:
        begin
          Pos := OrgPos;
          Velocity := NullVector2DFloat;
        end;
      mvOut:
        begin
          Pos := OrgPos;
          VelY := TitleSpeed;
        end;
      mvIn:
        begin
          x := OrgPos.x;
          y := Screen.Height + OrgPos.y;
          VelY := -TitleSpeed;
        end;
      mvAway:
        begin
          x := OrgPos.x;
          y := Screen.Height + OrgPos.y;
          Velocity := NullVector2DFloat;
        end;
    end;
  end;
end;

//------------------------------------------------------------------------------

function TSquaredBoard.GetMaxData: integer;
var
  ii: integer;
begin
  Result := 0;
  for ii := Low(FData) to High (FData) do begin
    if FData[ii] > Result then
      Result := FData[ii]
    ;
  end;
end;

//------------------------------------------------------------------------------

function TSquaredBoard.GetData(aIndex: integer): integer;
begin
  Result := FData[aIndex];
end;

procedure TSquaredBoard.SetData(aIndex, aValue: integer);
begin
  FData[aIndex] := aValue;
end;

function TSquaredBoard.GetNewData(aIndex: integer): integer;
begin
  Result := FNewData[aIndex];
end;

procedure TSquaredBoard.SetNewData(aIndex, aValue: integer);
begin
  FNewData[aIndex] := aValue;
end;

function TSquaredBoard.GetMolten(aIndex: integer): integer;
begin
  Result := FMolten[aIndex];
end;

procedure TSquaredBoard.SetMolten(aIndex, aValue: integer);
begin
  FMolten[aIndex] := aValue;
end;

function TSquaredBoard.GetDelta(aIndex: integer): TVector2DInt;
begin
  Result := FDelta[aIndex];
end;

procedure TSquaredBoard.SetDelta(aIndex: integer; aValue: TVector2DInt);
begin
  FDelta[aIndex] := aValue;
end;

function TSquaredBoard.GetFieldCount: integer;
begin
  Result := Length(FData);
end;

function TSquaredBoard.GetField(aX, aY: integer): integer;
begin
  Result := FData[aX + aY * Size];
end;

procedure TSquaredBoard.SetField(aX, aY, aValue: integer);
begin
  FData[aX + aY * Size] := aValue;
end;

function TSquaredBoard.GetNewField(aX, aY: integer): integer;
begin
  Result := FNewData[aX + aY * Size];
end;

procedure TSquaredBoard.SetNewField(aX, aY, aValue: integer);
begin
  FNewData[aX + aY * Size] := aValue;
end;

function TSquaredBoard.GetMoltenField(aX, aY: integer): integer;
begin
  Result := FMolten[aX + aY * Size];
end;

procedure TSquaredBoard.SetMoltenField(aX, aY, aValue: integer);
begin
  FMolten[aX + aY * Size] := aValue;
end;

function TSquaredBoard.GetAnimations(aIndex: integer): TSquaredAnimation;
begin
  Result := FAnimation[aIndex];
end;

procedure TSquaredBoard.SetAnimations(aIndex: integer; aValue: TSquaredAnimation);
begin
  // destroy old animation, if necessary
  if FAnimation[aIndex] <> nil then
    FreeAndNil(FAnimation[aIndex]);
  ;
  FAnimation[aIndex] := aValue;
end;

function TSquaredBoard.GetAnimation(aX, aY: integer): TSquaredAnimation;
begin
  Result := FAnimation[aX + aY * Size];
end;

procedure TSquaredBoard.SetAnimation(aX, aY: integer; aValue: TSquaredAnimation);
begin
  // destroy old animation, if necessary
  if FAnimation[aX + aY * Size] <> nil then
    FreeAndNil(FAnimation[aX + aY * Size]);
  ;
  FAnimation[aX + aY * Size] := aValue;
end;

function TSquaredBoard.GetIsAnimating: boolean;
var
  ii: integer;
begin
  Result := FALSE;
  for ii := 0 to Length(FAnimation) - 1 do begin
    if (FAnimation[ii] <> nil) and not (FAnimation[ii] is TGameOverAnimation) then begin
      Result := TRUE;
      Break;
    end;
  end;
end;

function TSquaredBoard.GetIsSliding: boolean;
var
  ii: integer;
begin
  Result := FALSE;
  for ii := 0 to Length(FAnimation) - 1 do begin
    if FAnimation[ii] is TSlideAnimation then begin
      Result := TRUE;
      Break;
    end;
  end;
end;

function TSquaredBoard.GetIsSlideFinished: boolean;
var
  ii: integer;
begin
  Result := TRUE;
  for ii := 0 to Length(FAnimation) - 1 do begin
    if FAnimation[ii] is TSlideAnimation then begin
      if not TSlideAnimation(FAnimation[ii]).isFinished then begin              //<- there is still something going on...
        Result := FALSE;
        Break;
      end;
    end;
  end;
end;

function TSquaredBoard.GetFreeFieldCount: integer;
var
  ii: integer;
begin
  Result := 0;
  for ii := 0 to Length(FData) - 1 do begin
    if FData[ii] = 0 then inc(Result);
  end;
end;

function TSquaredBoard.GetFreeField(aIndex: integer): integer;
var
  ii, jj: integer;
begin
  Result := -1;
  jj := -1;
  for ii := 0 to Length(FData) - 1 do begin
    if FData[ii] = 0 then inc(jj);
    if jj = aIndex then begin
      Result := ii;
      Break;
    end;
  end;
end;

//------------------------------------------------------------------------------
// load/save board
//------------------------------------------------------------------------------

procedure TSquaredBoard.Save;
begin
  SaveTo(cCfgFile, 'Board', 'Data');
end;

procedure TSquaredBoard.Load;
begin
  LoadFrom(cCfgFile, 'Board', 'Data');
end;

procedure TSquaredBoard.SaveTo(aFile, aSection, aID: string);
var
  ii: integer;
  aCfg: TIniFile;
  aData: string;
begin
  aCfg := TIniFile.Create(aFile);
  try
    aData := '';
    for ii := 0 to FieldCount - 1 do begin
      if aData <> '' then aData := aData + ',';
      aData := aData + IntToStr(Data[ii]);
    end;
    aCfg.WriteString(aSection, aID, aData);
  finally
    aCfg.Free;
  end;
end;

procedure TSquaredBoard.LoadFrom(aFile, aSection, aID: string);
var
  ii: integer;
  aCfg: TIniFile;
  aList: TStringList;
begin
  ResetData;

  aCfg := TIniFile.Create(aFile);
  try
    aList := TStringList.Create;
    try
      aList.StrictDelimiter := TRUE;
      aList.Delimiter := ',';
      aList.DelimitedText := aCfg.ReadString(aSection, aID, '');

      for ii:= 0 to FieldCount - 1 do begin
        if ii <= aList.Count - 1 then begin
          try
            FData[ii] := StrToInt(aList[ii]);
          except
            //not numeric
          end;
        end;
      end;
    finally
      aList.Free;
    end;
  finally
    aCfg.Free;
  end;
end;

//------------------------------------------------------------------------------
// game moves
//------------------------------------------------------------------------------

function TSquaredBoard.CanMove: boolean;
begin
  Result :=
    CanMoveUp or
    CanMoveDown or
    CanMoveLeft or
    CanMoveRight
  ;
end;

function TSquaredBoard.CanMove(aDirection: TDirection): boolean;
begin
  case aDirection of
    dirUp:
      Result := CanMoveUp;
    dirDown:
      Result := CanMoveDown;
    dirLeft:
      Result := CanMoveLeft;
    dirRight:
      Result := CanMoveRight;
  end;
end;

function TSquaredBoard.CanMoveUp: boolean;
var
  ii, jj: integer;
begin
  Result := FALSE;
  for ii := 0 to Size - 1 do begin
    for jj := Size - 1 downto 1 do begin
      // free field or same tile?
      if (Field[ii, jj] <> 0) then begin
        if (Field[ii, jj - 1] = 0)
        or ((Field[ii, jj - 1] = Field[ii, jj]) and (Field[ii, jj] < MaxTile)) then begin
          Result := TRUE;
        end;
      end;
      if Result then Break;
    end;
    if Result then Break;
  end;
end;

function TSquaredBoard.CanMoveDown: boolean;
var
  ii, jj: integer;
begin
  Result := FALSE;
  for ii := Size - 1 downto 0 do begin
    for jj := 0 to (Size - 1) - 1 do begin
      // free field or same tile?
      if  (Field[ii, jj] <> 0) then begin
        if (Field[ii, jj + 1] = 0)
        or ((Field[ii, jj + 1] = Field[ii, jj]) and (Field[ii, jj] < MaxTile)) then begin
          Result := TRUE;
        end;
      end;
      if Result then Break;
    end;
    if Result then Break;
  end;
end;

function TSquaredBoard.CanMoveLeft: boolean;
var
  ii, jj: integer;
begin
  Result := FALSE;
  for jj := Size - 1 downto 0 do begin
    for ii := Size - 1 downto 1 do begin
      // free field or same tile?
      if  (Field[ii, jj] <> 0) then begin
        if (Field[ii - 1, jj] = 0)
        or ((Field[ii - 1, jj] = Field[ii, jj])  and (Field[ii, jj] < MaxTile)) then begin
          Result := TRUE;
        end;
      end;
      if Result then Break;
    end;
    if Result then Break;
  end;
end;

function TSquaredBoard.CanMoveRight: boolean;
var
  ii, jj: integer;
begin
  Result := FALSE;
  for jj := 0 to Size - 1 do begin
    for ii := 0 to (Size - 1) - 1 do begin
      // free field or same tile?
      if  (Field[ii, jj] <> 0) then begin
        if (Field[ii + 1, jj] = 0)
        or ((Field[ii + 1, jj] = Field[ii, jj])  and (Field[ii, jj] < MaxTile)) then begin
          Result := TRUE;
        end;
      end;
      if Result then Break;
    end;
    if Result then Break;
  end;
end;

//------------------------------------------------------------------------------

procedure TSquaredBoard.MoveTiles(aDirection: TDirection);
begin

  FMoveDirection := aDirection;

  case aDirection of
    dirUp:
      MoveUp;
    dirDown:
      MoveDown;
    dirLeft:
      MoveLeft;
    dirRight:
      MoveRight;
  end;
end;

//------------------------------------------------------------------------------

procedure TSquaredBoard.MoveUp;
begin
  ResetMolten;

  DoMoveUp(0);
  DoSumUp;
  DoMoveUp(1);
end;

procedure TSquaredBoard.MoveDown;
begin
  ResetMolten;

  DoMoveDown(0);
  DoSumDown;
  DoMoveDown(1);
end;

procedure TSquaredBoard.MoveLeft;
begin
  ResetMolten;

  DoMoveLeft(0);
  DoSumLeft;
  DoMoveLeft(1);
end;

procedure TSquaredBoard.MoveRight;
begin
  ResetMolten;

  DoMoveRight(0);
  DoSumRight;
  DoMoveRight(1);
end;

//------------------------------------------------------------------------------

procedure TSquaredBoard.DoMoveUp(aPhase: integer);
var
  ii, jj, kk, ll: integer;
begin
  ResetNewData;
  for ii := 0 to Size - 1 do begin
    for jj := 0 to Size - 1 do begin
      if (Field[ii, jj] <> 0) then begin
        if (jj = 0) then begin
          // the first row needs not to be moved...
          NewField[ii, jj] := Field[ii, jj];
          // ...but it still gets an animation!
          if aPhase = 0 then begin
            StartSlide(ii, jj, jj, jj, sldVertical);
          end;
        end
        else begin
          // move as far as possible
          kk := jj;
          while ((kk - 1) >= 0) and (NewField[ii, kk - 1] = 0) do begin
            dec(kk);
          end;
          NewField[ii, kk] := Field[ii, jj];
          // move molten fields, too
          if kk <> jj then begin
            if MoltenField[ii, jj] <> 0 then begin
              MoltenField[ii, kk] := MoltenField[ii, jj];
              MoltenField[ii, jj] := 0;
            end;
          end;
          // create an animation for every tile
          if aPhase = 0 then begin
            StartSlide(ii, jj, jj, kk, sldVertical);
          end;
          // change the aim of the animations
          if aPhase = 1 then begin
            if kk <> jj then begin //<- only if necessary
              for ll := kk to Size - 1 do begin
                DecSlideDestination(ii, ll, kk);
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  UpdateData;
end;

procedure TSquaredBoard.DoMoveDown(aPhase: integer);
var
  ii, jj, kk, ll: integer;
begin
  ResetNewData;
  for ii := Size - 1 downto 0 do begin
    for jj := Size - 1 downto 0 do begin
      if (Field[ii, jj] <> 0) then begin
        if (jj = Size - 1) then begin
          // the first row needs not to be moved
          NewField[ii, jj] := Field[ii, jj];
          // ...but it still gets an animation!
          if aPhase = 0 then begin
            StartSlide(ii, jj, jj, jj, sldVertical);
          end;
        end
        else begin
          // move as far as possible
          kk := jj;
          while ((kk + 1) <= Size - 1) and (NewField[ii, kk + 1] = 0) do begin
            inc(kk);
          end;
          NewField[ii, kk] := Field[ii, jj];
          // move molten fields, too
          if kk <> jj then begin
            if MoltenField[ii, jj] <> 0 then begin
              MoltenField[ii, kk] := MoltenField[ii, jj];
              MoltenField[ii, jj] := 0;
            end;
          end;
          // create an animation for every tile
          if aPhase = 0 then begin
            StartSlide(ii, jj, jj, kk, sldVertical);
          end;
          // change the aim of the animations
          if aPhase = 1 then begin
            if kk <> jj then begin //<- only if necessary
              for ll := kk downto 0 do begin
                IncSlideDestination(ii, ll, kk);
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  UpdateData;
end;

procedure TSquaredBoard.DoMoveLeft(aPhase: integer);
var
  ii, jj, kk, ll: integer;
begin
  ResetNewData;
  for jj := Size - 1 downto 0 do begin
    for ii := 0 to Size - 1 do begin
      if (Field[ii, jj] <> 0) then begin
        if (ii = 0) then begin
          // the first column needs not to be moved
          NewField[ii, jj] := Field[ii, jj];
          // ...but it still gets an animation!
          if aPhase = 0 then begin
            StartSlide(ii, jj, ii, ii, sldHorizontal);
          end;
        end
        else begin
          // move as far as possible
          kk := ii;
          while ((kk - 1) >= 0) and (NewField[kk - 1, jj] = 0) do begin
            dec(kk);
          end;
          NewField[kk, jj] := Field[ii, jj];
          // move molten fields, too
          if kk <> ii then begin
            if MoltenField[ii, jj] <> 0 then begin
              MoltenField[kk, jj] := MoltenField[ii, jj];
              MoltenField[ii, jj] := 0;
            end;
          end;
          // create an animation for every tile
          if aPhase = 0 then begin
            StartSlide(ii, jj, ii, kk, sldHorizontal);
          end;
          // change the aim of the animations
          if aPhase = 1 then begin
            if kk <> ii then begin //<- only if necessary
              for ll := kk to Size - 1 do begin
                DecSlideDestination(ll, jj, kk);
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  UpdateData;
end;

procedure TSquaredBoard.DoMoveRight(aPhase: integer);
var
  ii, jj, kk, ll: integer;
begin
  ResetNewData;
  for jj := 0 to Size - 1 do begin
    for ii := Size - 1 downto 0 do begin
      if (Field[ii, jj] <> 0) then begin
        if (ii = Size - 1) then begin
          // the first column needs not to be moved
          NewField[ii, jj] := Field[ii, jj];
          // ...but it still gets an animation!
          if aPhase = 0 then begin
            StartSlide(ii, jj, ii, ii, sldHorizontal);
          end;
        end
        else begin
          // move as far as possible
          kk := ii;
          while ((kk + 1) <= Size - 1) and (NewField[kk + 1, jj] = 0) do begin
            inc(kk);
          end;
          NewField[kk, jj] := Field[ii, jj];
          // move molten fields, too
          if kk <> ii then begin
            if MoltenField[ii, jj] <> 0 then begin
              MoltenField[kk, jj] := MoltenField[ii, jj];
              MoltenField[ii, jj] := 0;
            end;
          end;
          // create an animation for every tile
          if aPhase = 0 then begin
            StartSlide(ii, jj, ii, kk, sldHorizontal);
          end;
          // change the aim of the animations
          if aPhase = 1 then begin
            if kk <> ii then begin //<- only if necessary
              for ll := kk downto 0 do begin
                IncSlideDestination(ll, jj, kk);
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  UpdateData;
end;

//------------------------------------------------------------------------------

procedure TSquaredBoard.DoSumUp;
var
  ii, jj, kk: integer;
begin
  ResetNewData;
  for ii := 0 to Size - 1 do begin
    for jj := 0 to Size - 1 do begin
      if (Field[ii, jj] <> 0) then begin
        if  (jj < Size - 1)
        and (Field[ii, jj] < MaxTile)
        and (Field[ii, jj] = Field[ii, jj + 1]) then begin
          //*** same value -> sum up
          NewField[ii, jj] := Field[ii, jj] + 1;
          MoltenField[ii, jj] := NewField[ii, jj];
          Field[ii, jj + 1] := 0;
          //*** score
          Score.Add(Trunc(Power(2, NewField[ii, jj])));
          Score.SetIfLarger(NewField[ii, jj]);
          //*** move all animations leading to the following field one field further...
          for kk := jj + 1 to Size - 1 do begin
            DecSlideToDestination(ii, kk, jj + 1);
          end;
        end
        else begin
          //*** leave value unchanged
          NewField[ii, jj] := Field[ii, jj];
        end;
      end;
    end;
  end;
  UpdateData;
end;

procedure TSquaredBoard.DoSumDown;
var
  ii, jj, kk: integer;
begin
  ResetNewData;
  for ii := Size - 1 downto 0 do begin
    for jj := Size - 1 downto 0 do begin
      if (Field[ii, jj] <> 0) then begin
        if  (jj > 0)
        and (Field[ii, jj] < MaxTile)
        and (Field[ii, jj] = Field[ii, jj - 1]) then begin
          //*** same value -> sum up
          NewField[ii, jj] := Field[ii, jj] + 1;
          MoltenField[ii, jj] := NewField[ii, jj];
          Field[ii, jj - 1] := 0;
          //*** score
          Score.Add(Trunc(Power(2, NewField[ii, jj])));
          Score.SetIfLarger(NewField[ii, jj]);
          //*** move all animations leading to the following field one field further...
          for kk := jj - 1 downto 0 do begin
            IncSlideToDestination(ii, kk, jj - 1);
          end;
        end
        else begin
          //*** leave value unchanged
          NewField[ii, jj] := Field[ii, jj];
        end;
      end;
    end;
  end;
  UpdateData;
end;

procedure TSquaredBoard.DoSumLeft;
var
  ii, jj, kk: integer;
begin
  ResetNewData;
  for jj := 0 to Size - 1 do begin
    for ii := 0 to Size - 1 do begin
      if (Field[ii, jj] <> 0) then begin
        if  (ii < Size - 1)
        and (Field[ii, jj] < MaxTile)
        and (Field[ii, jj] = Field[ii + 1, jj]) then begin
          //*** same value -> sum up
          NewField[ii, jj] := Field[ii, jj] + 1;
          MoltenField[ii, jj] := NewField[ii, jj];
          Field[ii + 1, jj] := 0;
          //*** score
          Score.Add(Trunc(Power(2, NewField[ii, jj])));
          Score.SetIfLarger(NewField[ii, jj]);
          //*** move all animations leading to the following field one field further...
          for kk := ii + 1 to Size - 1 do begin
            DecSlideToDestination(kk, jj, ii + 1);
          end;
        end
        else begin
          //*** leave value unchanged
          NewField[ii, jj] := Field[ii, jj];
        end;
      end;
    end;
  end;
  UpdateData;
end;

procedure TSquaredBoard.DoSumRight;
var
  ii, jj, kk: integer;
begin
  ResetNewData;
  for jj := 0 to Size - 1 do begin
    for ii := Size - 1 downto 0 do begin
      if (Field[ii, jj] <> 0) then begin
        if  (ii > 0)
        and (Field[ii, jj] < MaxTile)
        and (Field[ii, jj] = Field[ii - 1, jj]) then begin
          //*** same value -> sum up
          NewField[ii, jj] := Field[ii, jj] + 1;
          MoltenField[ii, jj] := NewField[ii, jj];
          Field[ii - 1, jj] := 0;
          //*** score
          Score.Add(Trunc(Power(2, NewField[ii, jj])));
          Score.SetIfLarger(NewField[ii, jj]);
          //*** move all animations leading to the following field one field further...
          for kk := ii - 1 downto 0 do begin
            IncSlideToDestination(kk, jj, ii - 1);
          end;
        end
        else begin
          //*** leave value unchanged
          NewField[ii, jj] := Field[ii, jj];
        end;
      end;
    end;
  end;
  UpdateData;
end;

//------------------------------------------------------------------------------

procedure TSquaredBoard.UpdateData;
var
  ii: integer;
begin
  //move calculated new data to current board data
  for ii := 0 to FieldCount - 1 do begin
    Data[ii] := NewData[ii];
  end;
end;

//------------------------------------------------------------------------------
// animations
//------------------------------------------------------------------------------

function TSquaredBoard.FindSlideTo(aToX, aToY: integer): TSlideAnimation;
var
  ii: integer;
  aSlide: TSlideAnimation;
begin
  Result := nil;

  for ii := 0 to Length(FAnimation) - 1 do begin
    if FAnimation[ii] is TSlideAnimation then begin
      aSlide := TSlideAnimation(FAnimation[ii]);
      case aSlide.Direction of
        sldVertical:
          begin
            if (aSlide.x = aToX) and (aSlide.ToField = aToY) then begin
              Result := TSlideAnimation(FAnimation[ii]);
              break;
            end;
          end;
        sldHorizontal:
          begin
            if (aSlide.ToField = aToX) and (aSlide.y = aToY) then begin
              Result := TSlideAnimation(FAnimation[ii]);
              break;
            end;
          end;
      end;
    end;
  end;

end;

procedure TSquaredBoard.StartSlide(aX, aY, aFrom, aTo: integer; aDirection: TSlideDirection);
begin
  if DoAnimateSlide then begin
    if Animation[aX, aY] = nil then begin
      Animation[aX, aY] := TSlideAnimation.Create(Tile[Field[aX, aY]], aFrom, aTo, aDirection)
    end;
  end;
end;

procedure TSquaredBoard.DecSlideDestination(aX, aY, aLimit: integer);
var
  aSlide: TSlideAnimation;
begin
  if Animation[aX, aY] is TSlideAnimation then begin
    aSlide := TSlideAnimation(Animation[aX, aY]);
    if (aSlide.ToField > aLimit) then begin
      aSlide.ToField := aSlide.ToField - 1;
    end;
  end;
end;

procedure TSquaredBoard.DecSlideToDestination(aX, aY, aToField: integer);
var
  aSlide: TSlideAnimation;
begin
  if Animation[aX, aY] is TSlideAnimation then begin
    aSlide := TSlideAnimation(Animation[aX, aY]);
    if (aSlide.ToField = aToField) then begin
      aSlide.ToField := aSlide.ToField - 1;
    end;
  end;
end;

procedure TSquaredBoard.IncSlideDestination(aX, aY, aLimit: integer);
var
  aSlide: TSlideAnimation;
begin
  if Animation[aX, aY] is TSlideAnimation then begin
    aSlide := TSlideAnimation(Animation[aX, aY]);
    if (aSlide.ToField < aLimit) then begin
      aSlide.ToField := aSlide.ToField + 1;
    end;
  end;
end;

procedure TSquaredBoard.IncSlideToDestination(aX, aY, aToField: integer);
var
  aSlide: TSlideAnimation;
begin
  if Animation[aX, aY] is TSlideAnimation then begin
    aSlide := TSlideAnimation(Animation[aX, aY]);
    if (aSlide.ToField = aToField) then begin
      aSlide.ToField := aSlide.ToField + 1;
    end;
  end;
end;

//------------------------------------------------------------------------------
// draw the board
//------------------------------------------------------------------------------

procedure TSquaredBoard.Update;
begin
  inherited Update;

  UpdateAnimations;

  case Moving of
    mvOut:
      if y >= Screen.Height + OrgPos.y + Height then
        Moving := mvAway
      ;
    mvIn:
      if y <= OrgPos.y then
        Moving := mvHere
      ;
  end;
end;

procedure TSquaredBoard.UpdateAnimations;
const
  FlipDir: array[dirNone..dirRight] of TZoomDirection = (zdX, zdY, zdY, zdX, zdX);
  FlipSpeed: array[FALSE..TRUE] of integer =(DefaultFlipSpeed, QuickFlipSpeed);
var
  ii: integer;
begin
  //*** slide animations are terminated all together...
  if isSlideFinished then begin
    //*** remove slide animations
    for ii := 0 to Length(FAnimation) - 1 do begin
      if FAnimation[ii] is TSlideAnimation then begin
        FreeAndNil(FAnimation[ii])
      end;
    end;

    //*** create flip animations
    if DoAnimateMelt then begin;
      for ii := 0 to Length(FMolten) - 1 do begin
        if Molten[ii] > 1 then begin
          Animations[ii] := TFlipAnimation.Create(
            Tile[Molten[ii] - 1],
            Tile[Molten[ii]],
            FlipDir[MoveDirection],
            FlipSpeed[TSquaredGame(Owner).KeyBuffer.KeyCount > 0]
          );
        end;
      end;
    end;
    ResetMolten;
    FMoveDirection := dirNone;
  end;

  //*** remove terminated animatons
  for ii := 0 to Length(FAnimation) - 1 do begin
    if FAnimation[ii] <> nil then begin
      FAnimation[ii].Update;
      if FAnimation[ii].isTerminated then
        FreeAndNil(FAnimation[ii])
      ;
    end;
  end;
end;

procedure TSquaredBoard.RenderTo(aSurface: TSDLSurface);
var
  ii, jj: integer;
begin
  // board
  RenderTo(x, y, aSurface);

  // chose order for correct sliding animations
  if MoveDirection in [dirNone, dirUp, dirLeft] then begin
    // tiles
    for ii := 0 to Size - 1 do begin
      for jj := 0 to Size - 1 do begin
        if (Field[ii, jj] > 0) or (Animation[ii, jj] <> nil) then begin
          if Animation[ii, jj] <> nil then begin
            Animation[ii, jj].RenderTo(
              x + BorderWidth + (TileWidth + BorderWidth) * ii,
              y + BorderWidth + (TileWidth + BorderWidth) * jj,
              aSurface
            );
          end
          else if not isSliding then begin                                        //<- while sliding ONLY animations are drawn...
            Tile[Field[ii, jj]].RenderTo(
              x + BorderWidth + (TileWidth + BorderWidth) * ii,
              y + BorderWidth + (TileWidth + BorderWidth) * jj,
              aSurface
            );
          end;
        end;
      end;
    end;
  end
  else begin
    // tiles
    for ii := Size - 1 downto 0 do begin
      for jj := Size - 1 downto 0 do begin
        if (Field[ii, jj] > 0) or (Animation[ii, jj] <> nil) then begin
          if Animation[ii, jj] <> nil then begin
            Animation[ii, jj].RenderTo(
              x + BorderWidth + (TileWidth + BorderWidth) * ii,
              y + BorderWidth + (TileWidth + BorderWidth) * jj,
              aSurface
            );
          end
        end;
      end;
    end;
  end;
end;

//------------------------------------------------------------------------------
// methods
//------------------------------------------------------------------------------

procedure TSquaredBoard.Reset;
begin
  GameOver.Stop;
  ResetData;
  ResetNewData;
  ResetAnimations;
end;

procedure TSquaredBoard.ResetData;
var
  ii: integer;
begin
  for ii := 0 to Length(FData) - 1 do begin
    FData[ii] := 0;
  end;
end;

procedure TSquaredBoard.ResetNewData;
var
  ii: integer;
begin
  for ii := 0 to Length(FNewData) - 1 do begin
    FNewData[ii] := 0;
  end;
end;

procedure TSquaredBoard.ResetMolten;
var
  ii: integer;
begin
  for ii := 0 to Length(FMolten) - 1 do begin
    FMolten[ii] := 0;
  end;
end;

procedure TSquaredBoard.ResetAnimations;
var
  ii: integer;
begin
  for ii := 0 to Length(FAnimation) - 1 do begin
    FreeAndNil(FAnimation[ii]);
  end;
end;

end.
