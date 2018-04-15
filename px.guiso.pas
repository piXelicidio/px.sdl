unit px.guiso;
{
  Graphical
  User
  Interface for
  SDL2 with
  Object pascal Delphi

  by Denys Almaral
}
interface
uses
  system.Generics.collections,
  sdl2,
  px.sdl;

type

PUIStyle = ^TUIStyle;
TUIStyle = record
  bk :TSDL_Color;
  fg :TSDL_Color;
  hoverBk :TSDL_color;
  hoverFg :TSDL_color;
  activeBk :TSDL_color;
  activeFg :TSDL_color;
  disabledBk :TSDL_color;
  disabledFg :TSDL_color;
end;

TAreaState = ( asNormal, asHover, asActive, asDisabled);

{ TArea is like our TControl  }
//CArea = class of TArea;
TArea = class
  type
    TListAreas = TList<TArea>;
    TUIEventMouseButton = reference to procedure(sender:TArea; mEvent:TSDL_MouseButtonEvent );
    TUIEventMouseMove = reference to procedure(sender:TArea; mEvent:TSDL_MouseMotionEvent );
  private
    fState :TAreaState;
    procedure SetPos(const Value: TSDL_Point);
  protected
    fParent :TArea;
    fPapaOwnsMe :boolean;
    fChilds :TListAreas;
    fRect   :TSDL_Rect;   //rects X,Y are in Screen coordinates;
    fLocal  :TSDL_Point;    //Local coordinates;
    fCatchInput :boolean;
    fVisible :boolean;
    fShowStates :boolean;
    fStyle :TUIStyle;
    fCurrBk : TSDL_Color;
    fCurrFg : TSDL_Color;

    class var fLastMouseMoveArea :TArea;
    class var fLastMouseDownArea :TArea;

    procedure updateScreenCoords;
    procedure setRect(x, y, h, w: integer);
    procedure setState( newState :TAreaState );
  public
    OnMouseMove :TUIEventMouseMove;
    OnMouseDown :TUIEventMouseButton;
    OnMouseUp   :TUIEventMouseButton;
    OnMouseClick  :TUIEventMouseButton;
    papaOwnsMe :boolean;
    Visible :boolean;
    Text :string;
    constructor create;
    destructor Destroy;override;
    procedure setXY( x,y :integer );
    procedure setWH( w,h :integer );
    procedure addChild( newArea : TArea );
    procedure draw;virtual;

    function Consume_MouseButton(const mEvent : TSDL_MouseButtonEvent ):boolean;
    function Consume_MouseMove(const mEvent :TSDL_MouseMotionEvent ):boolean;
    procedure doMouseDown(const mEvent : TSDL_MouseButtonEvent );virtual;
    procedure doMouseUp(const mEvent : TSDL_MouseButtonEvent );virtual;
    procedure doClick(mEvent :TSDL_MouseButtonEvent);virtual; //this one is trigered only if the mouseUp was in the same TArea than mouseDown;
    procedure doMouseMove(const mEvent : TSDL_MouseMotionEvent );virtual;
    procedure doMouseEnter;
    procedure doMouseLeave;
    property pos : TSDL_Point read fLocal write SetPos;
 end;

TGuisoPanel = class (TArea)
  public
    constructor create;
end;

TGuisoScreen = class( TArea )
  private
  public
    constructor create;
    destructor Destroy;override;
    procedure draw;override;
 end;

 var
  styleDefault, stylePanel :TUIStyle;

implementation



{ TArea }


function TArea.Consume_MouseButton(const mEvent: TSDL_MouseButtonEvent): boolean;
var
  i :integer;
  pos :TSDL_Point;
begin
  Result := false;
  if ( not fVisible ) or ( mEvent.button <> 1 ) then exit;
  //for all of these three mouse events, XY are in the same position of the record union
  pos.x := mEvent.x;
  pos.y := mEvent.y;
  if SDL_PointInRect(@pos, @fRect ) then
  begin
    //is inside ok, but let's see if my childs consume this input:
    //mouse inputs are processed in the reverse order of how the GUI areas are painted.
    for i := fChilds.Count-1 downto 0 do
    begin
      Result := fChilds.List[i].Consume_MouseButton(mEvent);
      if Result then break;
    end;
    //if non of my childs consumed the input then I eat it.
    if (not Result) and (fCatchInput) then
    begin
      Result := true;
      if mEvent.type_ = SDL_MOUSEBUTTONDOWN then doMouseDown(mEvent) else doMouseUp(mEvent);
    end;
  end
end;

function TArea.Consume_MouseMove(const mEvent: TSDL_MouseMotionEvent): boolean;
var
  i :integer;
  pos :TSDL_Point;
begin
  Result := false;
  if ( not fVisible ) then exit;
  //for all of these three mouse events, XY are in the same position of the record union
  pos.x := mEvent.x;
  pos.y := mEvent.y;
  if SDL_PointInRect(@pos, @fRect ) then
  begin
    //is inside ok, but let's see if my childs consume this input:
    //mouse inputs are processed in the reverse order of how the GUI areas are painted.
    for i := fChilds.Count-1 downto 0 do
    begin
      Result := fChilds.List[i].Consume_MouseMove(mEvent);
      if Result then break;
    end;
    //if non of my childs consumed the input then I eat it.
    if (not Result) then
    begin
      Result := true;
      if fCatchInput then doMouseMove(mEvent);
      if fLastMouseMoveArea<>self then
      begin
        if assigned(fLastMouseMoveArea)  then if fLastMouseMoveArea.fCatchInput then fLastMouseMoveArea.doMouseLeave;
        fLastMouseMoveArea := self;
        if fCatchInput then doMouseEnter;
      end;
    end;
  end
end;

constructor TArea.create;
begin
  fParent := nil;
  fChilds := TListAreas.create;
  fRect := sdl.Rect(0,0, 100, 20);
  fCatchInput := true;
  fPapaOwnsMe := true;
  fVisible := true;
  fShowStates := true;
  fStyle := styleDefault;
  setState( asNormal );
  fLastMouseMoveArea := nil;
end;

destructor TArea.Destroy;
var
  i :integer;
begin
  //kill childs first
  for i := 0 to fChilds.Count-1 do
    if fChilds.List[i].fPapaOwnsMe then fChilds.List[i].Free;
  fChilds.Free;
end;


procedure TArea.doMouseMove(const mEvent: TSDL_MouseMotionEvent);
begin
  if assigned(OnMouseMove) then OnMouseMove(self, mEvent);
end;

procedure TArea.doClick(mEvent: TSDL_MouseButtonEvent);
begin
  if assigned(OnMouseClick) then OnMouseClick(Self, mEvent);
end;

procedure TArea.doMouseDown(const mEvent: TSDL_MouseButtonEvent);
begin
  setState( asActive );
  fLastMouseDownArea := self;
  if assigned(OnMouseDown) then OnMouseDown(self, mEvent);
end;

procedure TArea.doMouseEnter;
begin
  sdl.print('Entering :'+Text);
  setState(asHover);
end;

procedure TArea.doMouseLeave;
begin
  sdl.print('Leaving :'+Text);
  setState(asNormal);
end;

procedure TArea.doMouseUp(const mEvent: TSDL_MouseButtonEvent);
begin
  if fLastMouseDownArea = self then doClick(mEvent);
  
  if assigned(OnMouseUp) then OnMouseUp(self, mEvent);
  setState( asNormal );
end;

procedure TArea.draw;
var
  i :integer;
  tsize :TSDL_Point;
  tpos :TSDL_Point;
begin
  if fVisible  then
  begin
    sdl.setColor( fCurrBk );
    SDL_RenderFillRect(sdl.rend, @fRect);
    if Text <>'' then
    begin
      //align center
      tsize := sdl.textSize(Text);
      tpos.x := (fRect.x + fRect.w div 2) - (tsize.x div 2);
      tpos.y := (fRect.y + fRect.h div 2) - (tsize.y div 2);
      sdl.drawText(Text, tpos.x, tpos.y, cardinal(fCurrFg));
    end;
    //TODO: mabe clip the area of the childs here?
    for i := 0 to fChilds.Count - 1 do fChilds.List[i].draw;
  end;
end;

procedure TArea.addChild( newArea: TArea);
begin
  if (newArea<>self) and (newArea<>nil) then
  begin
    fChilds.Add(newArea);
    newArea.fPapaOwnsMe := true;
    newArea.fParent := self;
  end else sdl.errorMsg('GUI: You cannot add itself or nil as TArea child');
end;

procedure TArea.SetPos(const Value: TSDL_Point);
begin
  SetXY(Value.x, Value.y);
end;

procedure TArea.setRect(x, y, h, w : integer );
begin
  fRect := sdl.Rect(x,y,h,w);
  updateScreenCoords;
end;

procedure TArea.setState(newState: TAreaState);
begin
  fState := newState;
  if fShowStates then
    case newState of
      asNormal: begin fCurrfg := fStyle.fg ; fCurrBk := fStyle.bk end;
      asHover: begin fCurrfg := fStyle.hoverFg ; fCurrBk := fStyle.hoverBk end;
      asActive: begin fCurrfg := fStyle.activeFg ; fCurrBk := fStyle.activeBk end;
      asDisabled: begin fCurrfg := fStyle.disabledFg ; fCurrBk := fStyle.disabledBk end;
    end;
end;

procedure TArea.setWH(w, h: integer);
begin
  fRect.w := w;
  fRect.h := h;
end;

procedure TArea.setXY(x, y: integer);
begin
  fLocal.x := x;
  fLocal.y := y;
  updateScreenCoords;
end;

{
  since UI most time are static, is better to update the screen coords of the childs
  any time its local x,y are changed than recalculate it every time this coords
  are needed to draw on the screen.
}
procedure TArea.updateScreenCoords;
var
  i: Integer;
begin
  if assigned(fParent) then
  begin
    fRect.x := fParent.fRect.x + fLocal.x;
    fRect.y := fParent.fRect.y + fLocal.y;
  end else
  begin
    fRect.x := fLocal.x;
    fRect.y := fLocal.y;
  end;
  for i := 0 to fChilds.Count-1 do fChilds[i].updateScreenCoords;
end;

{ TGuisoScreen }

constructor TGuisoScreen.create;
begin
  inherited;
  setRect(0,0, sdl.pixelWidth, sdl.pixelHeight);
  fCatchInput := false;
end;

destructor TGuisoScreen.Destroy;
begin

  inherited;
end;

procedure TGuisoScreen.draw;
var
  i: Integer;
begin
  for i := 0 to fChilds.Count-1 do fChilds.List[i].draw;
end;

{ TGuisoPanel }

constructor TGuisoPanel.create;
begin
  inherited;
  fStyle := stylePanel;
  setState(asNormal);
  fShowStates := false;
end;

initialization
  with styleDefault do
  begin
    fg := sdl.color(200,200,200);
    bk := sdl.color(70, 70, 70);
    hoverFg := sdl.color(250, 250, 250);
    hoverBk := sdl.color(60, 150, 30);
    activeFg := sdl.color(255, 255, 255);
    activeBk := sdl.color(220, 170, 5);
    disabledFg := sdl.color(100, 100, 100);
    disabledBk := sdl.color(30, 30, 30);
  end;
  stylePanel := styleDefault;
  with stylePanel do
  begin
    Fg := sdl.color(150, 150, 150);
    Bk := sdl.color(20, 20, 20);
  end;
finalization
end.
