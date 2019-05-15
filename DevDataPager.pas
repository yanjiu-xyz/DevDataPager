{
  Delphi分页控件

  版权所有 (c) 研究  QQ:71051699

  (1)、使用许可
  您可以自由复制、分发、修改本源码，但您的修改应该反馈给作者，并允许作者在必要时，
  合并到本项目中以供使用，合并后的源码同样遵循本版权声明限制。
  您的产品的关于中，应包含以下的版本声明:
  本产品使用的分页控件(TDevDataPager)版权归作者所有。

  (2)、技术支持
  有技术问题，您可以加QQ群30311217共同探讨。

  (3)、赞助
  您可以自由使用本源码而不需要支付任何费用。如果您觉得本源码对您有帮助，您可以赞助本项目。

  注：部分代码引用了 Developer Express 的相关单元，如有侵权可联系移除
}

unit DevDataPager;

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, StdCtrls, Math,
  Forms, Graphics, ClipBrd, ExtCtrls, Dialogs, TypInfo, Vcl.Menus,
  Types, UITypes, cxGraphics, dxCoreGraphics,
  cxLookAndFeelPainters, dxGDIPlusClasses, cxLookAndFeels, dxSkinsLookAndFeelPainter,
  cxControls;

const
  PageNumSeparator = '...';
  BtnMinWidth = 35;
  RecordCountWidth = 60;
  GoPageHeight = 22;
  GoPageWidth = 35;
  PageSizeWidth = 50;
  DropDownButtonWidth = 12;

type
  TOnPageNumEvent = procedure(Sender: TObject; APageNum: Integer) of object;
  TOnPageSizeEvent = procedure(Sender: TObject; APageSize: Integer) of object;

  TControlType = (ctLabelRecordCount, ctPriorPage, ctNextPage, ctGoPage, ctGoPageOk, ctGoPageLabelL, ctGoPageLabelR,
    ctFirstPage, ctLastPage, ctPageNum, ctEllipsis, ctPageSize);
  TPageSetting = class;
  TPageNumEdit = class;

  PElementInfo = ^TElementInfo;

  TElementInfo = record
    Caption: string;
    Value: Integer;
    Rect: TRect;
    OffSet: Integer;
    Showing: Boolean;
    Enabled: Boolean;
    ControlType: TControlType;
  end;

  TCustomDevDataPager = class(TcxControl, IdxSkinSupport, IcxLookAndFeelContainer)
  private
    FPageSetting: TPageSetting;
    FPageSizePopup: TPopupMenu;
    FControlList: TList;
    FPageNum: Integer;
    FPageSize: Integer;
    FRecordCount: Integer;
    FOnPageNumEvent: TNotifyEvent;
    FPageNumEdit: TPageNumEdit;

    FOverElement, FDownElement: PElementInfo;
    FOnNextPage: TOnPageNumEvent;
    FOnPriorPage: TOnPageNumEvent;
    FOnGoPage: TOnPageNumEvent;
    FOnPageSize: TOnPageSizeEvent;
    FLookAndFeel: TcxLookAndFeel;
    procedure SetPageNum(const Value: Integer);
    procedure SetPageSize(const Value: Integer);
    procedure SetRecordCount(const Value: Integer);

    procedure WMMouseMove(var Message: TWMMouseMove); message WM_MOUSEMOVE;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure SetLookAndFeel(const Value: TcxLookAndFeel);
    function GetPainter: TcxCustomLookAndFeelPainter;
    function IsUseSkin: Boolean;
  protected
    FOldPageSize: Integer;
    procedure Paint; override;

    procedure Prepare;

    procedure ControlListClear;
    procedure AddElement(AControlType: TControlType; ACaption: string; AEnabled: Boolean; AValue: Integer = -1);
    function GetElementWidth: Integer;
    procedure DrawDataPager;
    procedure DrawPageNums(ACanvas: TcxCanvas; AGraphics: TdxGPGraphics);
    procedure DrawControl(ACanvas: TcxCanvas; AGraphics: TdxGPGraphics; AElementInfo: PElementInfo);

    procedure DrawButtonArrow(ACanvas: TcxCanvas; const R: TRect; AColor: TColor); virtual;
    procedure DrawDropDownButton(ACanvas: TcxCanvas; R: TRect; AFrameColor: TColor; ABrushColor: TColor);

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure DoPageSizeChange(Sender: TObject);
    procedure OnPageNumChange(Sender: TObject);

    procedure ChangeButtonOK;

    procedure DoPageElementEvent(AElementInfo: PElementInfo);
    procedure Resize; override;
    // IcxLookAndFeelContainer
    function GetLookAndFeel: TcxLookAndFeel;

    procedure LookAndFeelChanged(Sender: TcxLookAndFeel; AChangedValues: TcxLookAndFeelValues); override;
{$IFDEF DELPHIBERLIN}
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
{$ELSE}
    procedure ChangeScale(M, D: Integer); override;
{$ENDIF}
    function CalcPageCount: Integer;
    procedure AdjustPageNum;
    procedure SetPageSizeList;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Invalidate; override;

    property Painter: TcxCustomLookAndFeelPainter read GetPainter;

    property PageNum: Integer read FPageNum write SetPageNum default 1;
    property PageSize: Integer read FPageSize write SetPageSize default 50;
    property RecordCount: Integer read FRecordCount write SetRecordCount default 0;
    property Setting: TPageSetting read FPageSetting write FPageSetting;

    property OnPageNum: TNotifyEvent read FOnPageNumEvent write FOnPageNumEvent;
    property OnGoPage: TOnPageNumEvent read FOnGoPage write FOnGoPage;
    property OnPriorPage: TOnPageNumEvent read FOnPriorPage write FOnPriorPage;
    property OnNextPage: TOnPageNumEvent read FOnNextPage write FOnNextPage;
    property OnPageSize: TOnPageSizeEvent read FOnPageSize write FOnPageSize;

    property LookAndFeel: TcxLookAndFeel read FLookAndFeel write SetLookAndFeel;
  end;

  TPageSetting = class(TPersistent)
  private
    FOwner: TComponent;
    FDefaultColor: TColor;
    FActiveColor: TColor;
    FHoverColor: TColor;
    FDownColor: TColor;
    FFrameWidth: Integer;
    FFrameColor: TColor;
    FFont: TFont;
    FArrowColor: TColor;
    FControlHeight: Integer;
    FPageSizeSet: String;
    FShowOKButton: Boolean;
    FBackgroundColor: TColor;
    procedure SetActiveColor(const Value: TColor);
    procedure SetDefaultColor(const Value: TColor);
    procedure SetDownColor(const Value: TColor);
    procedure SetHoverColor(const Value: TColor);
    procedure SetFrameColor(const Value: TColor);
    procedure SetFrameWidth(const Value: Integer);
    procedure SetFont(const Value: TFont);
    procedure SetArrowColor(const Value: TColor);
    procedure SetControlHeight(const Value: Integer);
    procedure SetPageSizeSet(const Value: String);
    procedure SetShowOKButton(const Value: Boolean);
    procedure SetBackgroundColor(const Value: TColor);

    procedure DoChange(Sender: TObject);
  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
  published

    property DefaultColor: TColor read FDefaultColor write SetDefaultColor;
    property ActiveColor: TColor read FActiveColor write SetActiveColor;
    property HoverColor: TColor read FHoverColor write SetHoverColor;
    property DownColor: TColor read FDownColor write SetDownColor;
    property FrameColor: TColor read FFrameColor write SetFrameColor;
    property ArrowColor: TColor read FArrowColor write SetArrowColor;
    property BackgroundColor: TColor read FBackgroundColor write SetBackgroundColor;

    property PageSizeSet: String read FPageSizeSet write SetPageSizeSet;
    property ControlHeight: Integer read FControlHeight write SetControlHeight default 25;
    property FrameWidth: Integer read FFrameWidth write SetFrameWidth default 1;
    property Font: TFont read FFont write SetFont;

    property ShowOKButton: Boolean read FShowOKButton write SetShowOKButton default True;
  end;

  TPageNumEdit = class(TCustomEdit)
  private
    FOwner: TComponent;

    FFrameColor: TColor;
    function GetValue: Integer;
    procedure SetValue(const Value: Integer);
    procedure SetFrameColor(const Value: TColor);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure OnPageNumKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure WMNCPAINT(var msg: TWMNCPaint); message WM_NCPAINT;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Value: Integer read GetValue write SetValue;

    property FrameColor: TColor read FFrameColor write SetFrameColor;
  end;

  TDevDataPager = class(TCustomDevDataPager)
  published
    property Align;
    property Anchors;
    property Enabled;
    property LookAndFeel;
    property PopupMenu;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnMouseEnter;
    property OnMouseLeave;

    property OnClick;

    // property Font;

    property PageNum;
    property PageSize;
    property RecordCount;
    property Setting;

    property OnPageNum;

    property OnGoPage;
    property OnPriorPage;
    property OnNextPage;
    property OnPageSize;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('DataPager', [TDevDataPager]);
end;

function GetDataPagerPainter(ALookAndFeel: TcxLookAndFeel): TcxCustomLookAndFeelPainter;
begin
  Result := ALookAndFeel.Painter;
  if ALookAndFeel.SkinPainter = nil then
  begin
    Result := cxLookAndFeelPaintersManager.GetPainter(lfsSkin);
  end;
end;

{ TPageSetting }

procedure TPageSetting.Assign(Source: TPersistent);
begin
  if Source is TPageSetting then
  begin
    FDefaultColor := TPageSetting(Source).FDefaultColor;
    FActiveColor := TPageSetting(Source).FActiveColor;
    FHoverColor := TPageSetting(Source).FHoverColor;
    FDownColor := TPageSetting(Source).FDownColor;
    FFrameColor := TPageSetting(Source).FFrameColor;
    FArrowColor := TPageSetting(Source).FArrowColor;
    FPageSizeSet := TPageSetting(Source).FPageSizeSet;

    FFrameWidth := TPageSetting(Source).FFrameWidth;

    FFont.Assign(TPageSetting(Source).FFont);
  end;
end;

constructor TPageSetting.Create(AOwner: TComponent);
begin
  inherited Create;
  FFont := TFont.Create;
  FFont.Size := 9;
  FFont.Color := clBlack;
  FFont.Name := 'Tahoma';
  FFont.OnChange := DoChange;
  FOwner := AOwner;

  FDefaultColor := clWhite;
  FActiveColor := clNavy;
  FHoverColor := $00F1F1F1;
  FDownColor := $00F1F1F1;
  FFrameColor := clSilver;
  FArrowColor := clBlack;
  FBackgroundColor := clWhite;
  FFrameWidth := 1;
  FControlHeight := 25;
  FShowOKButton := True;
  FPageSizeSet := '10,20,30,40,50,100,150';
end;

destructor TPageSetting.Destroy;
begin
  FFont.Free;
  inherited Destroy;
end;

procedure TPageSetting.DoChange(Sender: TObject);
begin
  if FOwner is TCustomDevDataPager then
    TCustomDevDataPager(FOwner).Invalidate;
end;

procedure TPageSetting.SetActiveColor(const Value: TColor);
begin
  if Value <> FActiveColor then
  begin
    FActiveColor := Value;
    if FOwner is TCustomDevDataPager then
      TCustomDevDataPager(FOwner).Invalidate;
  end;
end;

procedure TPageSetting.SetArrowColor(const Value: TColor);
begin
  if Value <> FArrowColor then
  begin
    FArrowColor := Value;
    if FOwner is TCustomDevDataPager then
      TCustomDevDataPager(FOwner).Invalidate;
  end;
end;

procedure TPageSetting.SetBackgroundColor(const Value: TColor);
begin
  if Value <> FBackgroundColor then
  begin
    FControlHeight := Value;
    if FOwner is TCustomDevDataPager then
    begin
      TCustomDevDataPager(FOwner).Prepare;
      TCustomDevDataPager(FOwner).Invalidate;
    end;
  end;
end;

procedure TPageSetting.SetControlHeight(const Value: Integer);
begin
  if Value <> FControlHeight then
  begin
    FControlHeight := Value;
    if FOwner is TCustomDevDataPager then
    begin
      TCustomDevDataPager(FOwner).Prepare;
      TCustomDevDataPager(FOwner).Invalidate;
    end;
  end;
end;

procedure TPageSetting.SetDefaultColor(const Value: TColor);
begin
  if Value <> FDefaultColor then
  begin
    FDefaultColor := Value;
    if FOwner is TCustomDevDataPager then
      TCustomDevDataPager(FOwner).Invalidate;
  end;
end;

procedure TPageSetting.SetDownColor(const Value: TColor);
begin
  if Value <> FDownColor then
  begin
    FDownColor := Value;
    if FOwner is TCustomDevDataPager then
      TCustomDevDataPager(FOwner).Invalidate;
  end;
end;

procedure TPageSetting.SetFont(const Value: TFont);
begin
  FFont.Assign(Value);
end;

procedure TPageSetting.SetFrameColor(const Value: TColor);
begin
  if Value <> FFrameColor then
  begin
    FFrameColor := Value;
    if FOwner is TCustomDevDataPager then
    begin
      TCustomDevDataPager(FOwner).Invalidate;
      TCustomDevDataPager(FOwner).FPageNumEdit.FrameColor := FFrameColor;
    end;
  end;
end;

procedure TPageSetting.SetFrameWidth(const Value: Integer);
begin
  if Value <> FFrameWidth then
  begin
    FFrameWidth := Value;
    if FOwner is TCustomDevDataPager then
      TCustomDevDataPager(FOwner).Invalidate;
  end;
end;

procedure TPageSetting.SetHoverColor(const Value: TColor);
begin
  if Value <> FHoverColor then
  begin
    FHoverColor := Value;
    if FOwner is TCustomDevDataPager then
      TCustomDevDataPager(FOwner).Invalidate;
  end;
end;

procedure TPageSetting.SetPageSizeSet(const Value: String);
begin
  if Value <> FPageSizeSet then
  begin
    FPageSizeSet := Value;
    if FOwner is TCustomDevDataPager then
    begin
      // TCustomDevDataPager(FOwner).Prepare;
      TCustomDevDataPager(FOwner).Invalidate;
    end;
  end;
end;

procedure TPageSetting.SetShowOKButton(const Value: Boolean);
begin
  if Value <> FShowOKButton then
  begin
    FShowOKButton := Value;
    if FOwner is TCustomDevDataPager then
    begin
      TCustomDevDataPager(FOwner).Prepare;
      TCustomDevDataPager(FOwner).Invalidate;
    end;
  end;
end;

{ TCustomDevDataPager }

procedure TCustomDevDataPager.AddElement(AControlType: TControlType; ACaption: string; AEnabled: Boolean;
  AValue: Integer);
var
  AHeight, AWidth: Integer;
  ALeft: Integer;
  AElementInfo: PElementInfo;
  ARect: TRect;
begin
  Canvas.Font.Assign(FPageSetting.Font);
  ALeft := GetElementWidth;
  AHeight := FPageSetting.ControlHeight;

  ARect.Left := ALeft;
  ARect.Top := (Height - AHeight) div 2;
  ARect.Height := AHeight;
  if FRecordCount = 0 then
    AWidth := BtnMinWidth + 8
  else
    AWidth := Max(BtnMinWidth, Canvas.TextWidth(ACaption) + 8);
  New(AElementInfo);
  AElementInfo^.OffSet := 0;
  AElementInfo^.Enabled := AEnabled;
  case AControlType of
    ctLabelRecordCount:
      begin
        AElementInfo^.OffSet := 4;
        ARect.Left := ARect.Left + AElementInfo^.OffSet;
        if FRecordCount = 0 then
          AWidth := RecordCountWidth
        else
          AWidth := Max(RecordCountWidth, Canvas.TextWidth(ACaption) + 8);
      end;
    ctPriorPage, ctNextPage, ctFirstPage, ctLastPage, ctPageNum:
      begin
        AElementInfo^.OffSet := 4;
        ARect.Left := ARect.Left + AElementInfo^.OffSet;

      end;
    ctGoPage:
      begin
        AElementInfo^.OffSet := 0;
        ARect.Top := ((Height - AHeight) + (FPageSetting.ControlHeight - GoPageHeight)) div 2;
        ARect.Height := GoPageHeight;
        ARect.Left := ARect.Left + AElementInfo^.OffSet;
        AWidth := GoPageWidth;
      end;
    ctGoPageOk:
      begin
        AElementInfo^.OffSet := 0;
      end;
    ctGoPageLabelL:
      begin
        AElementInfo^.OffSet := 4;
        ARect.Left := ARect.Left + AElementInfo^.OffSet;
        AWidth := AWidth - 10
      end;

    ctGoPageLabelR:
      begin
        AElementInfo^.OffSet := 0;
        ARect.Left := ARect.Left + AElementInfo^.OffSet;
        AWidth := AWidth - 10
      end;
    ctPageSize:
      begin
        AElementInfo^.OffSet := 10;
        ARect.Left := ARect.Left + AElementInfo^.OffSet;
        if FRecordCount = 0 then
          AWidth := PageSizeWidth + DropDownButtonWidth
        else
          AWidth := Max(PageSizeWidth, Canvas.TextWidth(ACaption) + 8) + DropDownButtonWidth;
      end;
    ctEllipsis:
      begin
        AElementInfo^.OffSet := 4;
        ARect.Left := ARect.Left + AElementInfo^.OffSet;
        AElementInfo^.Enabled := False;
      end;
  end;
  ARect.Width := AWidth;
  AElementInfo^.Rect := ARect;
  // AElementInfo^.Left := ALeft + 2 * FControlList.Count;;
  AElementInfo^.Value := AValue;
  AElementInfo^.Caption := ACaption;
  AElementInfo^.Showing := True;

  AElementInfo^.ControlType := AControlType;
  AElementInfo^.Showing := True;

  FControlList.Add(AElementInfo);

end;

procedure TCustomDevDataPager.AdjustPageNum;
var
  R: TRect;
  I: Integer;
  AElementInfo: PElementInfo;
begin
  if FPageNumEdit = nil then
  begin
    FPageNumEdit := TPageNumEdit.Create(Self);
    FPageNumEdit.Width := 0;
    FPageNumEdit.Left := -100;
    FPageNumEdit.Parent := Self;
    FPageNumEdit.Visible := False;
    FPageNumEdit.FrameColor := Setting.FrameColor;
    FPageNumEdit.OnChange := OnPageNumChange;
  end;
  for I := 0 to FControlList.Count - 1 do
  begin
    AElementInfo := PElementInfo(FControlList.Items[I]);
    if AElementInfo.ControlType = ctGoPage then
    begin
      R := AElementInfo.Rect;

      FPageNumEdit.Width := R.Width;
      FPageNumEdit.Height := GoPageHeight;
      FPageNumEdit.Left := R.Left;
      FPageNumEdit.Top := R.Top;
      FPageNumEdit.Value := PageNum;
      if not FPageNumEdit.Visible then
        FPageNumEdit.Visible := RecordCount > 0;

      Break;
    end;
  end;
end;

function TCustomDevDataPager.CalcPageCount: Integer;
begin
  if FPageSize <> 0 then
  begin
    Result := Ceil(FRecordCount / FPageSize);
  end
  else
  begin
    Result := 0;
  end;
end;

{$IFDEF DELPHIBERLIN}

procedure TCustomDevDataPager.ChangeScale(M, D: Integer; isDpiChange: Boolean);
{$ELSE}

procedure TCustomDevDataPager.ChangeButtonOK;
var
  I: Integer;
  AElementInfo: PElementInfo;
begin
  for I := 0 to FControlList.Count - 1 do
  begin
    AElementInfo := PElementInfo(FControlList.Items[I]);
    if AElementInfo.ControlType = ctGoPageOk then
    begin
      AElementInfo.Enabled := PageNum <> FPageNumEdit.Value;
      Invalidate;
      Break;
    end;
  end;
end;

procedure TCustomDevDataPager.ChangeScale(M, D: Integer);
{$ENDIF}
begin
  ScaleFactor.Change(M, D);
  inherited;
  LookAndFeel.Refresh;
end;

procedure TCustomDevDataPager.WMMouseMove(var Message: TWMMouseMove);
var
  CursorPos: TPoint;
  R, TmpRect: TRect;
  I: Integer;
  // i: TPageElementType;
  AElementInfo: PElementInfo;
begin
  inherited;
  if not(csDesigning in ComponentState) then
  begin
    GetCursorPos(CursorPos);
    for I := 0 to FControlList.Count - 1 do
    begin
      AElementInfo := PElementInfo(FControlList.Items[I]);
      R := AElementInfo.Rect;
      if R.Right > 0 then
      begin
        TmpRect.TopLeft := ClientToScreen(R.TopLeft);
        TmpRect.BottomRight := ClientToScreen(R.BottomRight);
        if PtInRect(TmpRect, CursorPos) and (AElementInfo.Enabled) then
        begin
          { if (AElementInfo.ControlType = ctLabelRecordCount) then
            begin
            if Cursor <> crDefault then
            begin
            Cursor := crDefault;
            end;
            FOverElement := nil;
            Break;
            end; }

          FOverElement := AElementInfo;
          if Cursor <> crHandPoint then
          begin
            Cursor := crHandPoint;
            Invalidate;
            Break;
          end;
        end
        else
        begin
          FOverElement := nil;
          if Cursor <> crDefault then
          begin
            Cursor := crDefault;
            Invalidate;
          end;
        end;
      end;
    end;
  end;

end;

procedure TCustomDevDataPager.CMMouseEnter(var Message: TMessage);
begin
  inherited;
end;

procedure TCustomDevDataPager.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if Self.Cursor <> crDefault then
    Self.Cursor := crDefault;

  Invalidate;
end;

procedure TCustomDevDataPager.ControlListClear;
var
  I: Integer;
  AElementInfo: PElementInfo;
begin
  for I := FControlList.Count - 1 downto 0 do
  begin
    AElementInfo := PElementInfo(FControlList.Items[I]);
    Dispose(AElementInfo);
  end;
  FControlList.Clear;
end;

constructor TCustomDevDataPager.Create(AOwner: TComponent);
begin
  inherited;
  FControlList := TList.Create;
  Font.Size := 9;

  Height := 35;
  Width := 700;

  FPageNum := 1;
  FPageSize := 50;

  FOldPageSize := PageSize;
  Color := clWhite;

  FPageSetting := TPageSetting.Create(Self);

  FLookAndFeel := TcxLookAndFeel.Create(Self);
  FLookAndFeel.OnChanged := LookAndFeelChanged;

  Prepare;
  // RecordCount := 0;
  // Invalidate;
end;

procedure TCustomDevDataPager.SetPageSizeList;
var
  PageSize_ARR: TArray<string>;
  APageSize: String;
  I: Integer;
  AItem: TMenuItem;
begin
  if FPageSizePopup = nil then
  begin
    FPageSizePopup := TPopupMenu.Create(Self);
    FPageSizePopup.AutoHotkeys := maManual;
  end;
  PageSize_ARR := FPageSetting.PageSizeSet.Split([',']);
  FPageSizePopup.Items.Clear;
  for I := 0 to Length(PageSize_ARR) - 1 do
  begin
    APageSize := PageSize_ARR[I];

    AItem := TMenuItem.Create(FPageSizePopup);
    AItem.Caption := Format('%s 条/页', [APageSize]);
    AItem.Tag := StrToIntDef(APageSize, 10);
    AItem.OnClick := DoPageSizeChange;
    FPageSizePopup.Items.Add(AItem);
  end;

end;

destructor TCustomDevDataPager.Destroy;
begin
  FPageSetting.Free;
  FreeAndNil(FLookAndFeel);
  ControlListClear;
  FControlList.Free;
  if FPageSizePopup <> nil then
    FPageSizePopup.Free;
  inherited;
end;

procedure TCustomDevDataPager.DoPageElementEvent(AElementInfo: PElementInfo);
var
  p: TPoint;
  APageNum: Integer;
begin
  if AElementInfo = nil then
    exit;

  case AElementInfo.ControlType of
    ctLabelRecordCount, ctEllipsis:
      begin

      end;
    ctPriorPage:
      begin
        if PageNum = 1 then
          exit;

        PageNum := PageNum - 1;
        if Assigned(FOnPriorPage) then
          FOnPriorPage(Self, PageNum);
      end;
    ctNextPage:
      begin
        if PageNum = CalcPageCount then
          exit;
        PageNum := PageNum + 1;
        if Assigned(FOnNextPage) then
          FOnNextPage(Self, PageNum);
      end;
    ctGoPageOk:
      begin
        APageNum := FPageNumEdit.Value;
        if PageNum <> APageNum then
        begin
          PageNum := APageNum;
          if Assigned(FOnGoPage) then
            FOnGoPage(Self, PageNum);
        end;
      end;
    ctGoPage, ctFirstPage, ctLastPage, ctPageNum:
      begin
        APageNum := AElementInfo.Value;
        if PageNum <> APageNum then
        begin
          PageNum := APageNum;
          if Assigned(FOnGoPage) then
            FOnGoPage(Self, PageNum);
        end;
      end;
    ctPageSize:
      begin
        SetPageSizeList;
        p.X := AElementInfo.Rect.Left;
        p.Y := AElementInfo.Rect.Top;
        p.Y := p.Y + AElementInfo.Rect.Height;
        p := Self.ClientToScreen(p);
        FPageSizePopup.Popup(p.X, p.Y);

      end;
  end;
end;

procedure TCustomDevDataPager.DoPageSizeChange(Sender: TObject);
var
  AItem: TMenuItem;
begin
  AItem := TMenuItem(Sender);
  PageSize := AItem.Tag;
  if Assigned(FOnPageSize) then
    FOnPageSize(Self, PageSize);
end;

procedure TCustomDevDataPager.DrawDataPager;
var
  AGraphics: TdxGPGraphics;
begin
  inherited;
  AGraphics := dxGpBeginPaint(Canvas.Handle, Self.ClientBounds);
  try
    AGraphics.SmoothingMode := smAntiAlias;
    if IsUseSkin then
    begin
      Color := Painter.DefaultContentColor;
    end
    else
    begin
      Color := FPageSetting.BackgroundColor;
    end;
    DrawPageNums(Canvas, AGraphics);
  finally
    dxGpEndPaint(AGraphics);
  end;

end;

procedure TCustomDevDataPager.DrawDropDownButton(ACanvas: TcxCanvas; R: TRect; AFrameColor: TColor;
  ABrushColor: TColor);

  function GetArrowColor: TColor;
  begin
    Result := FPageSetting.FArrowColor;
  end;

begin
  ACanvas.FrameRect(R, AFrameColor);
  InflateRect(R, -1, -1);
  ACanvas.Brush.Color := ABrushColor;
  ACanvas.FillRect(R);
  DrawButtonArrow(ACanvas, R, GetArrowColor);
end;

procedure TCustomDevDataPager.DrawPageNums(ACanvas: TcxCanvas; AGraphics: TdxGPGraphics);
var
  FElementInfo: PElementInfo;
  I: Integer;
begin
  for I := 0 to FControlList.Count - 1 do
  begin
    FElementInfo := PElementInfo(FControlList.Items[I]);
    if FElementInfo.Showing then
    begin
      DrawControl(ACanvas, AGraphics, FElementInfo);
    end;
  end;

end;

function TCustomDevDataPager.GetElementWidth: Integer;
var
  I: Integer;
  FElementInfo: PElementInfo;
begin
  Result := 0;
  for I := 0 to FControlList.Count - 1 do
  begin
    FElementInfo := PElementInfo(FControlList.Items[I]);
    if FElementInfo.Showing then
    begin
      Result := Result + FElementInfo.Rect.Width + FElementInfo.OffSet;
    end;
  end;
end;

function TCustomDevDataPager.GetLookAndFeel: TcxLookAndFeel;
begin
  Result := LookAndFeel;
end;

function TCustomDevDataPager.GetPainter: TcxCustomLookAndFeelPainter;
begin
  Result := GetDataPagerPainter(LookAndFeel);
end;

procedure TCustomDevDataPager.Invalidate;
begin

  inherited;

end;

function TCustomDevDataPager.IsUseSkin: Boolean;
begin
  Result := (not LookAndFeel.NativeStyle) and (LookAndFeel.Kind = lfUltraFlat);
end;

procedure TCustomDevDataPager.LookAndFeelChanged(Sender: TcxLookAndFeel; AChangedValues: TcxLookAndFeelValues);
begin
  Invalidate;
end;

procedure TCustomDevDataPager.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if (Button = mbLeft) and Enabled then
  begin
    FDownElement := FOverElement;
  end;
  Invalidate;
end;

procedure TCustomDevDataPager.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    DoPageElementEvent(FDownElement);
    FDownElement := nil;
    FOverElement := FDownElement;
  end;
  Invalidate;
end;

procedure TCustomDevDataPager.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
end;

procedure TCustomDevDataPager.OnPageNumChange(Sender: TObject);
begin
  ChangeButtonOK;
end;

procedure TCustomDevDataPager.DrawButtonArrow(ACanvas: TcxCanvas; const R: TRect; AColor: TColor);
var
  p: array [0 .. 2] of TPoint;
  procedure CalculatePoints;
  var
    ASize: TPoint;
    function _GetSize: TPoint;
    begin
      Result.X := (R.Right - R.Left) div 2;
      if not Odd(Result.X) then
        Inc(Result.X);
      Result.Y := Result.X div 2 + 1;
    end;

  begin
    with R do
    begin
      ASize := _GetSize;
      p[0] := Point((Left + Right - ASize.X) div 2, MulDiv(Top + Bottom - ASize.Y, 1, 2));
      p[1] := Point(p[0].X + ASize.X - 1, p[0].Y);
      p[2] := Point(p[0].X + ASize.X div 2, p[0].Y + ASize.Y - 1);
    end;
  end;

begin
  CalculatePoints;
  ACanvas.Brush.Color := AColor;
  ACanvas.Pen.Color := AColor;
  ACanvas.Polygon(p);
end;

procedure TCustomDevDataPager.DrawControl(ACanvas: TcxCanvas; AGraphics: TdxGPGraphics; AElementInfo: PElementInfo);
const
  RadiusX = 0;
  RadiusY = 0;
  procedure DrawText;
  var
    X, Y: Integer;
    AFont: TFont;
    AText: string;
    ARect: TRect;
    AFontColor: TColor;
  begin
    AFontColor := FPageSetting.Font.Color;
    AFont := FPageSetting.Font;
    AText := AElementInfo.Caption;
    ARect := AElementInfo.Rect;
    if AElementInfo.ControlType = ctPageSize then
      ARect.Width := ARect.Width - DropDownButtonWidth;

    X := ARect.Left + (ARect.Width - ACanvas.TextWidth(AText)) div 2;
    Y := ARect.Top + (ARect.Height - ACanvas.TextHeight(AText)) div 2;
    ACanvas.Brush.Style := bsClear;

    ACanvas.Font := AFont;

    if FPageNum.ToString.Equals(AElementInfo.Caption) then
    begin
      ACanvas.Font.Color := clWhite;
    end
    else
    begin
      if not AElementInfo.Enabled then
        ACanvas.Font.Color := clGray
      else
        ACanvas.Font.Color := AFontColor;
    end;
    ACanvas.TextOut(X, Y, AText);
  end;

  procedure DrawButton;
  var
    APen: TdxGPPen;
    ABrush: TdxGPBrush;
    ABrushColor, AFrameColor: TColor;
  begin
    if AElementInfo.Enabled then
    begin
      if FPageNum.ToString.Equals(AElementInfo.Caption) then
      begin
        ABrushColor := FPageSetting.ActiveColor;
      end
      else
      begin
        if FOverElement = AElementInfo then
          ABrushColor := FPageSetting.HoverColor
        else
          ABrushColor := FPageSetting.DefaultColor;
      end;
      AFrameColor := FPageSetting.FrameColor;
    end
    else
    begin
      ABrushColor := FPageSetting.DefaultColor;
      AFrameColor := clBtnFace;
    end;

    APen := TdxGPPen.Create(TdxAlphaColors.FromColor(AFrameColor), FPageSetting.FrameWidth, psSolid);
    ABrush := TdxGPBrush.Create;
    ABrush.Color := TdxAlphaColors.FromColor(ABrushColor);
    try
      AGraphics.RoundRect(AElementInfo.Rect, APen, ABrush, RadiusX, RadiusY);
    finally
      ABrush.Free;
      APen.Free;
    end;
  end;

  procedure DrawSkinButton;
  begin
    if AElementInfo.Enabled then
    begin
      if FPageNum.ToString.Equals(AElementInfo.Caption) then
      begin
        Painter.DrawButton(ACanvas, AElementInfo.Rect, AElementInfo.Caption, cxbsPressed, True);
      end
      else
      begin
        if FOverElement = AElementInfo then
          Painter.DrawButton(ACanvas, AElementInfo.Rect, AElementInfo.Caption, cxbsHot, True)
        else
          Painter.DrawButton(ACanvas, AElementInfo.Rect, AElementInfo.Caption, cxbsNormal, True);
      end;
    end
    else
    begin
      Painter.DrawButton(ACanvas, AElementInfo.Rect, AElementInfo.Caption, cxbsDisabled, True);
    end;

  end;

  procedure DrawPageSize;
  var
    APen: TdxGPPen;
    ABrush: TdxGPBrush;
    AFrameColor, ABrushColor: TColor;
    ARect: TRect;
  begin
    ARect := AElementInfo.Rect;
    if IsUseSkin then
    begin
      AFrameColor := TdxSkinLookAndFeelPainter(Painter).SkinInfo.ContainerBorderColor.Value;
      if FOverElement = AElementInfo then
      begin
        ABrushColor := Painter.DefaultContentColor;
        AFrameColor := Painter.DefaultSelectionColor;
      end
      else
        ABrushColor := Painter.DefaultControlColor;
    end
    else
    begin
      AFrameColor := FPageSetting.FrameColor;
      if FOverElement = AElementInfo then
        ABrushColor := FPageSetting.HoverColor
      else
        ABrushColor := FPageSetting.DefaultColor;
    end;

    APen := TdxGPPen.Create(TdxAlphaColors.FromColor(AFrameColor), FPageSetting.FrameWidth, psSolid);
    ABrush := TdxGPBrush.Create;
    ABrush.Color := TdxAlphaColors.FromColor(ABrushColor);
    try

      ARect.Width := ARect.Width - DropDownButtonWidth;
      AGraphics.RoundRect(ARect, APen, ABrush, 0, 0);
    finally
      ABrush.Free;
      APen.Free;
    end;

    // 画下拉箭头
    ARect.Left := ARect.Left + ARect.Width - 1;
    ARect.Width := DropDownButtonWidth;
    DrawDropDownButton(ACanvas, ARect, AFrameColor, ABrushColor);

  end;

begin

  case AElementInfo.ControlType of
    ctLabelRecordCount:
      begin
        DrawText;
      end;
    ctPriorPage, ctNextPage, ctFirstPage, ctLastPage, ctPageNum, ctGoPageOk, ctEllipsis:
      begin
        if IsUseSkin then
        begin
          DrawSkinButton;
        end
        else
        begin
          DrawButton;
          DrawText;
        end;
      end;
    ctGoPage:
      begin
        // DrawButton;
      end;
    ctGoPageLabelL, ctGoPageLabelR:
      begin
        DrawText;
      end;
    ctPageSize:
      begin
        DrawPageSize;
        DrawText;
      end;
  end;

end;

procedure TCustomDevDataPager.Paint;
begin
  inherited;
  DrawDataPager;
end;

procedure TCustomDevDataPager.Prepare;
var
  APageCount: Integer;
  I: Integer;
  OldFont: TFont;
begin
  OldFont := Font;
  try
    APageCount := CalcPageCount;
    ControlListClear;

    if APageCount > 0 then
    begin

      if (FPageNum = 1) then
      begin
        AddElement(ctPriorPage, '上一页', False)
      end
      else
      begin
        AddElement(ctPriorPage, '上一页', True);
      end;

      if APageCount <= 9 then
      begin
        for I := 1 to APageCount do
        begin
          AddElement(ctPageNum, I.ToString, True, I);
        end;
      end
      else
      begin
        if (PageNum > 3) and ((PageNum + 1) < APageCount) then
        begin
          for I := 1 to 1 do
          begin
            AddElement(ctPageNum, I.ToString, True, I);
          end;
          if (PageNum - 2) = 2 then
            AddElement(ctPageNum, '2', True, 2)
          else
            AddElement(ctEllipsis, PageNumSeparator, False);

          for I := PageNum - 1 to PageNum + 1 do
          begin
            AddElement(ctPageNum, I.ToString, True, I);
          end;

          if (PageNum + 2) = APageCount - 1 then
            AddElement(ctPageNum, IntToStr(PageNum + 2), True, PageNum + 2)
          else
          begin
            if (PageNum + 2) <> APageCount then
              AddElement(ctEllipsis, PageNumSeparator, False);
          end;

          for I := APageCount to APageCount do
          begin
            AddElement(ctPageNum, I.ToString, True, I);
          end;
        end
        else
        begin
          for I := 1 to 3 do
          begin
            AddElement(ctPageNum, I.ToString, True, I);
          end;
          AddElement(ctEllipsis, PageNumSeparator, False);
          for I := APageCount - 2 to APageCount do
          begin
            AddElement(ctPageNum, I.ToString, True, I);
          end;
        end;
      end;
      if (FPageNum = APageCount) then
        AddElement(ctNextPage, '下一页', False)
      else
        AddElement(ctNextPage, '下一页', True);
      AddElement(ctGoPageLabelL, '到第', False);
      AddElement(ctGoPage, FPageNum.ToString, True);
      AddElement(ctGoPageLabelR, '页', False);
      if FPageSetting.ShowOKButton then
        AddElement(ctGoPageOk, '确定', False);
      AddElement(ctPageSize, Format('%d条/页', [PageSize]), True);
    end;
    AddElement(ctLabelRecordCount, Format('共 %d 条记录', [RecordCount]), False);

    if RecordCount > 0 then
      AdjustPageNum;
  finally
    Font := OldFont;
  end;
end;

procedure TCustomDevDataPager.Resize;
begin
  Prepare;
  Invalidate;
  inherited Resize;
end;

procedure TCustomDevDataPager.SetLookAndFeel(const Value: TcxLookAndFeel);
begin
  FLookAndFeel.Assign(Value);
end;

procedure TCustomDevDataPager.SetPageNum(const Value: Integer);
var
  APageCount, OldPageNum: Integer;
begin
  if Value <> FPageNum then
  begin

    OldPageNum := FPageNum;
    if Value <= 0 then
    begin
      FPageNum := 1;
    end
    else
    begin
      APageCount := CalcPageCount;
      FPageNum := Value;
      if Value > APageCount then
      begin
        FPageNum := APageCount;
      end;
      if FPageNum <= 0 then
        FPageNum := 1;
    end;
    Prepare;
    if (OldPageNum <> FPageNum) and Assigned(FOnPageNumEvent) then
      FOnPageNumEvent(Self);
    FPageNumEdit.Value := FPageNum;
    ChangeButtonOK;
    Invalidate;
  end;
end;

procedure TCustomDevDataPager.SetPageSize(const Value: Integer);
begin
  if Value <> FPageSize then
  begin
    if Value <= 10 then
    begin
      FPageSize := 10;
    end
    else
    begin
      FPageSize := Value;
    end;

    if (CalcPageCount > 0) and (FPageNum > CalcPageCount) then
    begin
      FPageNum := CalcPageCount;
    end
    else
    begin
      FPageNum := 1;
    end;

    FOldPageSize := FPageSize;
    Prepare;
    if Assigned(FOnPageNumEvent) then
      FOnPageNumEvent(Self);
    Invalidate;
  end;
end;

procedure TCustomDevDataPager.SetRecordCount(const Value: Integer);
begin
  if Value <> FRecordCount then
  begin
    if Value <= 0 then
    begin
      FRecordCount := 0;
      FPageNum := 1;
      if FPageNumEdit <> nil then
        FreeAndNil(FPageNumEdit);
    end
    else
    begin
      FRecordCount := Value;
      if CalcPageCount > 0 then
      begin
        if FPageNum > CalcPageCount then
        begin
          FPageNum := CalcPageCount;
        end;
      end
      else
        FPageNum := 1;
    end;
    Prepare;
    Invalidate;
  end;
end;

{ TPageNumEdit }

constructor TPageNumEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FOwner := AOwner;
  OnKeyDown := OnPageNumKeyDown;

end;

procedure TPageNumEdit.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do
  begin
    Style := Style or ES_CENTER or ES_NUMBER;
  end;
end;

destructor TPageNumEdit.Destroy;
begin

  inherited;
end;

function TPageNumEdit.GetValue: Integer;
begin
  Result := StrToIntDef(Text, 1);
end;

procedure TPageNumEdit.OnPageNumKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if FOwner = nil then
    exit;
  if Key = 13 then
  begin
    TCustomDevDataPager(FOwner).PageNum := Value;
    SelectAll;
  end;
end;

procedure TPageNumEdit.SetFrameColor(const Value: TColor);
begin
  if FFrameColor <> Value then
  begin
    FFrameColor := Value;
    Invalidate;
  end;
end;

procedure TPageNumEdit.SetValue(const Value: Integer);
begin
  Text := IntToStr(Value);
end;

procedure TPageNumEdit.WMNCPAINT(var msg: TWMNCPaint);
var
  DC: HDC;
  BorderBrush: HBRUSH;
  R: TRect;
  AFrameColor: TColor;
begin
  inherited;
  if FOwner = nil then
    exit;
  AFrameColor := FFrameColor;
  SetRect(R, 0, 0, Width, Height);
  DC := GetWindowDC(Handle);
  try
    SetRect(R, 0, 0, Width, Height);

    BorderBrush := CreateSolidBrush(AFrameColor);
    FrameRect(DC, R, BorderBrush); // 绘制边线框
    DeleteObject(BorderBrush);
  finally
    ReleaseDC(Handle, DC)
  end;

end;

end.


