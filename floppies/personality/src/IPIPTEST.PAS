program IPIPTest;

uses
  App, Objects, Drivers, Views, Dialogs, Menus, MsgBox;

const
  cmStartTest = 1001;
  cmAbout = 1002;
  cmCloseResults = 1003;
  cmAnswer1 = 1101;
  cmAnswer2 = 1102;
  cmAnswer3 = 1103;
  cmAnswer4 = 1104;
  cmAnswer5 = 1105;
  QuestionCount = 20;
  TraitCount = 5;

type
  TQuestion = record
    Text: string[120];
    Trait: Byte;
    Reverse: Boolean;
  end;

  PQuestionDialog = ^TQuestionDialog;
  TQuestionDialog = object(TDialog)
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PResultsDialog = ^TResultsDialog;
  TResultsDialog = object(TDialog)
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  TPersonalityApp = object(TApplication)
    procedure InitDeskTop; virtual;
    procedure InitMenuBar; virtual;
    procedure InitStatusLine; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure RunTest;
    procedure ShowResults(var Scores: array of Integer);
  end;

const
  TraitNames: array[1..TraitCount] of string[19] =
    ('OPENNESS', 'CONSCIENTIOUS', 'EXTRAVERSION', 'AGREEABLENESS',
     'EMOTIONAL STABILITY');

  Questions: array[1..QuestionCount] of TQuestion = (
    (Text: 'I have a vivid imagination.'; Trait: 1; Reverse: False),
    (Text: 'I am not interested in abstract ideas.'; Trait: 1; Reverse: True),
    (Text: 'I enjoy thinking about new ways to do things.'; Trait: 1; Reverse: False),
    (Text: 'I prefer work that is familiar and routine.'; Trait: 1; Reverse: True),
    (Text: 'I like to keep my belongings neat and orderly.'; Trait: 2; Reverse: False),
    (Text: 'I often forget to put things back in their place.'; Trait: 2; Reverse: True),
    (Text: 'I follow through on my plans.'; Trait: 2; Reverse: False),
    (Text: 'I leave tasks unfinished.'; Trait: 2; Reverse: True),
    (Text: 'I feel comfortable around people.'; Trait: 3; Reverse: False),
    (Text: 'I do not talk a lot.'; Trait: 3; Reverse: True),
    (Text: 'I start conversations.'; Trait: 3; Reverse: False),
    (Text: 'I prefer to be alone.'; Trait: 3; Reverse: True),
    (Text: 'I make people feel welcome.'; Trait: 4; Reverse: False),
    (Text: 'I insult people.'; Trait: 4; Reverse: True),
    (Text: 'I sympathize with others'' feelings.'; Trait: 4; Reverse: False),
    (Text: 'I am not really interested in others.'; Trait: 4; Reverse: True),
    (Text: 'I am relaxed most of the time.'; Trait: 5; Reverse: False),
    (Text: 'I get upset easily.'; Trait: 5; Reverse: True),
    (Text: 'I seldom feel blue.'; Trait: 5; Reverse: False),
    (Text: 'I worry about things.'; Trait: 5; Reverse: True)
  );

function MakeRect(X1, Y1, X2, Y2: Integer): TRect;
begin
  MakeRect.Assign(X1, Y1, X2, Y2);
end;

procedure AddText(D: PDialog; X1, Y1, X2, Y2: Integer; Text: string);
var
  R: TRect;
begin
  R.Assign(X1, Y1, X2, Y2);
  D^.Insert(New(PStaticText, Init(R, Text)));
end;

procedure AddButton(D: PDialog; X1, Y1, X2, Y2: Integer;
  Title: string; Command: Word; Flags: Word);
var
  R: TRect;
begin
  R.Assign(X1, Y1, X2, Y2);
  D^.Insert(New(PButton, Init(R, Title, Command, Flags)));
end;

procedure TQuestionDialog.HandleEvent(var Event: TEvent);
var
  Command: Word;
begin
  if Event.What = evKeyDown then begin
    Command := 0;
    case Event.CharCode of
      '1': Command := cmAnswer1;
      '2': Command := cmAnswer2;
      '3': Command := cmAnswer3;
      '4': Command := cmAnswer4;
      '5': Command := cmAnswer5;
      #13, #27: begin
        ClearEvent(Event);
        Exit;
      end;
    end;
    if Command <> 0 then begin
      EndModal(Command);
      ClearEvent(Event);
      Exit;
    end;
  end;
  TDialog.HandleEvent(Event);
end;

procedure TResultsDialog.HandleEvent(var Event: TEvent);
begin
  if Event.What = evKeyDown then begin
    if Event.CharCode = #13 then begin
      ClearEvent(Event);
      Exit;
    end;
    if Event.CharCode = #27 then begin
      EndModal(cmCloseResults);
      ClearEvent(Event);
      Exit;
    end;
  end;
  TDialog.HandleEvent(Event);
end;

function AskQuestion(Number: Integer): Integer;
var
  D: PQuestionDialog;
  R: TRect;
  Answer: Word;
  NumberText: string[3];
begin
  R.Assign(3, 2, 77, 21);
  D := New(PQuestionDialog, Init(R, 'IPIP PERSONALITY TEST'));
  Str(Number, NumberText);
  AddText(D, 2, 1, 70, 2, 'Question ' + NumberText + ' of 20');
  AddText(D, 2, 2, 70, 5, Questions[Number].Text);
  AddText(D, 2, 6, 70, 7, 'Press 1-5 to answer');
  AddText(D, 2, 8, 23, 9, '1  Strongly disagree');
  AddText(D, 25, 8, 48, 9, '2  Disagree');
  AddText(D, 50, 8, 71, 9, '3  Neither');
  AddText(D, 2, 11, 23, 12, '4  Agree');
  AddText(D, 25, 11, 48, 12, '5  Strongly agree');
  Answer := Application^.ExecView(D);
  Dispose(D, Done);
  if Answer < cmAnswer1 then Answer := cmAnswer3;
  AskQuestion := Answer - 1100;
end;

procedure TPersonalityApp.ShowResults(var Scores: array of Integer);
var
  I, Percent: Integer;
  PercentText: string[6];
  S: string;
  D: PResultsDialog;
  R: TRect;
begin
  S := 'YOUR BIG FIVE PROFILE' + #13#10 + #13#10;
  for I := 1 to TraitCount do begin
    Percent := ((Scores[I] - 4) * 100) div 16;
    if Percent < 0 then Percent := 0;
    if Percent > 100 then Percent := 100;
    Str(Percent, PercentText);
    S := S + TraitNames[I] + ': ' + PercentText + '/100' + #13#10;
  end;
  S := S + #13#10 + 'Higher scores indicate more of that trait.' + #13#10 +
        'This is for reflection, not diagnosis.';
  R.Assign(10, 3, 70, 19);
  D := New(PResultsDialog, Init(R, 'YOUR RESULTS'));
  AddText(D, 2, 2, 58, 12, S);
  AddText(D, 2, 12, 58, 13, 'Press Esc to return to the test menu.');
  AddButton(D, 22, 13, 36, 15, '~O~K', cmCloseResults, bfNormal);
  Application^.ExecView(D);
  Dispose(D, Done);
end;

procedure TPersonalityApp.RunTest;
var
  Scores: array[1..TraitCount] of Integer;
  I, Answer: Integer;
begin
  for I := 1 to TraitCount do Scores[I] := 0;
  for I := 1 to QuestionCount do begin
    Answer := AskQuestion(I);
    if Questions[I].Reverse then Answer := 6 - Answer;
    Scores[Questions[I].Trait] := Scores[Questions[I].Trait] + Answer;
  end;
  ShowResults(Scores);
end;

procedure TPersonalityApp.InitDeskTop;
var
  R: TRect;
begin
  TApplication.InitDeskTop;
  R.Assign(20, 8, 60, 13);
  DeskTop^.Insert(New(PStaticText, Init(R,
    'IPIP PERSONALITY TEST' + #13#10 + #13#10 +
    'Press Enter to start the test.')));
end;

procedure TPersonalityApp.InitMenuBar;
var
  R: TRect;
begin
  GetExtent(R);
  MenuBar := New(PMenuBar,
    Init(R,
      NewMenu(
        NewSubMenu('~T~est', hcNoContext,
          NewMenu(
            NewItem('~S~tart test', 'S', kbF2, cmStartTest, hcNoContext,
              NewLine(
                NewItem('~A~bout', 'A', kbF3, cmAbout, hcNoContext, nil)
              )
            )
          ),
          nil
        )
      )
    )
  );
end;

procedure TPersonalityApp.InitStatusLine;
var
  R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  StatusLine := New(PStatusLine, Init(R,
    NewStatusDef(0, $FFFF,
      NewStatusKey('~F2~ Test', kbF2, cmStartTest,
      NewStatusKey('~F10~ Menu', kbF10, cmMenu,
      NewStatusKey('', kbAltX, cmQuit, nil))), nil)));
end;

procedure TPersonalityApp.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evKeyDown) and (Event.CharCode = #13) then begin
    ClearEvent(Event);
    RunTest;
    Exit;
  end;
  TApplication.HandleEvent(Event);
  if Event.What = evCommand then begin
    case Event.Command of
      cmStartTest: begin ClearEvent(Event); RunTest end;
      cmAbout: begin ClearEvent(Event);
        MessageBox('IPIPTEST 1.0^M^J^M^J' +
          'A short IPIP-style Big Five questionnaire.^M^J' +
          'IPIP items are provided for public use.^M^J' +
          'Results are not a psychological diagnosis.', nil,
          mfInformation or mfOKButton);
      end;
    end;
  end;
end;

var
  AppInstance: TPersonalityApp;

begin
  AppInstance.Init;
  AppInstance.Run;
  AppInstance.Done;
end.
