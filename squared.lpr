program squared;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils,
  { you can add units after this }
  sdlclasses, sdlfonts, sdltypes, sdlappstates, sdlsprites, sdltiles, consts,
  game, main, board, sdlgui, fx, gui, tiles, sdlkeybuffer, resources, menu,
  c4a, highscores;

var
  Application: TSquaredApp;

{$R *.res}

begin
  Application := TSquaredApp.Create(nil);
  Application.Title := 'Squared';
  Application.Run;
  Application.Free;
  {
  if FileExists('squared.log') then DeleteFile('squared.log');

  SetHeapTraceOutput('squared.log');
  DumpHeap;
  }
end.

