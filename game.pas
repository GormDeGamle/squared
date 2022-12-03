unit game;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sdl, sdlclasses, sdlappstates, sdltypes, sdlkeybuffer, consts,
  board, tiles, resources, gui, fx, c4a, highscores;

type
  //****************************************************************************
  //*** Squared - Puzzle Game
  //****************************************************************************

  { TSquaredGame }

  TSquaredGame = class(TBaseState)
  private
    FIsStartingUp: boolean;
    FKeyBuffer: TKeyBuffer;
    FBoard: TSquaredBoard;
    FScore: TSquaredScoreBox;
    FHighScore: TSquaredScoreBox;
    FScoreList: TSquaredScoreListBox;
    FTitle: TTitle;
    FC4A: TC4A;
    FLocalScores: TScoreList;
    FIsOver: boolean;
    FMustPlaceNewTile: boolean;
    FMustPullC4A: boolean;
    FNextStateID: integer;

    FShowHintUntil: integer;                                                    //<- show message that long
    FHint: string;

    procedure SetNextStateID(aValue: integer);
    procedure SetIsOver(aValue: boolean);
    function GetNewTile: integer;
    procedure SetHint(aValue: string);
    function GetC4AID: string;
  protected
    procedure OnKeyPush(aKey: TSDL_KeyboardEvent);
    procedure OnKeyPop(aKey: TSDL_KeyboardEvent);
  public
    constructor Create(aOwner: TStateApp; aID: integer);
    destructor Destroy; override;

    procedure Save;
    procedure Load;

    procedure Reset;
    procedure ResetBoard;
    procedure PlaceNewTile;
    procedure PullC4A;

    procedure ToggleAnimations;
    procedure ToggleC4A;
    procedure ToggleC4AMode;

    procedure OnC4APulled(aSender: TC4A);
    procedure OnC4APushed(aSender: TC4A);

    procedure OnKeyDown(aKey: TSDL_KeyboardEvent); override;
    procedure Move(aDirection: TDirection);

    procedure HandleEvents;
    procedure Update; override;
    procedure Render; override;
    procedure RenderHint;
    procedure RenderDebugInfo;

    property isStartingUp: boolean read FIsStartingUp;
    property NextStateID: integer read FNextStateID write SetNextStateID;
    property KeyBuffer: TKeyBuffer read FKeyBuffer;
    property Board: TSquaredBoard read FBoard;
    property Score: TSquaredScoreBox read FScore;
    property HighScore: TSquaredScoreBox read FHighScore;
    property ScoreList: TSquaredScoreListBox read FScoreList;
    property Title: TTitle read FTitle;
    property C4A: TC4A read FC4A;
    property C4AID: string read GetC4AID;
    property LocalScores: TScoreList read FLocalScores;
    property isOver: boolean read FIsOver write SetIsOver;
    property NewTile: integer read GetNewTile;
    property mustPlaceNewTile: boolean read FMustPlaceNewTile write FMustPlaceNewTile;
    property mustPullC4A: boolean read FMustPullC4A write FMustPullC4A;
    property ShowHintUntil: integer read FShowHintUntil write FShowHintUntil;
    property Hint: string read FHint write SetHint;
  end;

implementation

uses
  sdltools, main;

//****************************************************************************
//*** TSquaredGame
//****************************************************************************

constructor TSquaredGame.Create(aOwner: TStateApp; aID: integer);
begin
  // flag for startup (until first render)
  FIsStartingUp := TRUE;

  FLocalScores := TScoreList.Create(9);

  FC4A := TC4A.Create(cGame, 9);
  FC4A.OnPulled := @ONC4APulled;
  FC4A.OnPushed := @ONC4APushed;
  if C4A.isAvailable then begin
    Options.DoC4A := TRUE;
    Hint := 'C4A support ON';
    C4A.Pull;
  end;

  inherited;
  Randomize;

  FNextStateID := aID;

  FKeyBuffer := TKeyBuffer.Create(KeyBufferSize);
  FKeyBuffer.OnPush := @OnKeyPush;
  FKeyBuffer.OnPop  := @OnKeyPop;

  FTitle    := TTitle.Create('Squared!', TSquaredApp(Owner).TitleFont);

  FBoard := TSquaredBoard.Create(Self);

  FScore  := TSquaredScoreBox.Create(
    FBoard.x + FBoard.Width + FBoard.BorderWidth,
    FBoard.y + FBoard.BorderWidth,
    Screen.Width - (FBoard.x + FBoard.Width + FBoard.BorderWidth) - FBoard.BorderWidth,
    FBoard.TileWidth,
    Options.ScoreColor,
    'Score',
    Screen
  );
  FScore.Font := TSquaredApp(Owner).ScoreFont;
  FScore.TitleFont := Font;
  FScore.SaveFile := cCfgFile;
  FScore.SaveID := 'Current';

  FHighScore := TSquaredScoreBox.Create(
    FScore.x,
    FScore.y + FScore.Height + FBoard.BorderWidth,
    FScore.Width,
    FScore.Height,
    Options.ScoreColor,
    'Best',
    Screen
  );
  FHighScore.Font := FScore.Font;
  FHighScore.TitleFont := FScore.TitleFont;
  FHighScore.SaveFile := cCfgFile;
  FHighScore.SaveID := 'Best';

  FScoreList := TSquaredScoreListBox.Create(
    FHighScore.x,
    FHighScore.y + FHighScore.Height + FBoard.BorderWidth,
    FHighScore.Width,
    FHighScore.Height * 2 + FBoard.BorderWidth,
    Options.ScoreColor,
    'Top',
    9,
    Screen
  );
  FScoreList.Font := TSquaredApp(Owner).ScoreListFont;
  FScoreList.TitleFont := FScore.TitleFont;
  FScoreList.SaveFile := cCfgFile;
  FScoreList.SaveID := 'Top';

  FScore.HighScore := FHighScore;
  FBoard.Score := FScore;

  Load;

  if Board.FreeFieldCount = Board.FieldCount then begin
    Title.Moving := mvHere;
    ResetBoard
  end
  else begin
    Title.Moving := mvIn;
    Board.Moving := mvIn;
    Score.Moving := mvIn;
    HighScore.Moving := mvIn;
    ScoreList.Moving := mvIn;
  end;
end;

destructor TSquaredGame.Destroy;
begin
  Save;

  FC4A.Free;
  FLocalScores.Free;
  FScoreList.Free;
  FHighScore.Free;
  FScore.Free;
  FBoard.Free;
  FTitle.Free;
  FKeyBuffer.Free;

  inherited;
end;

//------------------------------------------------------------------------------
// properties
//------------------------------------------------------------------------------

procedure TSquaredGame.SetNextStateID(aValue: integer);
begin
  if aValue <> FNextStateID then begin
    FNextStateID := aValue;

    case FNextStateID of
      ST_EXIT:
        begin
          Board.Moving := mvOut;
          Title.Moving := mvOut;
          Score.Moving := mvOut;
          HighScore.Moving := mvOut;
          ScoreList.Moving := mvOut;
        end;
      ST_RESTART:
        begin
          Board.Moving := mvOut;
        end;
    end;
  end;
end;

procedure TSquaredGame.SetIsOver(aValue: Boolean);
begin
  if aValue <> FIsOver then begin
    FIsOver := aValue;
    if FIsOver then begin
      NextStateID := ST_GAMEOVER;;
      HighScore.Save;
      // save scorelist on game over
      if not isStartingUp then begin
        if Options.DoC4A then begin
          //add this score to the local high scores
          LocalScores.Add('', Score.Score);
          LocalSCores.SaveTo(
            cCfgFile,
            ScoreList.SaveSection,
            ScoreList.SaveId
          );
          //send score to server
          C4A.Push(Score.Score);
        end
        else begin
          ScoreList.Scores.Add('', Score.Score);
          ScoreList.Save;
          LocalScores.Assign(ScoreList.Scores);
        end;
      end;
    end
  end;
end;

function TSquaredGame.GetNewTile: integer;
begin
  if Random(10) = 0 then
    Result := 2
  else
    Result := 1
  ;
end;

procedure TSquaredGame.SetHint(aValue: string);
begin
  FHint := aValue;
  FShowHintUntil := SDL_GetTicks + ShowHintTime;
end;

function TSquaredGame.GetC4AID: string;
begin
  Result := 'C4A';
  if plThisMonth in C4A.PullOptions then
    Result := Result + '_ThisMonth';
  ;
  if plFiltered in C4A.PullOptions then
    Result := Result + '_Filtered';
  ;
end;

//------------------------------------------------------------------------------
// keyboard handling
//------------------------------------------------------------------------------

procedure TSquaredGame.OnKeyDown(aKey: TSDL_KeyboardEvent);
begin
  case aKey.keysym.sym of
    SDLK_BACKSPACE: //emergency exit
      Owner.Terminate;
    else
      KeyBuffer.Push(aKey);
  end;
end;

procedure TSquaredGame.Move(aDirection: TDirection);
begin
  // no moves while board is still being animated
  if Board.CanMove(aDirection) then begin
    Board.MoveTiles(aDirection);
    if Board.FreeFieldCount > 0 then
      mustPlaceNewTile := TRUE
    ;
  end;
end;

procedure TSquaredGame.OnKeyPush(aKey: TSDL_KeyboardEvent);
var
  ii: integer;
begin
  // speed up running animations
  with Board do begin
    for ii := 0 to FieldCount - 1 do begin

      if Animations[ii] is TPopUpAnimation then begin
        Animations[ii].Velocity := QuickPopUpSpeed;
      end;

      if (Animations[ii] is TFlipAnimation) then begin
        if not (Animations[ii] is TGameOverAnimation) then begin
          Animations[ii].Velocity := QuickFlipSpeed;
        end;
      end;

    end;
  end;
end;

procedure TSquaredGame.OnKeyPop(aKey: TSDL_KeyboardEvent);
begin
  //
end;

//------------------------------------------------------------------------------
// load/save game state
//------------------------------------------------------------------------------

procedure TSquaredGame.Save;
begin
  Score.Save;
  HighScore.Save;
  LocalScores.SaveTo(
    cCfgFile,
    ScoreList.SaveSection,
    ScoreList.SaveID
  );
  Board.Save;
end;

procedure TSquaredGame.Load;
begin
  Score.Load;
  HighScore.Load;
  ScoreList.Load;
  LocalScores.Assign(ScoreList.Scores);
  // init scorelist on first launch of V0.3 or greater
  if (HighScore.Score > ScoreList.Scores.Entry[0].Score) then begin
    ScoreList.Scores.Add(Options.C4A_ShortName, HighScore.Score);
    ScoreList.Save;
  end;
  Board.Load;
  Score.TileNumber := Board.MaxData;
end;

//------------------------------------------------------------------------------
// key handling
//------------------------------------------------------------------------------

procedure TSquaredGame.HandleEvents;
var
  aKey: TSDL_KeyboardEvent;
begin
  if not Board.isAnimating then begin
  //if not Board.isSliding then begin
    if KeyBuffer.KeyCount > 0 then begin

      aKey := KeyBuffer.Pop;

      case aKey.keysym.sym of
        SDLK_ESCAPE:
          NextStateID := ST_EXIT;
        SDLK_UP, SDLK_PAGEUP:
          Move(dirUp);
        SDLK_DOWN, SDLK_PAGEDOWN:
          Move(dirDown);
        SDLK_LEFT, SDLK_HOME:
          Move(dirLeft);
        SDLK_RIGHT, SDLK_END:
          Move(dirRight);
        SDLK_LALT:
          NextStateID := ST_RESTART;
        SDLK_LCTRL, SDLK_a:
          ToggleAnimations;
        SDLK_c:
          ToggleC4A;
        SDLK_m:
          ToggleC4AMode;
      end;
    end;
  end;
end;

//------------------------------------------------------------------------------
// rendering
//------------------------------------------------------------------------------

procedure TSquaredGame.Update;
var
  aNow: integer;
begin
  aNow := SDL_GetTicks;

  HandleEvents;

  inherited Update;

  C4A.Update;
  Title.Update;
  Score.Update;
  HighScore.Update;
  ScoreList.Update;
  Board.Update;

  //*** is hint expired?
  if (aNow > ShowHintUntil) then
    FHint := '';
  ;

  //*** need to place new tile?
  if mustPullC4A then
    PullC4A
  ;

  //*** need to place new tile?
  if mustPlaceNewTile then
    PlaceNewTile
  ;

  //*** want to exit?
  if (NextStateID = ST_EXIT) and (Board.Moving = mvAway) then
    Owner.NextStateID := ST_EXIT
  ;
  //*** want to restart?
  if (NextStateID = ST_RESTART) then begin
    case Board.Moving of
      mvAway:
        begin
          Reset;
          Board.Moving := mvIn;
        end;
      mvHere:
        NextStateID := ST_GAME;
    end;
  end;

  //*** is it over?
  if (NextStateID = ST_GAMEOVER) then begin
    if not Board.isAnimating then begin;
      if not Board.GameOver.isRunning then begin
        Board.GameOver.Start
      end;
    end;
  end;
end;

procedure TSquaredGame.Render;
begin
  //*** render screen output
  inherited;

  if not Board.CanMove then begin
    isOver := TRUE;
  end;

  FIsStartingUp := FALSE;

  Screen.BackgroundColor := Options.ScreenColor;
  Screen.Clear;

  Title.RenderTo(Screen);

  Board.RenderTo(Screen);

  Score.RenderTo(Screen);
  HighScore.RenderTo(Screen);
  ScoreList.RenderTo(Screen);

  RenderHint;

  if Owner.SysInfo.DoShow then RenderDebugInfo;
end;

procedure TSquaredGame.RenderHint;
begin
  if Hint <> '' then begin
    Font.Color := scBlack;
    Screen.WriteText(328, 10, HInt, Font)
  end;
end;

procedure TSquaredGame.RenderDebugInfo;
var
  ii, jj, xx, yy: integer;
begin
  Font.Color := scBlack;
  {
  xx := 0;
  yy := 0;

  for ii := 0 to 15 do begin
    if (Board.Animations[ii] <> nil) and (Board.Animations[ii] is TFlipAnimation) then begin
      xx := TFlipAnimation(Board.Animations[ii]).TempTile.Width;
      yy := TFlipAnimation(Board.Animations[ii]).OrgSize;
      Break;
    end;
  end;
  Screen.WriteText(120, 0, 'Width: ' + IntToStr(xx) + ' Phase: ' + IntToStr(yy), Font);
  }

  {
  xx := 8;
  yy := 8;
  for ii := MinTile to BestTile do begin
    Board.Tile[ii].RenderTo(xx, yy, Screen);
    inc(xx, Board.Tile[ii].Width + 8);
    if xx > (ScreenWidth - Board.Tile[ii].Width + 8) then begin
      inc(yy, Board.Tile[ii].Width + 8);
      xx := 8;
    end;
  end;
  }
  {
  for ii := 0 to Board.Size - 1 do begin
    for jj := 0 to Board.Size - 1 do begin
      if (Board.Animation[ii, jj] <> nil) and (Board.Animation[ii, jj] is TSlideAnimation) then
        Screen.WriteText(32 + ii * 32, 128 + jj * 32, IntToStr(TSlideAnimation(Board.Animation[ii, jj]).ToPos), Font)
      else
        Screen.WriteText(32 + ii * 32, 128 + jj * 32, '0', Font)
      ;
    end;
  end;
  }
  {
  for ii := 0 to Board.Size - 1 do begin
    for jj := 0 to Board.Size - 1 do begin
      Screen.WriteText(32 + ii * 32, 128 + jj * 32, IntToStr(Board.Field[ii, jj]), Font);
    end;
  end;

  Screen.WriteText(32, 288, 'Free; ' + IntToStr(Board.FreeFieldCount), Font);
  Screen.WriteText(32, 320, 'Can Up: ' + BoolToStr(Board.CanMoveUp), Font);
  Screen.WriteText(32, 336, 'Can Dn: ' + BoolToStr(Board.CanMoveDown), Font);
  Screen.WriteText(32, 352, 'Can Lt: ' + BoolToStr(Board.CanMoveLeft), Font);
  Screen.WriteText(32, 368, 'Can Rt: ' + BoolToStr(Board.CanMoveRight), Font);
  }
end;

//------------------------------------------------------------------------------
// score/board
//------------------------------------------------------------------------------

procedure TSquaredGame.Reset;
begin
  FIsOver := FALSE;
  Score.Reset;
  ResetBoard;
end;

procedure TSquaredGame.ResetBoard;
begin
  Board.Reset;
  PlaceNewTile;
  PlaceNewTile;
  Score.TileNumber := Board.MaxData;
end;

procedure TSquaredGame.PlaceNewTile;
const
  PopUpSpeed: array[FALSE..TRUE] of integer =(DefaultPopUpSpeed, QuickPopUpSpeed);
var
  aField: integer;
begin
  with Board do begin
    if not isSliding then begin
      aField := FreeField[Random(FreeFieldCount)];
      Data[aField] := NewTile;
      if DoAnimatePopup then
        Animations[aField] := TPopUpAnimation.Create(Tile[Data[aField]], PopUpSpeed[KeyBuffer.KeyCount > 0])
      ;

      mustPlaceNewTile := FALSE;
    end;
  end;
end;

procedure TSquaredGame.PullC4A;
begin
  if Options.DoC4A then
    C4A.Pull
  ;
  mustPullC4A := FALSE;
end;

procedure TSquaredGame.ToggleAnimations;
begin
  Options.DoAnimate := not Options.DoAnimate;

  if Options.DoAnimate then
    Hint := 'Animations ON'
  else
    Hint := 'Animations OFF'
  ;
end;

procedure TSquaredGame.ToggleC4A;
begin
  if C4A.isAvailable then begin;
    Options.DoC4A := not Options.DoC4A;

    if Options.DoC4A then begin
      Hint := 'C4A support ON';
      PullC4A;;
    end
    else begin
      Hint := 'C4A support OFF';
      ScoreList.ChangeScores('Top', LocalScores);
    end;
  end
  else begin
    Hint := 'C4A not available'
  end;
end;

procedure TSquaredGame.ToggleC4AMode;
begin
  if Options.DoC4A then begin
    if plThisMonth in C4A.PullOptions then begin
      C4A.PullOptions := C4A.PullOptions - [plThisMonth];
    end
    else begin
      C4A.PullOptions := C4A.PullOptions + [plThisMonth];
    end;
    Hint := 'Reading C4A scores';
    PullC4A;
  end;
end;

procedure TSquaredGame.OnC4APulled(aSender: TC4A);
begin
  if (C4A.Error = errC4A_OK) and (C4A.hasScores) then begin
    //save a local copy (just in case the server is not available)
    aSender.Scores.SaveTo(
      cCfgFile,
      ScoreList.SaveSection,
      C4AID
    );
  end
  else begin
    Hint := 'No C4A scores read';
    //show last know c4a scores
    aSender.Scores.LoadFrom(
      cCfgFile,
      ScoreList.SaveSection,
      C4AID
    );
  end;
  if plThisMonth in C4A.PullOptions then
    ScoreList.ChangeScores('C4A (this month)', aSender.Scores)
  else
    ScoreList.ChangeScores('C4A', aSender.Scores)
  ;
end;

procedure TSquaredGame.OnC4APushed(aSender: TC4A);
begin
  Hint := 'C4A score sent';
  mustPullC4A := TRUE;
end;

end.

