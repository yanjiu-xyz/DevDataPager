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

  ===================
  2026.10.25

  + 增加 分页区域尺寸属性，默认值保持不变
  + 增加 远程会话变化后的DPI与字体同步
  * 完善 Delphi新旧版本及DevExpress、非DevExpress高分屏适配
  * 调整 字体缩放、皮肤绘制及状态颜色，减少残影和重复重绘
  * 调整 页码输入框字体、内边距及布局同步
  * 修正 鼠标悬停、按下释放及元素重建后的状态处理
  * 修正 总数、页容量变化及重复选择页容量后的页码更新
  * 修正 全部菜单项识别，补齐Setting.Assign属性复制

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
    FHoverElement, FCurrElement, FDownElement: PElementInfo;
    FShowAllMenuItem: TMenuItem;
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
    FSessionNotifyRegistered: Boolean;
    FDpiRefreshPending: Boolean;
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
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
    procedure WndProc(var Message: TMessage); override;
    procedure QueueDpiRefresh;
    procedure RefreshSessionDpi;
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
    function ScaleMetric(const Value: Integer): Integer;
    procedure AssignScaledFont(ACanvas: TCanvas; AFont: TFont);
    function GetElementFont(AControlType: TControlType; AValue: Integer;
      AEnabled: Boolean): TFont;
    procedure DrawElementBackground(ACanvas: TCanvas; const ARect: TRect;
      AFrameColor, AFillColor: TColor);
    procedure DrawElementText(ACanvas: TCanvas; const ARect: TRect;
      const AText: string; AFont: TFont);
{$IF RTLVersion < 34}
{$IF RTLVersion >= 33}
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
{$ELSE}
    procedure ChangeScale(M, D: Integer); override;
{$IFEND}
{$IFEND}

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
{$IF RTLVersion >= 34}
    procedure ScaleForPPI(NewPPI: Integer); override;
{$IFEND}

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
    FRecordCountWidth: Integer;
    FGoPageHeight: Integer;
    FGoPageWidth: Integer;
    FPageSizeWidth: Integer;
    FDropDownButtonWidth: Integer;
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
    procedure SetRecordCountWidth(const Value: Integer);
    procedure SetGoPageHeight(const Value: Integer);
    procedure SetGoPageWidth(const Value: Integer);
    procedure SetPageSizeWidth(const Value: Integer);
    procedure SetDropDownButtonWidth(const Value: Integer);
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

    // 尺寸按96 DPI设置，实际显示时自动缩放，宽高不得小于1
    property RecordCountWidth: Integer read FRecordCountWidth
      write SetRecordCountWidth default 60;
    property GoPageHeight: Integer read FGoPageHeight
      write SetGoPageHeight default 22;
    property GoPageWidth: Integer read FGoPageWidth
      write SetGoPageWidth default 35;
    property PageSizeWidth: Integer read FPageSizeWidth
      write SetPageSizeWidth default 50;
    property DropDownButtonWidth: Integer read FDropDownButtonWidth
      write SetDropDownButtonWidth default 12;

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

const
  WM_PAGER_SESSION_CHANGE = $02B1;
  WM_PAGER_DPI_AFTERPARENT = $02E3;
  WM_PAGER_REFRESH_DPI = WM_APP + $4D1;

type
  TPagerGetDpiForWindow = function(AWindow: HWND): UINT; stdcall;

function PagerRegisterSessionNotification(AWindow: HWND; AFlags: DWORD): BOOL;
  stdcall; external 'wtsapi32.dll' name 'WTSRegisterSessionNotification';
function PagerUnregisterSessionNotification(AWindow: HWND): BOOL;
  stdcall; external 'wtsapi32.dll' name 'WTSUnRegisterSessionNotification';

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
  Result := ALookAndFeel.SkinPainter;
  if Result = nil then
  begin
    Result := ALookAndFeel.Painter;
    if Result = nil then
      Result := cxLookAndFeelPaintersManager.GetPainter(lfsStandard);
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
       PerformEraseBackground(self, MemDC);
       MemBitmap.Canvas.Brush.Color := BackgroundColor;
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
    FRecordCountWidth := TDataPagerSetting(Source).FRecordCountWidth;
    FGoPageHeight := TDataPagerSetting(Source).FGoPageHeight;
    FGoPageWidth := TDataPagerSetting(Source).FGoPageWidth;
    FPageSizeWidth := TDataPagerSetting(Source).FPageSizeWidth;
    FDropDownButtonWidth := TDataPagerSetting(Source).FDropDownButtonWidth;
    FFont.Assign(TDataPagerSetting(Source).FFont);
    FDisabledFont.Assign(TDataPagerSetting(Source).FDisabledFont);
    FLabelFont.Assign(TDataPagerSetting(Source).FLabelFont);
    FElementMinWidth := TDataPagerSetting(Source).FElementMinWidth;
    FActiveFont.Assign(TDataPagerSetting(Source).FActiveFont);
    FBackgroundColor := TDataPagerSetting(Source).FBackgroundColor;
    FElementHeight := TDataPagerSetting(Source).FElementHeight;
    FShowOKButton := TDataPagerSetting(Source).FShowOKButton;
    FShowAll := TDataPagerSetting(Source).FShowAll;

    if FOwner is TCustomDevDataPager then
    begin
      TCustomDevDataPager(FOwner).Prepare;
      TCustomDevDataPager(FOwner).PaintChanged;
    end;
  end
  else
    inherited Assign(Source);
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
  FRecordCountWidth := DevDataPager.RecordCountWidth;
  FGoPageHeight := DevDataPager.GoPageHeight;
  FGoPageWidth := DevDataPager.GoPageWidth;
  FPageSizeWidth := DevDataPager.PageSizeWidth;
  FDropDownButtonWidth := DevDataPager.DropDownButtonWidth;
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
  begin
    TCustomDevDataPager(FOwner).Prepare;
    TCustomDevDataPager(FOwner).PaintChanged;
  end;
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

procedure TDataPagerSetting.SetRecordCountWidth(const Value: Integer);
begin
  if (Value > 0) and (Value <> FRecordCountWidth) then
  begin
    FRecordCountWidth := Value;
    DoChange(Self);
  end;
end;

procedure TDataPagerSetting.SetGoPageHeight(const Value: Integer);
begin
  if (Value > 0) and (Value <> FGoPageHeight) then
  begin
    FGoPageHeight := Value;
    DoChange(Self);
  end;
end;

procedure TDataPagerSetting.SetGoPageWidth(const Value: Integer);
begin
  if (Value > 0) and (Value <> FGoPageWidth) then
  begin
    FGoPageWidth := Value;
    DoChange(Self);
  end;
end;

procedure TDataPagerSetting.SetPageSizeWidth(const Value: Integer);
begin
  if (Value > 0) and (Value <> FPageSizeWidth) then
  begin
    FPageSizeWidth := Value;
    DoChange(Self);
  end;
end;

procedure TDataPagerSetting.SetDropDownButtonWidth(const Value: Integer);
begin
  if (Value > 0) and (Value <> FDropDownButtonWidth) then
  begin
    FDropDownButtonWidth := Value;
    DoChange(Self);
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

  AssignScaledFont(Canvas, GetElementFont(AControlType, AValue, AEnabled));
  ALeft := GetElementWidth;
  AHeight := Max(ScaleMetric(FDataPagerSetting.ElementHeight),
    Canvas.TextHeight(ACaption) + ScaleMetric(6));

  ARect.Left := ALeft;
  ARect.Top := (Height - AHeight) div 2;
  ARect.Height := AHeight;
  if FRecordCount = 0 then
    AWidth := ScaleMetric(Setting.ElementMinWidth) + ScaleMetric(8)
  else
    AWidth := Max(ScaleMetric(Setting.ElementMinWidth),
      Canvas.TextWidth(ACaption) + ScaleMetric(8));
  New(AElementInfo);
  AElementInfo^.OffSet := 0;
  AElementInfo^.Enabled := AEnabled;
  case AControlType of
    ctLabelRecordCount:
      begin
        AElementInfo^.OffSet := ScaleMetric(4);
        ARect.Left := ARect.Left + AElementInfo^.OffSet;
        if FRecordCount = 0 then
          AWidth := ScaleMetric(Setting.RecordCountWidth)
        else
          AWidth := Max(ScaleMetric(Setting.RecordCountWidth),
            Canvas.TextWidth(ACaption) + ScaleMetric(8));
      end;
    ctPriorPage, ctNextPage, ctFirstPage, ctLastPage, ctPageNum:
      begin
        AElementInfo^.OffSet := ScaleMetric(4);
        ARect.Left := ARect.Left + AElementInfo^.OffSet;
      end;
    ctGoPage:
      begin
        AElementInfo^.OffSet := 0;
        ARect.Height := Max(ScaleMetric(Setting.GoPageHeight),
          Canvas.TextHeight('0') + ScaleMetric(6));
        ARect.Top := (ClientHeight - ARect.Height) div 2;
        ARect.Left := ARect.Left + AElementInfo^.OffSet;
        AWidth := Max(ScaleMetric(Setting.GoPageWidth),
          Canvas.TextWidth(CalcPageCount.ToString) + ScaleMetric(8));
      end;
    ctGoPageOk:
      begin
        AElementInfo^.OffSet := 0;
      end;
    ctGoPageLabelL:
      begin
        AElementInfo^.OffSet := ScaleMetric(4);
        ARect.Left := ARect.Left + AElementInfo^.OffSet;
        AWidth := AWidth - ScaleMetric(10) + ScaleMetric(6)
      end;
    ctGoPageLabelR:
      begin
        AElementInfo^.OffSet := 0;
        ARect.Left := ARect.Left + AElementInfo^.OffSet;
        AWidth := AWidth - ScaleMetric(10) + ScaleMetric(4)
      end;
    ctPageSize:
      begin
        AElementInfo^.OffSet := ScaleMetric(4);
        ARect.Left := ARect.Left + AElementInfo^.OffSet;
        if (FDataPagerSetting.ShowAll) and (FCanShowAll) then
        begin
          AWidth := Canvas.TextWidth(FLabels.LabelShowAll) + ScaleMetric(8) +
            ScaleMetric(Setting.DropDownButtonWidth);
        end
        else
        begin
          if FRecordCount = 0 then
            AWidth := ScaleMetric(Setting.PageSizeWidth) +
              ScaleMetric(Setting.DropDownButtonWidth)
          else
            AWidth := Max(ScaleMetric(Setting.PageSizeWidth),
              Canvas.TextWidth(ACaption) + ScaleMetric(8)) +
              ScaleMetric(Setting.DropDownButtonWidth);
        end;
      end;
    ctEllipsis:
      begin
        AElementInfo^.OffSet := ScaleMetric(4);
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
    InflateRect(AGoRect, -ScaleMetric(2), -ScaleMetric(2));
    if not EqualRect(PageNumEdit.BoundsRect, AGoRect) then
      PageNumEdit.SetBounds(AGoRect.Left, AGoRect.Top,
        Max(1, AGoRect.Width), Max(1, AGoRect.Height));
    if (RecordCount > 0) and not PageNumEdit.Visible then
      PageNumEdit.Visible := True;
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
var
  AMousePos: TPoint;
  AOldHoverElement: PElementInfo;
  AHoverRect: TRect;
begin
  inherited;
  GetCursorPos(AMousePos);
  Windows.ScreenToClient(Handle, AMousePos);
  if PtInRect(ClientRect, AMousePos) then
    Exit;

  if self.Cursor <> crDefault then
    self.Cursor := crDefault;

  if (FHoverElement <> nil) or (FCurrElement <> nil) then
  begin
    AOldHoverElement := FHoverElement;
    FHoverElement := nil;
    FCurrElement := nil;
    if AOldHoverElement <> nil then
    begin
      AHoverRect := AOldHoverElement.Rect;
      Windows.InvalidateRect(Handle, @AHoverRect, False);
    end;
  end;
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

  Height := ScaleMetric(35);
  Width := ScaleMetric(700);

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
  FShowAllMenuItem := nil;
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
    FShowAllMenuItem := AItem;
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
  OldPageSize: Integer;
begin
  AItem := TMenuItem(Sender);
  AItem.Checked := True;

  FCanShowAll := AItem = FShowAllMenuItem;
  FPageNum := 1;
  OldPageSize := PageSize;
  PageSize := AItem.Tag;
  if PageSize = OldPageSize then
  begin
    // 页大小不变时 setter 不会重建页码列表，但菜单操作仍会重置到第一页。
    Prepare;
    PaintChanged;
  end;
  PageNumEdit.Value := FPageNum;

  if FCanShowAll then
  begin
    if Assigned(FOnQueryAll) then
      FOnQueryAll(self);
  end
  else if Assigned(FOnPageSize) then
    FOnPageSize(self, PageSize);
end;

procedure TCustomDevDataPager.DrawDropDownButton(ACanvas: TCanvas; R: TRect;
  AFrameColor: TColor; ABrushColor: TColor);
begin
  DrawElementBackground(ACanvas, R, AFrameColor, ABrushColor);
  InflateRect(R, -ScaleMetric(1), -ScaleMetric(1));
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
  Result := (not LookAndFeel.NativeStyle) and
    (LookAndFeel.SkinPainter <> nil);
end;

procedure TCustomDevDataPager.LookAndFeelChanged(Sender: TcxLookAndFeel;
  AChangedValues: TcxLookAndFeelValues);
begin
  inherited;
  Prepare;
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
var
  I: Integer;
  AElementInfo: PElementInfo;
begin
  inherited;
  if (Button = mbLeft) and Enabled then
  begin
    FDownElement := nil;
    for I := 0 to FControlList.Count - 1 do
    begin
      AElementInfo := PElementInfo(FControlList[I]);
      if AElementInfo.Enabled and PtInRect(AElementInfo.Rect, Point(X, Y)) then
      begin
        FDownElement := AElementInfo;
        Break;
      end;
    end;
    PaintChanged;
  end;
end;

procedure TCustomDevDataPager.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
  AElementInfo: PElementInfo;
  ANewHoverElement: PElementInfo;
  AOldHoverElement: PElementInfo;
  AHoverRect: TRect;
  AHoverChanged: Boolean;
begin
  inherited;
  if not(csDesigning in ComponentState) then
  begin
    ANewHoverElement := nil;
    for I := 0 to FControlList.Count - 1 do
    begin
      AElementInfo := PElementInfo(FControlList.Items[I]);
      if AElementInfo.Enabled and
        PtInRect(AElementInfo.Rect, Point(X, Y)) then
      begin
        ANewHoverElement := AElementInfo;
        Break;
      end;
    end;

    AOldHoverElement := FHoverElement;
    AHoverChanged := AOldHoverElement <> ANewHoverElement;
    FHoverElement := ANewHoverElement;
    FCurrElement := ANewHoverElement;

    if (ANewHoverElement <> nil) and
      (ANewHoverElement.ControlType = ctGoPage) then
      AdjustPageNum(ANewHoverElement)
    else if (FPageNumEdit <> nil) and FPageNumEdit.Visible then
      FPageNumEdit.Visible := False;

    if (ANewHoverElement <> nil) and
      (ANewHoverElement.ControlType <> ctGoPage) then
      Cursor := crHandPoint
    else
      Cursor := crDefault;

    if AHoverChanged then
    begin
      if AOldHoverElement <> nil then
      begin
        AHoverRect := AOldHoverElement.Rect;
        Windows.InvalidateRect(Handle, @AHoverRect, False);
      end;
      if ANewHoverElement <> nil then
      begin
        AHoverRect := ANewHoverElement.Rect;
        Windows.InvalidateRect(Handle, @AHoverRect, False);
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
    if (FDownElement <> nil) and
      PtInRect(FDownElement.Rect, Point(X, Y)) then
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
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := AColor;
  ACanvas.Pen.Color := AColor;
  ACanvas.Polygon(p);
end;

procedure TCustomDevDataPager.DrawControl(ACanvas: TCanvas);
{$IFDEF DevGDIPlus}
begin
  inherited;
  if not IsTransparentBackground then
  begin
    ACanvas.Brush.Style := bsSolid;
    if IsUseSkin then
      ACanvas.Brush.Color := Painter.DefaultContentColor
    else
      ACanvas.Brush.Color := FDataPagerSetting.BackgroundColor;
    ACanvas.FillRect(ClientRect);
  end;
  // 背景和文字使用同一 Canvas，避免 GDI+ 缓冲提交覆盖已经绘制的文字
  DrawPageNums(ACanvas, nil);

{$ELSE}

begin
  inherited;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := FDataPagerSetting.BackgroundColor;
  ACanvas.FillRect(ClientRect);
  // Canvas.Brush.Color   := FDataPagerSetting.BackgroundColor;
  DrawPageNums(ACanvas);
{$ENDIF}
end;

procedure TCustomDevDataPager.DrawInternalControl
  (ACanvas: TCanvas{$IFDEF DevGDIPlus}; AGraphics: TdxGPGraphics{$ENDIF};
  AElementInfo: PElementInfo);
  procedure DrawText;
  var
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
      ARect.Width := ARect.Width - ScaleMetric(Setting.DropDownButtonWidth);

    end;

    // LabelFont

    DrawElementText(ACanvas, ARect, AText,
      GetElementFont(AElementInfo.ControlType, AElementInfo.Value,
      AElementInfo.Enabled));
  end;

  procedure DrawGoPage; // 画跳转页
  var
    ABrushColor, AFrameColor: TColor;
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

    DrawElementBackground(ACanvas, ARect, AFrameColor, ABrushColor);
    AText := PageNumEdit.Text;
    if AText.IsEmpty then
    begin
      AText := PageNum.ToString;
      PageNumEdit.Text := AText;
    end;
    DrawElementText(ACanvas, ARect, AText, FDataPagerSetting.Font);
  end;

  procedure DrawButton;
  var
    R: TRect;
    ABrushColor, AFrameColor: TColor;
  begin
    if AElementInfo.Enabled then
    begin
      if (AElementInfo.ControlType = ctPageNum) and
        (AElementInfo.Value = FPageNum) then
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
    DrawElementBackground(ACanvas, R, AFrameColor, ABrushColor);
  end;

{$IFDEF DevGDIPlus}
  procedure DrawSkinButton;
  begin
    if AElementInfo.Enabled then
    begin
      if (AElementInfo.ControlType = ctPageNum) and
        (AElementInfo.Value = FPageNum) then
      begin
        Painter.DrawScaledButton(ACanvas, AElementInfo.Rect,
          '', cxbsPressed, ScaleFactor, True);
      end
      else
      begin
        if FHoverElement = AElementInfo then
          Painter.DrawScaledButton(ACanvas, AElementInfo.Rect,
            '', cxbsHot, ScaleFactor, True)
        else
          Painter.DrawScaledButton(ACanvas, AElementInfo.Rect,
            '', cxbsNormal, ScaleFactor, True);
      end;
    end
    else
    begin
      Painter.DrawScaledButton(ACanvas, AElementInfo.Rect, '',
        cxbsDisabled, ScaleFactor, True);
    end;

  end;
{$ENDIF}
  procedure DrawPageSize;
  var
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
    ARect.Width := ARect.Width - ScaleMetric(Setting.DropDownButtonWidth);
    DrawElementBackground(ACanvas, ARect, AFrameColor, ABrushColor);
    // 画下拉箭头

    ARect.Left := ARect.Left + ARect.Width - ScaleMetric(1);
    ARect.Width := ScaleMetric(Setting.DropDownButtonWidth);
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
          DrawText;
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
    FPageNumEdit.AutoSize := False;
    FPageNumEdit.ParentFont := False;
    AssignScaledFont(Canvas, Setting.Font);
    FPageNumEdit.Font.Assign(Canvas.Font);
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
  if (FControlList = nil) or (FDataPagerSetting = nil) or (FLabels = nil) then
    Exit;
  OldFont := Font;
  try
    APageCount := CalcPageCount;
    FHoverElement := nil;
    FCurrElement := nil;
    FDownElement := nil;
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
    begin
      AssignScaledFont(Canvas, Setting.Font);
      PageNumEdit.Font.Assign(Canvas.Font);
      AdjustPageNum;
    end;
    if FAutoWidth and (Align in [alNone, alLeft, alRight]) then
      Width := GetElementWidth + ScaleMetric(4);
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

procedure TCustomDevDataPager.CreateWnd;
begin
  inherited;
  if not (csDesigning in ComponentState) then
  begin
    FSessionNotifyRegistered := PagerRegisterSessionNotification(Handle, 0);
    QueueDpiRefresh;
  end;
end;

procedure TCustomDevDataPager.DestroyWnd;
begin
  if FSessionNotifyRegistered then
  begin
    PagerUnregisterSessionNotification(Handle);
    FSessionNotifyRegistered := False;
  end;
  FDpiRefreshPending := False;
  inherited;
end;

procedure TCustomDevDataPager.WndProc(var Message: TMessage);
begin
  if Message.Msg = WM_PAGER_REFRESH_DPI then
  begin
    FDpiRefreshPending := False;
    RefreshSessionDpi;
    Message.Result := 0;
    Exit;
  end;
  inherited;
  if Message.Msg = WM_PAGER_DPI_AFTERPARENT then
    QueueDpiRefresh
  else if Message.Msg = WM_PAGER_SESSION_CHANGE then
    case Message.WParam of
      1, 3, 5, 8, 15: QueueDpiRefresh;
    end;
end;

procedure TCustomDevDataPager.QueueDpiRefresh;
begin
  if FDpiRefreshPending or not HandleAllocated or
    (ComponentState * [csDestroying, csDesigning] <> []) then
    Exit;
  // 等宿主处理完 DPI 消息再同步，合并同一次连接中的重复通知
  FDpiRefreshPending := True;
  if not PostMessage(Handle, WM_PAGER_REFRESH_DPI, 0, 0) then
    FDpiRefreshPending := False;
end;

procedure TCustomDevDataPager.RefreshSessionDpi;
{$IF RTLVersion >= 34}
var
  AGetDpiForWindow: TPagerGetDpiForWindow;
  AWindow: HWND;
  APPI: UINT;
{$IFEND}
begin
  if (ComponentState * [csDestroying, csLoading, csDesigning] <> []) or
    (FDataPagerSetting = nil) or (FLabels = nil) then
    Exit;
{$IF RTLVersion >= 34}
  // 动态获取 API，旧版 Windows 仍沿用 VCL 已确定的 DPI
  AGetDpiForWindow := TPagerGetDpiForWindow(GetProcAddress(
    GetModuleHandle('user32.dll'), 'GetDpiForWindow'));
  if Assigned(AGetDpiForWindow) then
  begin
    AWindow := GetAncestor(Handle, GA_ROOT);
    if AWindow = 0 then
      AWindow := Handle;
    APPI := AGetDpiForWindow(AWindow);
    if (APPI > 0) and (APPI <> UINT(CurrentPPI)) then
    begin
      ScaleForPPI(Integer(APPI));
      Exit;
    end;
  end;
{$IFEND}
  Prepare;
  Invalidate;
end;

function TCustomDevDataPager.ScaleMetric(const Value: Integer): Integer;
{$IFNDEF DevGDIPlus}
{$IF RTLVersion < 34}
var
  AParent: TWinControl;
  APPI: Integer;
{$IFEND}
{$ENDIF}
begin
{$IFDEF DevGDIPlus}
  Result := ScaleFactor.Apply(Value);
{$ELSE}
{$IF RTLVersion >= 34}
  Result := ScaleValue(Value);
{$ELSE}
  APPI := Screen.PixelsPerInch;
  AParent := Parent;
  while AParent <> nil do
  begin
    if AParent is TCustomForm then
    begin
      APPI := TCustomForm(AParent).PixelsPerInch;
      Break;
    end;
    AParent := AParent.Parent;
  end;
  Result := MulDiv(Value, APPI, 96);
{$IFEND}
{$ENDIF}
end;

procedure TCustomDevDataPager.AssignScaledFont(ACanvas: TCanvas;
  AFont: TFont);
begin
  ACanvas.Font.Assign(AFont);
  // 按字体自身的源 DPI 换算，避免已缩放字体再次按 96 DPI 放大
  ACanvas.Font.Height := MulDiv(AFont.Height, ScaleMetric(96),
    Max(1, AFont.PixelsPerInch));
end;

function TCustomDevDataPager.GetElementFont(AControlType: TControlType;
  AValue: Integer; AEnabled: Boolean): TFont;
begin
  if AControlType in [ctLabelRecordCount, ctGoPageLabelL, ctGoPageLabelR] then
    Result := Setting.LabelFont
  else if not AEnabled then
    Result := Setting.DisabledFont
  else if (AControlType = ctPageNum) and (AValue = PageNum) then
    Result := Setting.ActiveFont
  else
    Result := Setting.Font;
end;

procedure TCustomDevDataPager.DrawElementBackground(ACanvas: TCanvas;
  const ARect: TRect; AFrameColor, AFillColor: TColor);
var
  AInnerRect: TRect;
  AFrameWidth: Integer;
begin
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := AFrameColor;
  ACanvas.FillRect(ARect);
  AFrameWidth := Max(0, ScaleMetric(Setting.FrameWidth));
  AInnerRect := ARect;
  InflateRect(AInnerRect, -AFrameWidth, -AFrameWidth);
  ACanvas.Brush.Color := AFillColor;
  if not IsRectEmpty(AInnerRect) then
    ACanvas.FillRect(AInnerRect);
end;

procedure TCustomDevDataPager.DrawElementText(ACanvas: TCanvas;
  const ARect: TRect; const AText: string; AFont: TFont);
var
  ADC: HDC;
  ASavedDC: Integer;
  ATextRect: TRect;
begin
  AssignScaledFont(ACanvas, AFont);
  ADC := ACanvas.Handle;
  ASavedDC := SaveDC(ADC);
  try
    SelectObject(ADC, ACanvas.Font.Handle);
    SetTextColor(ADC, ColorToRGB(ACanvas.Font.Color));
    SetBkMode(ADC, Windows.TRANSPARENT);
    ATextRect := ARect;
    // 文字限制在本元素区域，避免较大字体在相邻按钮留下残影
    Windows.DrawTextW(ADC, PWideChar(AText), Length(AText), ATextRect,
      DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
  finally
    RestoreDC(ADC, ASavedDC);
  end;
end;

{$IF RTLVersion >= 34}
procedure TCustomDevDataPager.ScaleForPPI(NewPPI: Integer);
begin
  inherited;
  Prepare;
  PaintChanged;
end;
{$ELSE}
{$IF RTLVersion >= 33}
procedure TCustomDevDataPager.ChangeScale(M, D: Integer;
  isDpiChange: Boolean);
begin
  inherited;
  Prepare;
  PaintChanged;
end;
{$ELSE}
procedure TCustomDevDataPager.ChangeScale(M, D: Integer);
begin
  inherited;
  Prepare;
  PaintChanged;
end;
{$IFEND}
{$IFEND}

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
    if FPageNumEdit <> nil then
      FPageNumEdit.Value := FPageNum;
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
    if FPageNumEdit <> nil then
      FPageNumEdit.Value := FPageNum;
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
