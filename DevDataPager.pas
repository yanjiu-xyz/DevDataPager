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

{
  beta 版本
  初始版本提交

  ===================

  + 增加 Dev依赖编译指令，默认为关闭状态,在Defs.inc文件取消注释即可
  + 增加 字体及颜色定义属性
  * 修正 cpu占用过高的问题
  * 调整了部分属性名称
  ===================

  2019.10.29

  * 修复 记录总数为0时鼠标移到控件时出错误
  + 增加 内部控件的文本属性
  * 优化 分页操作的逻辑
  * 调整 公布GetElementWidth方法

  ===================
  2019.10.31

  * 修正 切换页面时刷新问题
  * 修正 使用Dev皮肤时出错的问题
  + 增加 内部控件最小宽度

  ===================
  2019.11.21

  + 增加 分页下拉选项中增加全部,触发OnQueryAll事件 (注意:只有当前页码大于1页时,才会显示全部)
  * 修正 指定每页大小时页码框中数值不变
  * 修正 页码框位置问题
  * 调整 字符资源到resourcestring

  ===================
  2020.11.5

  * 修正 在Dev20.1.x时黑底

  ===================
  2020.11.20

  + 增加 AutoWidth属性，自动宽度 [感谢 围墙(qq:412252480)的提交]

  2023.7.21
  * 修正 运行时可能存报“Range check error”的问题
  * 修正 设置背景色时控件中元素高度异常
  * 优化 双缓冲绘图时的性能


}

{$IF RTLVersion>=31}// Berlin 及以上版本
{$DEFINE DELPHIBERLIN}
{$IFEND}
unit DevDataPager;

{$I Defs.inc}

interface

uses

  Windows, Messages, SysUtils, Classes, Controls, StdCtrls, Math,
  Graphics, Vcl.Menus, Vcl.Themes, Vcl.Forms,
  Types, UITypes
{$IFDEF DevGDIPlus}
    , cxGraphics, dxCoreGraphics, cxLookAndFeelPainters, dxGDIPlusClasses,
  dxThemeManager,
  cxLookAndFeels, dxSkinsLookAndFeelPainter, cxControls, cxGeometry, cxDWMApi
{$ENDIF}
    ;

const
  RecordCountWidth = 60;
  GoPageHeight = 22;
  GoPageWidth = 35;
  PageSizeWidth = 50;
  DropDownButtonWidth = 12;

type
  TOnPageNumEvent = procedure(Sender: TObject; APageNum: Integer) of object;
  TOnPageSizeEvent = procedure(Sender: TObject; APageSize: Integer) of object;

  TControlType = (ctLabelRecordCount, ctPriorPage, ctNextPage, ctGoPage,
    ctGoPageOk, ctGoPageLabelL, ctGoPageLabelR, ctFirstPage, ctLastPage,
    ctPageNum, ctEllipsis, ctPageSize);
  TDataPagerSetting = class;
  TPagerLabels = class;
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

{$IFDEF DevGDIPlus}

  TCanvas = TcxCanvas;
{$ELSE}
  TCanvas = Graphics.TCanvas;
  TWinControlAccess = class(TWinControl);

  TCustomControlEx = class(TCustomControl)
  private
    FPainting: Boolean;
    MemBitmap: TBitmap;
    FBackgroundColor: TColor;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
  protected
    procedure PaintChanged;
    procedure Paint; override;
    procedure Resize; override;
    procedure DrawControl(ACanvas: TCanvas); virtual;
    procedure DoubleBufferedPaint(var Message: TWMPaint);

    property BackgroundColor: TColor read FBackgroundColor
      write FBackgroundColor;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

{$ENDIF}
{$IFDEF DevGDIPlus}

  TCustomDevDataPager = class(TcxControl, IdxSkinSupport,
    IcxLookAndFeelContainer)
{$ELSE}
  TCustomDevDataPager = class(TCustomControlEx)
{$ENDIF}
  private
    FDataPagerSetting: TDataPagerSetting;
    FLabels: TPagerLabels;
    FPageSizePopup: TPopupMenu;
    FControlList: TList;
    FPageNum: Integer;
    FPageSize: Integer;
    FRecordCount: Integer;
    FOnPageNumEvent: TNotifyEvent;
    FPageNumEdit: TPageNumEdit;
    FHoverElement, FDownElement, FCurrElement: PElementInfo;
    FOnNextPage: TOnPageNumEvent;
    FOnPriorPage: TOnPageNumEvent;
    FOnGoPage: TOnPageNumEvent;
    FOnPageSize: TOnPageSizeEvent;
    FOnQueryAll: TNotifyEvent;
{$IFDEF DevGDIPlus}
    FLookAndFeel: TcxLookAndFeel;
{$ENDIF}
    FCanShowAll: Boolean;
    FAutoWidth: Boolean;
    procedure SetPageNum(const Value: Integer);
    procedure SetPageSize(const Value: Integer);
    procedure SetRecordCount(const Value: Integer);
    procedure SetAutoWidth(const Value: Boolean);

    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
{$IFDEF DevGDIPlus}
    procedure SetLookAndFeel(const Value: TcxLookAndFeel);
    function GetPainter: TcxCustomLookAndFeelPainter;
    function IsUseSkin: Boolean;
{$ENDIF}
  protected
    procedure Paint; override;
    procedure DrawControl(ACanvas: TCanvas); {$IFDEF DevGDIPlus} {$ELSE} override; {$ENDIF}
    procedure Prepare;
    procedure ControlListClear;
    procedure AddElement(AControlType: TControlType; ACaption: string;
      AEnabled: Boolean; AValue: Integer = -1);

    procedure DrawPageNums(ACanvas: TCanvas
{$IFDEF DevGDIPlus}; AGraphics: TdxGPGraphics{$ENDIF});
    procedure DrawInternalControl(ACanvas: TCanvas{$IFDEF DevGDIPlus};
      AGraphics: TdxGPGraphics{$ENDIF}; AElementInfo: PElementInfo);
    procedure DrawButtonArrow(ACanvas: TCanvas; const R: TRect;
      AColor: TColor); virtual;
    procedure DrawDropDownButton(ACanvas: TCanvas; R: TRect;
      AFrameColor: TColor; ABrushColor: TColor);

{$IFDEF DevGDIPlus}
{$IFDEF Dev20PlusFix}
    function GetBackgroundStyle: TcxControlBackgroundStyle; override;
{$ENDIF}
{$ENDIF}
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure DoPageSizeChange(Sender: TObject);
    procedure OnPageNumChange(Sender: TObject);
    procedure ChangeButtonOK;
    procedure DoPageElementEvent(AElementInfo: PElementInfo);
    procedure Resize; override;

{$IFDEF DevGDIPlus}
    // IcxLookAndFeelContainer
    function GetLookAndFeel: TcxLookAndFeel;
    procedure LookAndFeelChanged(Sender: TcxLookAndFeel;
      AChangedValues: TcxLookAndFeelValues); override;

    procedure PaintChanged;
{$ENDIF}
    function CalcPageCount: Integer;
    procedure AdjustPageNum; overload;
    procedure AdjustPageNum(AElementInfo: PElementInfo); overload;
    procedure SetPageSizeList;
    function PageNumEdit: TPageNumEdit;

    function GetElement(AControlType: TControlType): PElementInfo;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function PageCount: Integer;
    /// <summary>
    /// 获取内部控件的总宽度
    /// </summary>
    /// <returns></returns>
    function GetElementWidth: Integer;

    property AutoWidth: Boolean read FAutoWidth write SetAutoWidth
      default False;
{$IFDEF DevGDIPlus}
    property Painter: TcxCustomLookAndFeelPainter read GetPainter;
    property LookAndFeel: TcxLookAndFeel read FLookAndFeel write SetLookAndFeel;
{$ENDIF}
    property PageNum: Integer read FPageNum write SetPageNum default 1;
    property PageSize: Integer read FPageSize write SetPageSize default 50;
    property RecordCount: Integer read FRecordCount write SetRecordCount
      default 0;
    property Setting: TDataPagerSetting read FDataPagerSetting
      write FDataPagerSetting;
    property Labels: TPagerLabels read FLabels write FLabels;

    property OnPageNum: TNotifyEvent read FOnPageNumEvent write FOnPageNumEvent;
    property OnGoPage: TOnPageNumEvent read FOnGoPage write FOnGoPage;
    property OnPriorPage: TOnPageNumEvent read FOnPriorPage write FOnPriorPage;
    property OnNextPage: TOnPageNumEvent read FOnNextPage write FOnNextPage;
    property OnPageSize: TOnPageSizeEvent read FOnPageSize write FOnPageSize;
    property OnQueryAll: TNotifyEvent read FOnQueryAll write FOnQueryAll;
  end;

  TDataPagerSetting = class(TPersistent)
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
    FElementHeight: Integer;
    FPageSizeSet: String;
    FShowOKButton: Boolean;
    FBackgroundColor: TColor;
    FDisabledFont: TFont;
    FActiveFont: TFont;
    FLabelFont: TFont;
    FElementMinWidth: Integer;
    FShowAll: Boolean;
    procedure SetActiveColor(const Value: TColor);
    procedure SetDefaultColor(const Value: TColor);
    procedure SetDownColor(const Value: TColor);
    procedure SetHoverColor(const Value: TColor);
    procedure SetFrameColor(const Value: TColor);
    procedure SetFrameWidth(const Value: Integer);
    procedure SetFont(const Value: TFont);
    procedure SetArrowColor(const Value: TColor);
    procedure SetElementHeight(const Value: Integer);
    procedure SetPageSizeSet(const Value: String);
    procedure SetShowOKButton(const Value: Boolean);
    procedure SetBackgroundColor(const Value: TColor);
    procedure DoChange(Sender: TObject);
    procedure SetDisabledFont(const Value: TFont);
    procedure SetActiveFont(const Value: TFont);
    procedure SetLabelFont(const Value: TFont);
    procedure SetElementMinWidth(const Value: Integer);
    procedure SetShowAll(const Value: Boolean);
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
    property BackgroundColor: TColor read FBackgroundColor
      write SetBackgroundColor;

    property PageSizeSet: String read FPageSizeSet write SetPageSizeSet;
    property ElementHeight: Integer read FElementHeight write SetElementHeight
      default 25;
    property FrameWidth: Integer read FFrameWidth write SetFrameWidth default 1;
    property DisabledFont: TFont read FDisabledFont write SetDisabledFont;
    property Font: TFont read FFont write SetFont;
    property ActiveFont: TFont read FActiveFont write SetActiveFont;
    property LabelFont: TFont read FLabelFont write SetLabelFont;
    property ElementMinWidth: Integer read FElementMinWidth
      write SetElementMinWidth default 25;

    property ShowOKButton: Boolean read FShowOKButton write SetShowOKButton
      default True;
    property ShowAll: Boolean read FShowAll write SetShowAll default False;
  end;

  TPagerLabels = class(TPersistent)
  private
    FOwner: TComponent;
    FLabelNextPage: String;
    FLabelRecordCount: String;
    FLabelLastPage: String;
    FLabelGoPageR: String;
    FLabelEllipsis: String;
    FLabelPriorPage: String;
    FLabelPageSize: String;
    FLabelGoPageOK: String;
    FLabelGoPageL: String;
    FLabelFirstPage: String;
    FLabelShowAll: String;
    procedure SetLabelLabelEllipsis(const Value: String);
    procedure SetLabelLabelFirstPage(const Value: String);
    procedure SetLabelLabelGoPageL(const Value: String);
    procedure SetLabelLabelGoPageOK(const Value: String);
    procedure SetLabelLabelGoPageR(const Value: String);
    procedure SetLabelLabelLastPage(const Value: String);
    procedure SetLabelLabelNextPage(const Value: String);
    procedure SetLabelLabelPageSize(const Value: String);
    procedure SetLabelLabelPriorPage(const Value: String);
    procedure SetLabelRecordCount(const Value: String);
    procedure SetLabelShowAll(const Value: String);

  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure DoRePaint;
    procedure ModifyElement(AControlType: TControlType; ALabel: String);
    //
    property LabelFirstPage: String read FLabelFirstPage
      write SetLabelLabelFirstPage;
    property LabelLastPage: String read FLabelLastPage
      write SetLabelLabelLastPage;
  published
    property LabelRecordCount: String read FLabelRecordCount
      write SetLabelRecordCount;
    property LabelPriorPage: String read FLabelPriorPage
      write SetLabelLabelPriorPage;
    property LabelNextPage: String read FLabelNextPage
      write SetLabelLabelNextPage;
    property LabelPageSize: String read FLabelPageSize
      write SetLabelLabelPageSize;
    property LabelGoPageOK: String read FLabelGoPageOK
      write SetLabelLabelGoPageOK;
    property LabelGoPageL: String read FLabelGoPageL write SetLabelLabelGoPageL;
    property LabelGoPageR: String read FLabelGoPageR write SetLabelLabelGoPageR;
    property LabelEllipsis: String read FLabelEllipsis
      write SetLabelLabelEllipsis;
    property LabelShowAll: String read FLabelShowAll write SetLabelShowAll;
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
    procedure OnPageNumKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure OnPageNumMouseLeave(Sender: TObject);
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
    property AutoWidth;
    property Enabled;
    property DoubleBuffered default True;
{$IFDEF DevGDIPlus}
    property LookAndFeel;
{$ENDIF}
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
    property Labels;

    property OnPageNum;

    property OnGoPage;
    property OnPriorPage;
    property OnNextPage;
    property OnPageSize;
    property OnQueryAll;
  end;

procedure Register;

implementation

resourcestring
  __DefaultLabelNextPage = '下一页';
  __DefaultLabelRecordCount = '共 %d 条记录';
  __DefaultLabelLastPage = '末页';
  __DefaultLabelGoPageR = '页';
  __DefaultLabelEllipsis = '...';
  __DefaultLabelPriorPage = '上一页';
  __DefaultLabelPageSize = '%d条/页';
  __DefaultLabelGoPageOK = '确定';
  __DefaultLabelGoPageL = '到第';
  __DefaultLabelFirstPage = '首页';
  __DefaultLabelShowAll = '全部';

procedure Register;
begin
  RegisterComponents('DataPager', [TDevDataPager]);
end;

function GetScreenClient(Control: TControl): TPoint;
var
  p: TPoint;
begin
  p := Control.ClientOrigin;
  ScreenToClient(Control.Parent.Handle, p);
  Result := p;
end;

{$IFDEF DevGDIPlus}

function GetDataPagerPainter(ALookAndFeel: TcxLookAndFeel)
  : TcxCustomLookAndFeelPainter;
begin
  Result := ALookAndFeel.Painter;
  if ALookAndFeel.SkinPainter = nil then
  begin
    if Result.LookAndFeelStyle = lfsOffice11 then
    begin
      if AreVisualStylesAvailable(totButton) then
        Result := cxLookAndFeelPaintersManager.GetPainter(lfsNative)
      else
        Result := cxLookAndFeelPaintersManager.GetPainter(lfsStandard);
    end;
  end;
end;
{$ELSE}
{ TCustomControlEx }

procedure TCustomControlEx.PaintChanged;
begin
  FPainting := True;
  Invalidate;
end;

constructor TCustomControlEx.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  MemBitmap := TBitmap.Create;
  FPainting := True;
  BackgroundColor := clWhite; // 默认白色背景
end;

destructor TCustomControlEx.Destroy;
begin
  MemBitmap.Free;
  inherited Destroy;
end;

procedure TCustomControlEx.DoubleBufferedPaint(var Message: TWMPaint);
var
  PS: TPaintStruct;
  DC: HDC;
  MemDC: HDC;
  OldBitmap: HBITMAP;
begin
  DC := BeginPaint(Handle, PS);
  try
    MemBitmap.Width := ClientWidth;
    MemBitmap.Height := ClientHeight;

    MemDC := CreateCompatibleDC(DC);
    try
      OldBitmap := SelectObject(MemDC, MemBitmap.Handle);
      // PerformEraseBackground(self, MemDC);
      // MemBitmap.Canvas.Brush.Color := BackgroundColor;
      MemBitmap.Canvas.Brush.Color := clRed;
      MemBitmap.Canvas.FillRect(ClientRect);
      Message.DC := MemDC;
      WMPaint(Message);
      Message.DC := 0;

      BitBlt(DC, 0, 0, ClientWidth, ClientHeight, MemDC, 0, 0, SRCCOPY);

      SelectObject(MemDC, OldBitmap);
    finally
      DeleteDC(MemDC);
    end;
  finally
    EndPaint(Handle, PS);
  end;
end;

procedure TCustomControlEx.DrawControl(ACanvas: TCanvas);
begin

end;

procedure TCustomControlEx.Paint;
begin
  if (csDesigning in ComponentState) then
    FPainting := True;
  if ((self.Width > 1) and (self.Height > 1)) then
  begin
    if FPainting then
    begin
      FPainting := False;
      DrawControl(Canvas);
      FPainting := True;
    end;
  end;
end;

procedure TCustomControlEx.Resize;
begin
  inherited;
  PaintChanged;
end;

procedure TCustomControlEx.WMPaint(var Message: TWMPaint);
begin
  if not FDoubleBuffered or (Message.DC <> 0) then
  begin
    if not(csCustomPaint in ControlState) and (ControlCount = 0) then
    begin
      inherited;
    end
    else
    begin
      PaintHandler(Message);
    end;
  end
  else
  begin
    DoubleBufferedPaint(Message);
  end;
end;

procedure TCustomControlEx.WMSize(var Message: TWMSize);
begin
  inherited;
  Invalidate;
end;

{$ENDIF}
{ TDataPagerSetting }

procedure TDataPagerSetting.Assign(Source: TPersistent);
begin
  if Source is TDataPagerSetting then
  begin
    FDefaultColor := TDataPagerSetting(Source).FDefaultColor;
    FActiveColor := TDataPagerSetting(Source).FActiveColor;
    FHoverColor := TDataPagerSetting(Source).FHoverColor;
    FDownColor := TDataPagerSetting(Source).FDownColor;
    FFrameColor := TDataPagerSetting(Source).FFrameColor;
    FArrowColor := TDataPagerSetting(Source).FArrowColor;
    FPageSizeSet := TDataPagerSetting(Source).FPageSizeSet;
    FFrameWidth := TDataPagerSetting(Source).FFrameWidth;
    FFont.Assign(TDataPagerSetting(Source).FFont);
    FDisabledFont.Assign(TDataPagerSetting(Source).FDisabledFont);
    FLabelFont.Assign(TDataPagerSetting(Source).FLabelFont);
    FElementMinWidth := TDataPagerSetting(Source).FElementMinWidth;

  end;
end;

constructor TDataPagerSetting.Create(AOwner: TComponent);
begin
  inherited Create;
  FOwner := AOwner;

  FActiveFont := TFont.Create;
  FActiveFont.Size := 9;
  FActiveFont.Color := clWhite;
  FActiveFont.Name := 'Tahoma';
  FActiveFont.OnChange := DoChange;
  FFont := TFont.Create;
  FFont.Size := 9;
  FFont.Color := clBlack;
  FFont.Name := 'Tahoma';
  FFont.OnChange := DoChange;

  FDisabledFont := TFont.Create;
  FDisabledFont.Size := 9;
  FDisabledFont.Color := clGray;
  FDisabledFont.Name := 'Tahoma';
  FDisabledFont.OnChange := DoChange;

  FLabelFont := TFont.Create;
  FLabelFont.Size := 9;
  FLabelFont.Color := clBlack;
  FLabelFont.Name := 'Tahoma';
  FLabelFont.OnChange := DoChange;

  FDefaultColor := clWhite;
  FActiveColor := clNavy;
  FHoverColor := $00F1F1F1;
  FDownColor := $00F1F1F1;
  FFrameColor := clSilver;
  FArrowColor := clBlack;
  FBackgroundColor := clWhite;
  FFrameWidth := 1;
  FElementHeight := 25;
  FElementMinWidth := 25;
  FShowOKButton := True;
  FShowAll := False;
  FPageSizeSet := '10,20,30,40,50,100,150';
end;

destructor TDataPagerSetting.Destroy;
begin
  FFont.Free;
  FDisabledFont.Free;
  FActiveFont.Free;
  FLabelFont.Free;
  inherited Destroy;
end;

procedure TDataPagerSetting.DoChange(Sender: TObject);
begin
  if FOwner is TCustomDevDataPager then
    TCustomDevDataPager(FOwner).PaintChanged;
end;

procedure TDataPagerSetting.SetActiveColor(const Value: TColor);
begin
  if Value <> FActiveColor then
  begin
    FActiveColor := Value;
    if FOwner is TCustomDevDataPager then
      TCustomDevDataPager(FOwner).PaintChanged;
  end;
end;

procedure TDataPagerSetting.SetActiveFont(const Value: TFont);
begin
  FActiveFont.Assign(Value);
end;

procedure TDataPagerSetting.SetArrowColor(const Value: TColor);
begin
  if Value <> FArrowColor then
  begin
    FArrowColor := Value;
    if FOwner is TCustomDevDataPager then
      TCustomDevDataPager(FOwner).PaintChanged;
  end;
end;

procedure TDataPagerSetting.SetBackgroundColor(const Value: TColor);
begin
  if Value <> FBackgroundColor then
  begin
    FBackgroundColor := Value;
    if FOwner is TCustomDevDataPager then
    begin
{$IFNDEF DevGDIPlus}
      TCustomDevDataPager(FOwner).BackgroundColor := FBackgroundColor;
{$ENDIF}
      TCustomDevDataPager(FOwner).Prepare;
      TCustomDevDataPager(FOwner).PaintChanged;
    end;
  end;
end;

procedure TDataPagerSetting.SetElementMinWidth(const Value: Integer);
begin
  if Value <> FElementMinWidth then
  begin
    FElementMinWidth := Value;
    if FOwner is TCustomDevDataPager then
    begin
      TCustomDevDataPager(FOwner).Prepare;
      TCustomDevDataPager(FOwner).PaintChanged;
    end;
  end;
end;

procedure TDataPagerSetting.SetElementHeight(const Value: Integer);
begin
  if Value <> FElementHeight then
  begin
    FElementHeight := Value;
    if FOwner is TCustomDevDataPager then
    begin
      TCustomDevDataPager(FOwner).Prepare;
      TCustomDevDataPager(FOwner).PaintChanged;
    end;
  end;
end;

procedure TDataPagerSetting.SetDefaultColor(const Value: TColor);
begin
  if Value <> FDefaultColor then
  begin
    FDefaultColor := Value;
    if FOwner is TCustomDevDataPager then
      TCustomDevDataPager(FOwner).PaintChanged;
  end;
end;

procedure TDataPagerSetting.SetDisabledFont(const Value: TFont);
begin
  FDisabledFont.Assign(Value);
end;

procedure TDataPagerSetting.SetDownColor(const Value: TColor);
begin
  if Value <> FDownColor then
  begin
    FDownColor := Value;
    if FOwner is TCustomDevDataPager then
      TCustomDevDataPager(FOwner).PaintChanged;
  end;
end;

procedure TDataPagerSetting.SetFont(const Value: TFont);
begin
  FFont.Assign(Value);
end;

procedure TDataPagerSetting.SetFrameColor(const Value: TColor);
begin
  if Value <> FFrameColor then
  begin
    FFrameColor := Value;
    if FOwner is TCustomDevDataPager then
    begin
      TCustomDevDataPager(FOwner).PageNumEdit.FrameColor := FFrameColor;
      TCustomDevDataPager(FOwner).PaintChanged;
    end;
  end;
end;

procedure TDataPagerSetting.SetFrameWidth(const Value: Integer);
begin
  if Value <> FFrameWidth then
  begin
    FFrameWidth := Value;
    if FOwner is TCustomDevDataPager then
      TCustomDevDataPager(FOwner).PaintChanged;
  end;
end;

procedure TDataPagerSetting.SetHoverColor(const Value: TColor);
begin
  if Value <> FHoverColor then
  begin
    FHoverColor := Value;
    if FOwner is TCustomDevDataPager then
      TCustomDevDataPager(FOwner).PaintChanged;
  end;
end;

procedure TDataPagerSetting.SetLabelFont(const Value: TFont);
begin
  FLabelFont.Assign(Value);
end;

procedure TDataPagerSetting.SetPageSizeSet(const Value: String);
begin
  if Value <> FPageSizeSet then
  begin
    FPageSizeSet := Value;
    if FOwner is TCustomDevDataPager then
    begin
      // TCustomDevDataPager(FOwner).Prepare;
      TCustomDevDataPager(FOwner).PaintChanged;
    end;
  end;
end;

procedure TDataPagerSetting.SetShowOKButton(const Value: Boolean);
begin
  if Value <> FShowOKButton then
  begin
    FShowOKButton := Value;
    if FOwner is TCustomDevDataPager then
    begin
      TCustomDevDataPager(FOwner).Prepare;
      TCustomDevDataPager(FOwner).PaintChanged;
    end;
  end;
end;

procedure TDataPagerSetting.SetShowAll(const Value: Boolean);
begin
  if Value <> FShowAll then
  begin
    FShowAll := Value;
    if FOwner is TCustomDevDataPager then
    begin
      TCustomDevDataPager(FOwner).Prepare;
      TCustomDevDataPager(FOwner).PaintChanged;
    end;
  end;
end;

{ TCustomDevDataPager }

procedure TCustomDevDataPager.AddElement(AControlType: TControlType;
  ACaption: string; AEnabled: Boolean; AValue: Integer);
var
  AHeight, AWidth: Integer;
  ALeft: Integer;
  AElementInfo: PElementInfo;
  ARect: TRect;
begin
  if FDataPagerSetting = nil then
    Exit;

  Canvas.Font.Assign(FDataPagerSetting.Font);
  ALeft := GetElementWidth;
  AHeight := FDataPagerSetting.ElementHeight;

  ARect.Left := ALeft;
  ARect.Top := (Height - AHeight) div 2;
  ARect.Height := AHeight;
  if FRecordCount = 0 then
    AWidth := Setting.ElementMinWidth + 8
  else
    AWidth := Max(Setting.ElementMinWidth, Canvas.TextWidth(ACaption) + 8);
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
        ARect.Top := ((Height - AHeight) + (FDataPagerSetting.ElementHeight -
          GoPageHeight)) div 2;
        ARect.Height := GoPageHeight;
        ARect.Left := ARect.Left + AElementInfo^.OffSet;
        AWidth := Max(GoPageWidth,
          Canvas.TextWidth(CalcPageCount.ToString) + 8);
      end;
    ctGoPageOk:
      begin
        AElementInfo^.OffSet := 0;
      end;
    ctGoPageLabelL:
      begin
        AElementInfo^.OffSet := 4;
        ARect.Left := ARect.Left + AElementInfo^.OffSet;
        AWidth := AWidth - 10 + 6
      end;
    ctGoPageLabelR:
      begin
        AElementInfo^.OffSet := 0;
        ARect.Left := ARect.Left + AElementInfo^.OffSet;
        AWidth := AWidth - 10 + 4
      end;
    ctPageSize:
      begin
        AElementInfo^.OffSet := 4;
        ARect.Left := ARect.Left + AElementInfo^.OffSet;
        if (FDataPagerSetting.ShowAll) and (FCanShowAll) then
        begin
          AWidth := Canvas.TextWidth(FLabels.LabelShowAll) + 8 +
            DropDownButtonWidth;
        end
        else
        begin
          if FRecordCount = 0 then
            AWidth := PageSizeWidth + DropDownButtonWidth
          else
            AWidth := Max(PageSizeWidth, Canvas.TextWidth(ACaption) + 8) +
              DropDownButtonWidth;
        end;
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
  AElementInfo^.Value := AValue;
  AElementInfo^.Caption := ACaption;
  AElementInfo^.Showing := True;
  AElementInfo^.ControlType := AControlType;
  AElementInfo^.Showing := True;
  FControlList.Add(AElementInfo);
end;

procedure TCustomDevDataPager.AdjustPageNum;
var
  I: Integer;
  AElementInfo: PElementInfo;
begin
  for I := 0 to FControlList.Count - 1 do
  begin
    AElementInfo := PElementInfo(FControlList.Items[I]);
    if AElementInfo.ControlType = ctGoPage then
    begin
      { R := AElementInfo.Rect;
        FPageNumEdit.Width := R.Width;
        FPageNumEdit.Height := GoPageHeight;
        FPageNumEdit.Left := R.Left;
        FPageNumEdit.Top := R.Top;
        FPageNumEdit.Value := PageNum;
        if not FPageNumEdit.Visible then
        FPageNumEdit.Visible := RecordCount > 0;
      }
      AdjustPageNum(AElementInfo);
      Break;
    end;
  end;
end;

procedure TCustomDevDataPager.AdjustPageNum(AElementInfo: PElementInfo);
var
  AGoRect: TRect;
begin
  if AElementInfo = nil then
    Exit;

  if AElementInfo.ControlType = ctGoPage then
  begin
    { R := AElementInfo.Rect;

      FPageNumEdit.Width := R.Width;
      FPageNumEdit.Height := GoPageHeight;
      FPageNumEdit.Left := R.Left;
      FPageNumEdit.Top := R.Top;
      FPageNumEdit.Value := PageNum;
      if not FPageNumEdit.Visible then
      FPageNumEdit.Visible := RecordCount > 0;
    }
    AGoRect := AElementInfo.Rect;
    InflateRect(AGoRect, -1, -1);
    PageNumEdit.Width := AGoRect.Width - 2;
    PageNumEdit.Height := AGoRect.Height - 2;
    PageNumEdit.Left := AGoRect.Left + 1;
    PageNumEdit.Top := AGoRect.Top + 2;
    PageNumEdit.Visible := RecordCount > 0;
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
      AElementInfo.Enabled := PageNum <> PageNumEdit.Value;
      PaintChanged;
      Break;
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
  if self.Cursor <> crDefault then
    self.Cursor := crDefault;

  PaintChanged;
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
  FCanShowAll := False;

  Color := clWhite;

  DoubleBuffered := True;

  FDataPagerSetting := TDataPagerSetting.Create(self);
  FLabels := TPagerLabels.Create(self);
{$IFDEF DevGDIPlus}
  FLookAndFeel := TcxLookAndFeel.Create(self);
  FLookAndFeel.OnChanged := LookAndFeelChanged;
{$ENDIF}
  Prepare;
  // RecordCount := 0;
  // Invalidate;
end;

procedure TCustomDevDataPager.SetPageSizeList;
var
  PageSize_ARR: TArray<string>;
  APageSize: Integer;
  I: Integer;
  AItem: TMenuItem;
begin
  if FPageSizePopup = nil then
  begin
    FPageSizePopup := TPopupMenu.Create(self);
    FPageSizePopup.AutoHotkeys := maAutomatic;
  end;
  PageSize_ARR := FDataPagerSetting.PageSizeSet.Split([',', ';']);
  FPageSizePopup.Items.Clear;
  for I := 0 to Length(PageSize_ARR) - 1 do
  begin
    APageSize := StrToIntDef(PageSize_ARR[I], 10);
    AItem := TMenuItem.Create(FPageSizePopup);
    AItem.Caption := Format(FLabels.LabelPageSize, [APageSize]);
    AItem.Tag := APageSize;
    AItem.GroupIndex := 99;
    AItem.RadioItem := True;
    if AItem.Tag = PageSize then
      AItem.Checked := True;
    AItem.OnClick := DoPageSizeChange;
    FPageSizePopup.Items.Add(AItem);
  end;
  if (FDataPagerSetting.ShowAll) and (PageCount > 1) then
  begin
    AItem := TMenuItem.Create(FPageSizePopup);
    AItem.Caption := '-';

    FPageSizePopup.Items.Add(AItem);
    AItem := TMenuItem.Create(FPageSizePopup);
    AItem.Caption := FLabels.LabelShowAll;
    AItem.Tag := RecordCount;
    AItem.GroupIndex := 99;
    AItem.RadioItem := True;
    if AItem.Tag = PageSize then
      AItem.Checked := True;
    AItem.OnClick := DoPageSizeChange;
    FPageSizePopup.Items.Add(AItem);

  end;

end;

destructor TCustomDevDataPager.Destroy;
begin
  FDataPagerSetting.Free;
  FLabels.Free;
{$IFDEF DevGDIPlus}
  FreeAndNil(FLookAndFeel);
{$ENDIF}
  ControlListClear;
  FControlList.Free;
  if FPageSizePopup <> nil then
    FPageSizePopup.Free;
  if FPageNumEdit <> nil then
    FPageNumEdit.Free;
  inherited;
end;

procedure TCustomDevDataPager.DoPageElementEvent(AElementInfo: PElementInfo);
var
  p: TPoint;
  APageNum: Integer;
begin
  if AElementInfo = nil then
    Exit;

  case AElementInfo.ControlType of
    ctLabelRecordCount, ctEllipsis:
      begin

      end;
    ctPriorPage:
      begin
        if PageNum = 1 then
          Exit;

        PageNum := PageNum - 1;
        if Assigned(FOnPriorPage) then
          FOnPriorPage(self, PageNum);
      end;
    ctNextPage:
      begin
        if PageNum = CalcPageCount then
          Exit;
        PageNum := PageNum + 1;
        if Assigned(FOnNextPage) then
          FOnNextPage(self, PageNum);
      end;

    ctGoPageOk:
      begin
        APageNum := PageNumEdit.Value;
        if PageNum <> APageNum then
        begin
          PageNum := APageNum;
          if Assigned(FOnGoPage) then
            FOnGoPage(self, PageNum);
        end;
      end;
    ctGoPage, ctFirstPage, ctLastPage, ctPageNum:
      begin
        APageNum := AElementInfo.Value;
        if PageNum <> APageNum then
        begin
          PageNum := APageNum;
          if Assigned(FOnGoPage) then
            FOnGoPage(self, PageNum);
        end;
      end;
    ctPageSize:
      begin
        SetPageSizeList;
        p.X := AElementInfo.Rect.Left;
        p.Y := AElementInfo.Rect.Top;
        p.Y := p.Y + AElementInfo.Rect.Height;
        p := self.ClientToScreen(p);
        FPageSizePopup.Popup(p.X, p.Y);

      end;
  end;
end;

procedure TCustomDevDataPager.DoPageSizeChange(Sender: TObject);
var
  AItem: TMenuItem;
begin
  AItem := TMenuItem(Sender);
  AItem.Checked := True;

  if Pos(FLabels.LabelShowAll, AItem.Caption) > 0 then
  begin
    FCanShowAll := True;
    FPageNum := 1;
    PageSize := AItem.Tag;
    if Assigned(FOnQueryAll) then
      FOnQueryAll(self);
  end
  else
  begin
    FCanShowAll := False;
    FPageNum := 1;
    PageSize := AItem.Tag;
    if Assigned(FOnPageSize) then
      FOnPageSize(self, PageSize);
  end;
end;

procedure TCustomDevDataPager.DrawDropDownButton(ACanvas: TCanvas; R: TRect;
  AFrameColor: TColor; ABrushColor: TColor);
begin
  ACanvas.Brush.Color := AFrameColor;
  ACanvas.FrameRect(R);
  InflateRect(R, -1, -1);
  ACanvas.Brush.Color := ABrushColor;
  ACanvas.FillRect(R);
  DrawButtonArrow(ACanvas, R, FDataPagerSetting.FArrowColor);
end;

procedure TCustomDevDataPager.DrawPageNums(ACanvas: TCanvas{$IFDEF DevGDIPlus};
  AGraphics: TdxGPGraphics{$ENDIF});
var
  FElementInfo: PElementInfo;
  I: Integer;
begin
  for I := 0 to FControlList.Count - 1 do
  begin
    FElementInfo := PElementInfo(FControlList.Items[I]);
    if FElementInfo.Showing then
    begin
      DrawInternalControl(ACanvas
{$IFDEF DevGDIPlus}, AGraphics{$ENDIF}, FElementInfo);
{$IFDEF DEBUG}
      // ACanvas.FrameRect(FElementInfo.Rect,clRed);
{$ENDIF}
    end;

  end;
end;

{$IFDEF DevGDIPlus}
{$IFDEF Dev20PlusFix}

function TCustomDevDataPager.GetBackgroundStyle: TcxControlBackgroundStyle;
begin
  if IsTransparentBackground then
    Result := bgTransparent
  else
    Result := bgOpaque;
end;
{$ENDIF}
{$ENDIF}

function TCustomDevDataPager.GetElement(AControlType: TControlType)
  : PElementInfo;
var
  I: Integer;
  FElementInfo: PElementInfo;
begin
  Result := nil;
  for I := 0 to FControlList.Count - 1 do
  begin
    FElementInfo := PElementInfo(FControlList.Items[I]);
    if FElementInfo.ControlType = AControlType then
    begin
      Result := FElementInfo;
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

{$IFDEF DevGDIPlus}

function TCustomDevDataPager.GetLookAndFeel: TcxLookAndFeel;
begin
  Result := LookAndFeel;
end;

function TCustomDevDataPager.GetPainter: TcxCustomLookAndFeelPainter;
begin
  Result := GetDataPagerPainter(LookAndFeel);
end;

function TCustomDevDataPager.IsUseSkin: Boolean;
begin
  Result := (not LookAndFeel.NativeStyle) and (LookAndFeel.Kind = lfUltraFlat)
    and (LookAndFeel.SkinPainter <> nil);
end;

procedure TCustomDevDataPager.LookAndFeelChanged(Sender: TcxLookAndFeel;
  AChangedValues: TcxLookAndFeelValues);
begin
  PaintChanged;
end;

procedure TCustomDevDataPager.SetLookAndFeel(const Value: TcxLookAndFeel);
begin
  FLookAndFeel.Assign(Value);
end;

procedure TCustomDevDataPager.PaintChanged;
begin
  Repaint;
end;

{$ENDIF}

procedure TCustomDevDataPager.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if (Button = mbLeft) and Enabled then
  begin
    FDownElement := FHoverElement;
    PaintChanged;
  end;
end;

procedure TCustomDevDataPager.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  CursorPos: TPoint;
  R, TmpRect: TRect;
  I: Integer;
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

          FHoverElement := AElementInfo;

          if AElementInfo.ControlType = ctGoPage then
          begin
            AdjustPageNum(AElementInfo);
          end
          else
          begin
            PageNumEdit.Visible := False;
            if Cursor <> crHandPoint then
            begin
              Cursor := crHandPoint;
            end;
            if (FCurrElement <> AElementInfo) then
            begin
              PaintChanged;
              FCurrElement := AElementInfo;
            end;
          end;
          Break;
        end
        else
        begin
          if PageNumEdit.Visible then
          begin
            PageNumEdit.Visible := False;
            PaintChanged;
          end;
          FHoverElement := nil;
          if Cursor <> crDefault then
          begin
            Cursor := crDefault;
            // Changed;
          end;
        end;
      end;
    end;
  end;

end;

procedure TCustomDevDataPager.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    DoPageElementEvent(FDownElement);
    FDownElement := nil;
    FHoverElement := nil;
    FCurrElement := nil;
    PaintChanged;
  end;
end;

procedure TCustomDevDataPager.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
end;

procedure TCustomDevDataPager.OnPageNumChange(Sender: TObject);
var
  AValue: Integer;
begin
  AValue := StrToIntDef(PageNumEdit.Text, 1);
  if AValue > CalcPageCount then
  begin
    PageNumEdit.Text := CalcPageCount.ToString;
    PageNumEdit.SelectAll;
  end;
  AdjustPageNum;
  ChangeButtonOK;
end;

procedure TCustomDevDataPager.DrawButtonArrow(ACanvas: TCanvas; const R: TRect;
  AColor: TColor);
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
      p[0] := Point((Left + Right - ASize.X) div 2,
        MulDiv(Top + Bottom - ASize.Y, 1, 2));
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

procedure TCustomDevDataPager.DrawControl(ACanvas: TCanvas);
{$IFDEF DevGDIPlus}
var
  AGraphics: TdxGPGraphics;
begin
  inherited;
  AGraphics := dxGpBeginPaint(ACanvas.Handle, self.ClientBounds);
  try
    AGraphics.SmoothingMode := smAntiAlias;
    if IsUseSkin then
    begin
      Color := Painter.DefaultContentColor;
    end
    else
    begin
      Color := FDataPagerSetting.BackgroundColor;
    end;
    DrawPageNums(ACanvas, AGraphics);
  finally
    dxGpEndPaint(AGraphics);
  end;

{$ELSE}

begin
  inherited;
  Color := FDataPagerSetting.BackgroundColor;
  // Canvas.Brush.Color   := FDataPagerSetting.BackgroundColor;
  DrawPageNums(Canvas);
{$ENDIF}
end;

procedure TCustomDevDataPager.DrawInternalControl
  (ACanvas: TCanvas{$IFDEF DevGDIPlus}; AGraphics: TdxGPGraphics{$ENDIF};
  AElementInfo: PElementInfo);
const
  RadiusX = 0;
  RadiusY = 0;
  procedure DrawText;
  var
    X, Y: Integer;
    AText: string;
    ARect: TRect;
  begin
    AText := AElementInfo.Caption;
    ARect := AElementInfo.Rect;
    if AElementInfo.ControlType = ctPageSize then
    begin
      if (FDataPagerSetting.ShowAll) and FCanShowAll then
      begin
        AText := FLabels.LabelShowAll;
      end;
      ARect.Width := ARect.Width - DropDownButtonWidth;

    end;

    // LabelFont

    case AElementInfo.ControlType of
      ctLabelRecordCount, ctGoPageLabelL, ctGoPageLabelR:
        begin
          ACanvas.Font.Assign(FDataPagerSetting.LabelFont);
        end;
    else
      begin
        if FPageNum.ToString.Equals(AElementInfo.Caption) then
        begin
          ACanvas.Font.Assign(FDataPagerSetting.ActiveFont);
        end
        else
        begin
          if not AElementInfo.Enabled then
            ACanvas.Font.Assign(FDataPagerSetting.DisabledFont)
          else
            ACanvas.Font.Assign(FDataPagerSetting.Font);
        end;
      end;
    end;

    X := ARect.Left + (ARect.Width - ACanvas.TextWidth(AText)) div 2;
    Y := ARect.Top + (ARect.Height - ACanvas.TextHeight(AText)) div 2;
    ACanvas.Brush.Style := bsClear;
    ACanvas.TextOut(X, Y, AText);
  end;

  procedure DrawGoPage; // 画跳转页
  var
    ABrushColor, AFrameColor: TColor;
  var
    X, Y: Integer;
    AText: string;
    ARect: TRect;
  begin
    if AElementInfo.Enabled then
    begin
      ABrushColor := FDataPagerSetting.DefaultColor;
      AFrameColor := FDataPagerSetting.FrameColor;
    end
    else
    begin
      ABrushColor := FDataPagerSetting.DefaultColor;
      AFrameColor := clBtnFace;
    end;
    ARect := AElementInfo.Rect;

    ACanvas.Brush.Color := AFrameColor;
    ACanvas.FrameRect(ARect);
    InflateRect(ARect, -1, -1);
    ACanvas.Brush.Color := ABrushColor;
    ACanvas.FillRect(ARect);
    AText := PageNumEdit.Text;
    if AText.IsEmpty then
    begin
      AText := PageNum.ToString;
      PageNumEdit.Text := AText;
    end;
    X := ARect.Left + (ARect.Width - ACanvas.TextWidth(AText)) div 2;
    Y := ARect.Top + (ARect.Height - ACanvas.TextHeight(AText)) div 2;
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Assign(FDataPagerSetting.Font);
    ACanvas.TextOut(X, Y, AText);
  end;

  procedure DrawButton;
  var
{$IFDEF DevGDIPlus}
    APen: TdxGPPen;
    ABrush: TdxGPBrush;
{$ENDIF}
    R: TRect;
    ABrushColor, AFrameColor: TColor;
  begin
    if AElementInfo.Enabled then
    begin
      if FPageNum.ToString.Equals(AElementInfo.Caption) then
      begin
        ABrushColor := FDataPagerSetting.ActiveColor;
      end
      else
      begin
        if FHoverElement = AElementInfo then
          ABrushColor := FDataPagerSetting.HoverColor
        else
          ABrushColor := FDataPagerSetting.DefaultColor;
      end;
      AFrameColor := FDataPagerSetting.FrameColor;
    end
    else
    begin
      ABrushColor := FDataPagerSetting.DefaultColor;
      AFrameColor := clBtnFace;
    end;
    R := AElementInfo.Rect;
{$IFDEF DevGDIPlus}
    APen := TdxGPPen.Create(TdxAlphaColors.FromColor(AFrameColor),
      FDataPagerSetting.FrameWidth, psSolid);
    ABrush := TdxGPBrush.Create;
    ABrush.Color := TdxAlphaColors.FromColor(ABrushColor);
    try
      AGraphics.RoundRect(R, APen, ABrush, RadiusX, RadiusY);
    finally
      ABrush.Free;
      APen.Free;
    end;
{$ELSE}
    ACanvas.Brush.Color := AFrameColor;
    ACanvas.FrameRect(R);
    InflateRect(R, -1, -1);
    ACanvas.Brush.Color := ABrushColor;
    ACanvas.FillRect(R);
{$ENDIF}
  end;

{$IFDEF DevGDIPlus}
  procedure DrawSkinButton;
  begin
    if AElementInfo.Enabled then
    begin
      if FPageNum.ToString.Equals(AElementInfo.Caption) then
      begin
        Painter.DrawScaledButton(ACanvas, AElementInfo.Rect,
          AElementInfo.Caption, cxbsPressed, ScaleFactor, True);
      end
      else
      begin
        if FHoverElement = AElementInfo then
          Painter.DrawScaledButton(ACanvas, AElementInfo.Rect,
            AElementInfo.Caption, cxbsHot, ScaleFactor, True)
        else
          Painter.DrawScaledButton(ACanvas, AElementInfo.Rect,
            AElementInfo.Caption, cxbsNormal, ScaleFactor, True);
      end;
    end
    else
    begin
      Painter.DrawScaledButton(ACanvas, AElementInfo.Rect, AElementInfo.Caption,
        cxbsDisabled, ScaleFactor, True);
    end;

  end;
{$ENDIF}
  procedure DrawPageSize;
  var
{$IFDEF DevGDIPlus}
    APen: TdxGPPen;
    ABrush: TdxGPBrush;
{$ENDIF}
    AFrameColor, ABrushColor: TColor;
    ARect: TRect;
  begin
    ARect := AElementInfo.Rect;

{$IFDEF DevGDIPlus}
    if IsUseSkin then
    begin
      AFrameColor := TdxSkinLookAndFeelPainter(Painter)
        .SkinInfo.ContainerBorderColor.Value;
      if FHoverElement = AElementInfo then
      begin
        ABrushColor := Painter.DefaultContentColor;
        AFrameColor := Painter.DefaultSelectionColor;
      end
      else
        ABrushColor := Painter.DefaultControlColor;
    end
    else
{$ENDIF}
    begin
      AFrameColor := FDataPagerSetting.FrameColor;
      if FHoverElement = AElementInfo then
        ABrushColor := FDataPagerSetting.HoverColor
      else
        ABrushColor := FDataPagerSetting.DefaultColor;
    end;
{$IFDEF DevGDIPlus}
    APen := TdxGPPen.Create(TdxAlphaColors.FromColor(AFrameColor),
      FDataPagerSetting.FrameWidth, psSolid);
    ABrush := TdxGPBrush.Create;
    ABrush.Color := TdxAlphaColors.FromColor(ABrushColor);
    try
      ARect.Width := ARect.Width - DropDownButtonWidth;
      AGraphics.RoundRect(ARect, APen, ABrush, 0, 0);
    finally
      ABrush.Free;
      APen.Free;
    end;
{$ELSE}
    ARect.Width := ARect.Width - DropDownButtonWidth;
    ACanvas.Brush.Color := AFrameColor;
    ACanvas.FrameRect(ARect);
    InflateRect(ARect, -1, -1);
    ACanvas.Brush.Color := ABrushColor;
    ACanvas.FillRect(ARect);
    InflateRect(ARect, 1, 1);
{$ENDIF}
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
    ctPriorPage, ctNextPage, ctFirstPage, ctLastPage, ctPageNum, ctGoPageOk,
      ctEllipsis:
      begin
{$IFDEF DevGDIPlus}
        if IsUseSkin then
        begin
          DrawSkinButton;
        end
        else
{$ENDIF}
        begin
          DrawButton;
          DrawText;
        end;
      end;
    ctGoPage:
      begin
        DrawGoPage;
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
{$IFDEF DevGDIPlus}
  DrawControl(Canvas);
{$ENDIF}
end;

function TCustomDevDataPager.PageCount: Integer;
begin
  Result := CalcPageCount;
end;

function TCustomDevDataPager.PageNumEdit: TPageNumEdit;
begin
  if FPageNumEdit = nil then
  begin
    FPageNumEdit := TPageNumEdit.Create(self);
    FPageNumEdit.Width := 0;
    FPageNumEdit.Left := -100;
    FPageNumEdit.Parent := self;
    FPageNumEdit.Visible := False;
    FPageNumEdit.BorderStyle := bsNone;
    FPageNumEdit.FrameColor := Setting.FrameColor;
    FPageNumEdit.OnChange := OnPageNumChange;
  end;
  Result := FPageNumEdit;
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
        AddElement(ctPriorPage, FLabels.LabelPriorPage, False)
      end
      else
      begin
        AddElement(ctPriorPage, FLabels.LabelPriorPage, True);
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
            AddElement(ctEllipsis, FLabels.LabelEllipsis, False);

          for I := PageNum - 1 to PageNum + 1 do
          begin
            AddElement(ctPageNum, I.ToString, True, I);
          end;

          if (PageNum + 2) = APageCount - 1 then
            AddElement(ctPageNum, IntToStr(PageNum + 2), True, PageNum + 2)
          else
          begin
            if (PageNum + 2) <> APageCount then
              AddElement(ctEllipsis, FLabels.LabelEllipsis, False);
          end;

          for I := APageCount to APageCount do
          begin
            AddElement(ctPageNum, I.ToString, True, I);
          end;
        end
        else
        begin
          if (PageNum + 2) >= APageCount then
          begin
            for I := 1 to 1 do
            begin
              AddElement(ctPageNum, I.ToString, True, I);
            end;
          end
          else
          begin
            for I := 1 to 5 do
            begin
              AddElement(ctPageNum, I.ToString, True, I);
            end;
          end;

          AddElement(ctEllipsis, FLabels.LabelEllipsis, False);
          if (PageNum + 2) >= APageCount then
          begin
            for I := APageCount - 4 to APageCount do
            begin
              AddElement(ctPageNum, I.ToString, True, I);
            end;
          end
          else
          begin
            for I := APageCount to APageCount do
            begin
              AddElement(ctPageNum, I.ToString, True, I);
            end;
          end;
        end;
      end;

      if (FPageNum = APageCount) then
        AddElement(ctNextPage, FLabels.LabelNextPage, False)
      else
        AddElement(ctNextPage, FLabels.LabelNextPage, True);
      AddElement(ctGoPageLabelL, FLabels.LabelGoPageL, False);
      AddElement(ctGoPage, FPageNum.ToString, True);
      AddElement(ctGoPageLabelR, FLabels.LabelGoPageR, False);
      if FDataPagerSetting.ShowOKButton then
        AddElement(ctGoPageOk, FLabels.LabelGoPageOK, False);
      AddElement(ctLabelRecordCount, Format(FLabels.LabelRecordCount,
        [RecordCount]), False);
      if FCanShowAll then
        AddElement(ctPageSize, FLabels.LabelShowAll, True)
      else
        AddElement(ctPageSize, Format(FLabels.LabelPageSize, [PageSize]), True);
    end
    else
    begin
      AddElement(ctLabelRecordCount, Format(FLabels.LabelRecordCount,
        [RecordCount]), False);
    end;

    if RecordCount > 0 then
      AdjustPageNum;
    if FAutoWidth and (Align in [alNone, alLeft, alRight]) then
      Width := GetElementWidth + 4;
  finally
    Font := OldFont;
  end;
end;

procedure TCustomDevDataPager.Resize;
begin
  inherited;
  if (Width = 0) or (Height = 0) then
    Exit;
  Prepare;
  PaintChanged;
end;

procedure TCustomDevDataPager.SetAutoWidth(const Value: Boolean);
begin
  if FAutoWidth <> Value then
  begin
    FAutoWidth := Value;
    if FAutoWidth then
    begin
      Resize;
    end;
  end;
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
      FOnPageNumEvent(self);
    PageNumEdit.Value := FPageNum;
    // FPageNumEdit.Left
    ChangeButtonOK;
    PaintChanged;
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

    Prepare;
    if Assigned(FOnPageNumEvent) then
      FOnPageNumEvent(self);
    PaintChanged;
  end;
end;

procedure TCustomDevDataPager.SetRecordCount(const Value: Integer);
var
  FPageCount: Integer;
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
      FPageCount := CalcPageCount;
      if FPageCount > 0 then
      begin
        if FPageNum > FPageCount then
        begin
          FPageNum := FPageCount;
        end;
      end
      else
        FPageNum := 1;

    end;

    Prepare;
    PaintChanged;
  end;
end;

{ TPageNumEdit }

constructor TPageNumEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FOwner := AOwner;
  OnKeyDown := OnPageNumKeyDown;
  OnMouseLeave := OnPageNumMouseLeave;
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

procedure TPageNumEdit.OnPageNumKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if FOwner = nil then
    Exit;
  if Key = 13 then
  begin
    TCustomDevDataPager(FOwner).PageNum := Value;
    SelectAll;
  end;
end;

procedure TPageNumEdit.OnPageNumMouseLeave(Sender: TObject);
begin
  if FOwner = nil then
    Exit;
  TCustomDevDataPager(FOwner).PaintChanged;
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

{ TPagerLabels }

procedure TPagerLabels.Assign(Source: TPersistent);
begin
  inherited;
  if Source is TPagerLabels then
  begin
    FLabelNextPage := TPagerLabels(Source).FLabelNextPage;
    FLabelRecordCount := TPagerLabels(Source).FLabelRecordCount;
    FLabelLastPage := TPagerLabels(Source).FLabelLastPage;
    FLabelGoPageR := TPagerLabels(Source).FLabelGoPageR;
    FLabelEllipsis := TPagerLabels(Source).FLabelEllipsis;
    FLabelPriorPage := TPagerLabels(Source).FLabelPriorPage;
    FLabelPageSize := TPagerLabels(Source).FLabelPageSize;
    LabelGoPageOK := TPagerLabels(Source).LabelGoPageOK;
    FLabelGoPageL := TPagerLabels(Source).FLabelGoPageL;
    FLabelFirstPage := TPagerLabels(Source).FLabelFirstPage;
    FLabelShowAll := TPagerLabels(Source).FLabelShowAll;
  end;
end;

constructor TPagerLabels.Create(AOwner: TComponent);
begin
  inherited Create;
  FOwner := AOwner;

  FLabelNextPage := __DefaultLabelNextPage;
  FLabelRecordCount := __DefaultLabelRecordCount;
  FLabelLastPage := __DefaultLabelLastPage;
  FLabelGoPageR := __DefaultLabelGoPageR;
  FLabelEllipsis := __DefaultLabelEllipsis;
  FLabelPriorPage := __DefaultLabelPriorPage;
  FLabelPageSize := __DefaultLabelPageSize;
  FLabelGoPageOK := __DefaultLabelGoPageOK;
  FLabelGoPageL := __DefaultLabelGoPageL;
  FLabelFirstPage := __DefaultLabelFirstPage;
  FLabelShowAll := __DefaultLabelShowAll;
end;

destructor TPagerLabels.Destroy;
begin

  inherited;
end;

procedure TPagerLabels.DoRePaint;
begin
  if FOwner is TCustomDevDataPager then
  begin
    TCustomDevDataPager(FOwner).PaintChanged;
  end;
end;

procedure TPagerLabels.ModifyElement(AControlType: TControlType;
  ALabel: String);
var
  AElementInfo: PElementInfo;
begin
  AElementInfo := TCustomDevDataPager(FOwner).GetElement(AControlType);
  if AElementInfo <> nil then
  begin
    AElementInfo.Caption := ALabel;
    TCustomDevDataPager(FOwner).Prepare;
  end;
end;

procedure TPagerLabels.SetLabelLabelEllipsis(const Value: String);
begin
  if FLabelEllipsis <> Value then
  begin
    FLabelEllipsis := Value;
    ModifyElement(ctEllipsis, Value);
    DoRePaint;
  end;
end;

procedure TPagerLabels.SetLabelLabelFirstPage(const Value: String);
begin
  if FLabelFirstPage <> Value then
  begin
    FLabelFirstPage := Value;
    ModifyElement(ctFirstPage, Value);
    DoRePaint;
  end;
end;

procedure TPagerLabels.SetLabelLabelGoPageL(const Value: String);
begin
  if FLabelGoPageL <> Value then
  begin
    FLabelGoPageL := Value;
    ModifyElement(ctGoPageLabelL, Value);
    DoRePaint;
  end;
end;

procedure TPagerLabels.SetLabelLabelGoPageOK(const Value: String);
begin
  if FLabelGoPageOK <> Value then
  begin
    FLabelGoPageOK := Value;
    ModifyElement(ctGoPageOk, Value);
    DoRePaint;
  end;
end;

procedure TPagerLabels.SetLabelLabelGoPageR(const Value: String);
begin
  if FLabelGoPageR <> Value then
  begin
    FLabelGoPageR := Value;
    ModifyElement(ctGoPageLabelR, Value);
    DoRePaint;
  end;
end;

procedure TPagerLabels.SetLabelLabelLastPage(const Value: String);
begin
  if FLabelLastPage <> Value then
  begin
    FLabelLastPage := Value;
    ModifyElement(ctLastPage, Value);
    DoRePaint;
  end;
end;

procedure TPagerLabels.SetLabelLabelNextPage(const Value: String);
begin
  if FLabelNextPage <> Value then
  begin
    FLabelNextPage := Value;
    ModifyElement(ctNextPage, Value);
    DoRePaint;
  end;
end;

procedure TPagerLabels.SetLabelLabelPageSize(const Value: String);
begin
  if FLabelPageSize <> Value then
  begin
    FLabelPageSize := Value;
    if TCustomDevDataPager(FOwner).FCanShowAll then
      ModifyElement(ctPageSize, FLabelShowAll)
    else
      ModifyElement(ctPageSize, Format(FLabelPageSize,
        [TCustomDevDataPager(FOwner).PageSize]));
    DoRePaint;
  end;
end;

procedure TPagerLabels.SetLabelLabelPriorPage(const Value: String);
begin
  if FLabelPriorPage <> Value then
  begin
    FLabelPriorPage := Value;
    ModifyElement(ctPriorPage, Value);
    DoRePaint;
  end;
end;

procedure TPagerLabels.SetLabelRecordCount(const Value: String);
begin
  if FLabelRecordCount <> Value then
  begin
    FLabelRecordCount := Value;
    ModifyElement(ctLabelRecordCount, Format(FLabelRecordCount,
      [TCustomDevDataPager(FOwner).RecordCount]));
    DoRePaint;
  end;
end;

procedure TPagerLabels.SetLabelShowAll(const Value: String);
begin
  if FLabelShowAll <> Value then
  begin
    FLabelShowAll := Value;
  end;
end;

end.
