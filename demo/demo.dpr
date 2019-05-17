program demo;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {frmMain},
  DevDataPager in '..\DevDataPager.pas';

{$R *.res}

begin
 ReportMemoryLeaksOnShutdown:=True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
