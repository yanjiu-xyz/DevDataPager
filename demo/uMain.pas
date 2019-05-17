unit uMain;

interface

uses
  DevDataPager,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Mask ;

type
  TfrmMain = class(TForm)
    DevDataPager2: TDevDataPager;
    DevDataPager3: TDevDataPager;
    DevDataPager4: TDevDataPager;
    DevDataPager5: TDevDataPager;
    Memo1: TMemo;
    DevDataPager6: TDevDataPager;
    DevDataPager1: TDevDataPager;
    DevDataPager7: TDevDataPager;
    CheckBox1: TCheckBox;
    procedure Button1Click(Sender: TObject);
    procedure DevDataPager3GoPage(Sender: TObject; APageNum: Integer);
    procedure DevDataPager3NextPage(Sender: TObject; APageNum: Integer);
    procedure DevDataPager3PriorPage(Sender: TObject; APageNum: Integer);
    procedure DevDataPager1PageNum(Sender: TObject);
    procedure DevDataPager1PageSize(Sender: TObject; APageSize: Integer);
  private
    { Private declarations }
    // FDataPager: TDevDataPager;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.Button1Click(Sender: TObject);
begin
  // FDataPager.RecordCount := StrToInt(LabeledEdit1.Text);
  // FDataPager.PageNum := StrToInt(edPageNum.Text);
  // FDataPager.PageSizeSet := LabeledEdit2.Text;
end;

procedure TfrmMain.DevDataPager1PageNum(Sender: TObject);
begin
  if CheckBox1.Checked then     
    Memo1.Lines.Add(Format('PageNum:%d', [TDevDataPager(Sender).PageNum]));
end;

procedure TfrmMain.DevDataPager1PageSize(Sender: TObject; APageSize: Integer);
begin
  Memo1.Lines.Add(Format('每页%d行', [APageSize]))
end;

procedure TfrmMain.DevDataPager3GoPage(Sender: TObject; APageNum: Integer);
begin
  Memo1.Lines.Add(Format('到第%d页,每页%d行', [APageNum, TDevDataPager(Sender).PageSize]));
end;

procedure TfrmMain.DevDataPager3NextPage(Sender: TObject; APageNum: Integer);
begin
  Memo1.Lines.Add(Format('点击下一页%d,每页%d行', [APageNum, TDevDataPager(Sender).PageSize]));
end;

procedure TfrmMain.DevDataPager3PriorPage(Sender: TObject; APageNum: Integer);
begin
  Memo1.Lines.Add(Format('点击上一页%d,每页%d行', [APageNum, TDevDataPager(Sender).PageSize]));
end;

end.
