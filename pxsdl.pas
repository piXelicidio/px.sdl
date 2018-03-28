unit pxSdl;

{$mode objfpc}{$H+}

interface

uses
  sdl2, sdl2_image, sysutils, fgl;

type

  TSdlConfig = record
    window : record
      w  :SInt32 ;
      h  :SInt32 ;
    end;
    subsystems : UInt32; //  SDL_INIT_... flags
  end;

  TTextureList = specialize TFPGList<PSDL_Texture>;

  TProc = procedure of object;
  TUpdateProc = procedure( dt : single ) of object;
//  TOnKeyDownProc = procedure() of object;

  { TSDLApp }

  TpxSdl = class
    private
      fStarted :boolean;

      fWindow :PSDL_Window;
      fWinTitle :string;
      fTitleFPS :boolean;

      fRend :PSDL_Renderer;
      fPixelWidth, fPixelHeight :LongInt;
      fTextures : TTextureList;

      fMainLoop :TProc;
      fFrameCounter :Uint32;
      fAveFPS   :Uint32;
      fOnDraw :TProc;
      fOnLoad :TProc;
      fOnUpdate :TProc;
      fEvent  :TSDL_Event;

      fTempRect :TSDL_Rect;
      fDemoX, fDemoY : LongInt;
      fDemoIncX, fDemoIncY : LongInt;

      procedure appMainLoop;
      procedure defaultDraw;
      procedure defaultLoad;
      procedure defaultUpdate;
      procedure SetMainLoop( aMainLoop : TProc );
      procedure SetOnDraw(AValue: TProc);
      procedure SetonLoad(AValue: TProc);
      procedure SetonUpdate(AValue: TProc);
      procedure updateRenderSize;
    public //drawing
      procedure setColor( r, g, b:UInt8; a :UInt8 = 255 );
      procedure drawRect( x, y, w, h :SInt32 );
    public //new, load, create
      function loadTexture( filename: string  ):PSDL_Texture;overload;
      function loadTexture( filename: string; out w,h:LongInt ):PSDL_Texture;overload;
    public
      cfg :TSdlConfig;    //modify values of this record before start, optionally.
      constructor create;
      destructor destroy;override;
      procedure start;
      procedure fatalError;
      property window:PSDL_Window read fWindow;
      property pixelWidth:LongInt read fPixelWidth;
      property pixelHeight:LongInt read fPixelHeight;
      property rend:PSDL_Renderer read fRend;
      property MainLoop:TProc read fMainLoop write SetMainLoop;
      property onLoad:TProc read fOnLoad write SetonLoad;
      property onUpdate:TProc read fOnUpdate write SetonUpdate;
      property onDraw:TProc read fOnDraw write SetOnDraw;
  end;

var
  sdl :TpxSdl;

implementation



{ TpxSdl }

procedure TpxSdl.appMainLoop;
var
  exitLoop :boolean = false;
  lastTick    :Uint32;
  frameStep   :Uint32;
  currTick    :UInt32;
  titleFPS  :string;
begin
  lastTick := SDL_GetTicks;
  fFrameCounter := 0;
  frameStep     := 0;
  while exitLoop = false do
  begin
    //process events
    while SDL_PollEvent(@fEvent) = 1 do
    begin
      case fEvent.type_ of
        SDL_KEYDOWN:;
        SDL_KEYUP:;
        SDL_TEXTINPUT:;
        SDL_MOUSEMOTION:;
        SDL_MOUSEBUTTONDOWN:;
        SDL_MOUSEBUTTONUP:;
        SDL_MOUSEWHEEL:;
        SDL_WINDOWEVENT:;
        SDL_QUITEV : exitLoop:=true;
      else
        //TODO: ProcessAdditionalEvents(fEvent):
      end
    end;
    //update
    fOnUpdate(); //TODO: calc dt when necessary
    //draw;
    fOnDraw();
    SDL_RenderPresent(fRend);
    //framerate handling
    inc(fFrameCounter);
    inc(frameStep);
    if frameStep >= 30 then
    begin
      frameStep := 0;
      currTick := SDL_GetTicks;
      fAveFPS := (1000 * 30) div (currTick - lastTick) ;
      lastTick := currTick;
      titleFPS := fWinTitle +  ' FPS: ' + IntToStr(fAveFPS);
      if fTitleFPS then SDL_SetWindowTitle( fWindow, PChar(titleFPS)  );
    end;
    //SDL_Delay(1);
  end
end;

procedure TpxSdl.defaultDraw;

begin
  setColor(0,0,0);
  SDL_RenderClear(fRend);
  setColor(255,255,255);
  drawRect(fDemoX, fDemoY, 100, 100);
end;

procedure TpxSdl.defaultLoad;
begin
  fDemoX := 0; fDemoY:=0;
  fDemoIncX := 1; fDemoIncY := 1;
end;

procedure TpxSdl.defaultUpdate;
begin
  fDemoX := fDemoX + fDemoIncX;
  fDemoY := fDemoY + fDemoIncY;
  if fDemoX < 0 then fDemoIncX := 1 else if fDemoX > fPixelWidth-100 then fDemoIncX := -1;
  if fDemoY < 0 then fDemoIncY := 1 else if fDemoY > fPixelHeight-100 then fDemoIncY := -1;
end;

constructor TpxSdl.create;
begin
  with cfg do
  begin
    window.w :=640;
    window.h :=480;
    subsystems := SDL_INIT_VIDEO or SDL_INIT_AUDIO or SDL_INIT_TIMER or SDL_INIT_EVENTS
  end;
  fTitleFPS := true;
  fFrameCounter := 0;
  mainLoop:=@appMainLoop;
  onLoad := @defaultLoad;
  onDraw := @defaultDraw;
  onUpdate := @defaultUpdate;

  fTextures := TTextureList.Create;
end;

destructor TpxSdl.destroy;
var
  i:integer;
begin
  for i:=0 to fTextures.Count-1 do
  begin
    SDL_DestroyTexture( fTextures.Items[i] );
  end;
  fTextures.Free;
  SDL_DestroyRenderer(fRend);
  SDL_DestroyWindow(fWindow);
  SDL_Quit;
end;

procedure TpxSdl.start;
var
  winflags :UInt32;
begin
  //initializaitons
  fStarted := true;
  if SDL_Init(cfg.subsystems) < 0 then
  begin
    fatalError;
    exit;
  end else
  begin
    winflags := 0;
    fWinTitle := 'SDL App';
    fWindow := SDL_CreateWindow(PChar(fWinTitle), SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, cfg.window.w, cfg.window.h, winflags );
    if fWindow = nil then begin fatalError; exit; end;
    fRend := SDL_CreateRenderer(fWindow, -1, 0);
    if fRend = nil then begin fatalError; exit; end;
    updateRenderSize;
  end;
  //Load
  fOnLoad;
  //run applicaiton
  fMainLoop;
end;

procedure TpxSdl.fatalError;
begin
  writeln('Fail.')
end;

procedure TpxSdl.SetMainLoop(aMainLoop: TProc);
begin
  if aMainLoop <> nil then fMainLoop := aMainLoop;
end;

procedure TpxSdl.SetOnDraw(AValue: TProc);
begin
  if AValue<>nil then fOnDraw:=AValue;
end;

procedure TpxSdl.SetonLoad(AValue: TProc);
begin
  if AValue<>nil then fOnLoad:=AValue;
end;

procedure TpxSdl.SetonUpdate(AValue: TProc);
begin
  if AValue<>nil then FonUpdate:=AValue;
end;

procedure TpxSdl.updateRenderSize;
begin
  SDL_GetRendererOutputSize(fRend, @fPixelWidth, @fPixelHeight);
end;

procedure TpxSdl.setColor(r, g, b: UInt8; a: UInt8);
begin
  SDL_SetRenderDrawColor(fRend, r, g, b, a);
end;


procedure TpxSdl.drawRect(x, y, w, h: SInt32 );
begin
  fTempRect.x := x;
  fTempRect.y := y;
  fTempRect.w := w;
  fTempRect.h := h;
  SDL_RenderDrawRect(fRend, @fTempRect);
end;

function TpxSdl.loadTexture(filename: string): PSDL_Texture;
begin
  Result := IMG_LoadTexture(fRend, PChar(filename));
  if Result<>nil then
  begin
    fTextures.add(Result);
  end;
end;

function TpxSdl.loadTexture(filename: string; out w, h: LongInt): PSDL_Texture;
begin
  Result := IMG_LoadTexture(fRend, PChar(filename));
  if Result<>nil then
  begin
    fTextures.add(Result);
    SDL_QueryTexture(Result, nil, nil, @w, @h);
  end;
end;


initialization
  sdl := TpxSdl.create;
finalization
  sdl.free;
end.

