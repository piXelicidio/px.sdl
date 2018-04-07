unit px.sdl;

interface

uses
  sdl2, sdl2_image, sysutils, generics.collections;

type

  TSdlConfig = record
    window : record
      w  :SInt32 ;
      h  :SInt32 ;
      flags :UInt32;
    end;
    subsystems : UInt32; //  SDL_INIT_... flags
    RenderDriverIndex :SInt32;
    RenderFlags :UInt32;
  end;

  //TODO: textures in StringList? and check to no reload same texturet twice?
  TTextureList = TList<PSDL_Texture>;

   // using reference to procedure callbacks can be annonymos functions,
   // regular procedures or procedure of object, as I unduerstand :)_
  TProc = reference to procedure;
  //  TProc = procedure of object;

  PSprite = ^TSprite;
  TSprite = record
    srcTex      :PSDL_Texture;
    srcRectPtr  :PSDL_Rect;  //can be nil to take entire texture, or point to the next field:
    srcRect     :TSDL_Rect;  // the actual rect that srcRectPtr should point to
    dstRect     :TSDL_Rect;  //position and dimentions to draw;
    center      :TSDL_Point;  //pivot point
  end;


type


  Tsdl = class
    public
      constructor create;
      destructor Destroy;override;
    private
      fStarted :boolean;
      fBasePath :string;
      fPrefPath :string;

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
      fOnFinalize: TProc;
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
      procedure SetonFinalize(const Value: TProc);
    public //drawing
      procedure setColor( r, g, b:UInt8; a :UInt8 = 255 );inline;
      procedure drawRect( x, y, w, h :SInt32 );inline;
      procedure drawSprite(var sprite :TSprite; ax, ay :integer  );overload;//inline;
      procedure drawSprite(var sprite :TSprite; ax, ay :integer; angle :single);overload;//inline;
    public //utils
      function loadTexture( filename: string  ):PSDL_Texture;overload;
      function loadTexture( filename: string; out w,h:LongInt ):PSDL_Texture;overload;
      function newSprite( srcTex :PSDL_Texture; srcRectPtr:PSDL_Rect = nil):TSprite;overload;
      function newSprite( srcTex :PSDL_Texture; x, y, w, h :SInt32 ):TSprite;overload;
      function Rect( ax, ay, aw, ah :integer ):TSDL_Rect;
    public
      cfg :TSdlConfig;    //modify values of this record before start, optionally.
      procedure Start;  {***}
      procedure finalizeAll;
      procedure errorFatal;
      procedure errorMsg( s:string );
      procedure debug( s:string );
      property window:PSDL_Window read fWindow;
      property pixelWidth:LongInt read fPixelWidth;
      property pixelHeight:LongInt read fPixelHeight;
      property rend:PSDL_Renderer read fRend;
      property MainLoop:TProc read fMainLoop write SetMainLoop;
      property onLoad:TProc read fOnLoad write SetonLoad;
      property onUpdate:TProc read fOnUpdate write SetonUpdate;
      property onDraw:TProc read fOnDraw write SetOnDraw;
      property onFinalize:TProc read fOnFinalize write SetonFinalize;
  end;

  function StrToSDL( s: string ):PAnsiChar;
//  function SDLtoString( p: PChar ):string;

var
  sdl :Tsdl;

implementation

function StrToSDL( s: string ):PAnsiChar;
begin
  Result := PAnsiChar(AnsiString(s));
end;


{ Tsdl }

procedure Tsdl.appMainLoop;
var
  exitLoop :boolean;
  lastTick    :Uint32;
  frameStep   :Uint32;
  currTick    :UInt32;
  titleFPS  :string;
begin
  exitLoop := false;
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
      if fTitleFPS then SDL_SetWindowTitle( fWindow, PAnsiChar(AnsiString(titleFPS))  );
    end;
    //SDL_Delay(1);
  end
end;

procedure Tsdl.defaultDraw;

begin
  setColor(0,0,0);
  SDL_RenderClear(fRend);
  setColor(255,255,255);
  drawRect(fDemoX, fDemoY, 100, 100);
end;

procedure Tsdl.defaultLoad;
begin
  fDemoX := 0; fDemoY:=0;
  fDemoIncX := 1; fDemoIncY := 1;
end;

procedure Tsdl.defaultUpdate;
begin
  fDemoX := fDemoX + fDemoIncX;
  fDemoY := fDemoY + fDemoIncY;
  if fDemoX < 0 then fDemoIncX := 1 else if fDemoX > fPixelWidth-100 then fDemoIncX := -1;
  if fDemoY < 0 then fDemoIncY := 1 else if fDemoY > fPixelHeight-100 then fDemoIncY := -1;
  SDL_Delay(1);
end;

constructor Tsdl.create;
begin
  with cfg do
  begin
    window.w :=640;
    window.h :=480;
    window.flags := SDL_WINDOW_OPENGL;
    subsystems := SDL_INIT_VIDEO or SDL_INIT_AUDIO or SDL_INIT_TIMER or SDL_INIT_EVENTS ;
    RenderDriverIndex := -1;
    RenderFlags := 0;
  end;
  fTitleFPS := true;
  fFrameCounter := 0;
  mainLoop:=appMainLoop;
  onLoad := defaultLoad;
  onDraw := defaultDraw;
  onUpdate := defaultUpdate;

  fTextures := TTextureList.Create;
end;

destructor Tsdl.destroy;
begin
  finalizeAll;
end;

procedure Tsdl.finalizeAll;
var
  i:integer;
begin
  if Assigned(fOnFinalize)  then fOnFinalize();

  for i:=0 to fTextures.Count-1 do
  begin
    SDL_DestroyTexture( fTextures.Items[i] );
  end;
  fTextures.Free;
  SDL_DestroyRenderer(fRend);
  SDL_DestroyWindow(fWindow);
  SDL_Quit;
end;

procedure Tsdl.Start;
var
  rendInfo :TSDL_RendererInfo;
begin
  //initializaitons
  fStarted := true;
  //fBasePath := string(PAnsiChar(SDL_GetBasePath));
  fBasePath := string( SDL_GetBasePath );
  fPrefPath := string( SDL_GetPrefPath(StrToSdl('denysapp'), StrToSdl('sdlapp')) );
  if fPrefPath='' then ;

  if SDL_Init(cfg.subsystems) < 0 then
  begin
    errorFatal;
    exit;
  end else
  begin

    fWinTitle := 'SDL App';
    fWindow := SDL_CreateWindow(StrToSdl(fWinTitle), SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, cfg.window.w, cfg.window.h, cfg.window.flags );
    if fWindow = nil then errorFatal;
    fRend := SDL_CreateRenderer(fWindow, cfg.RenderDriverIndex, cfg.RenderFlags);
    if fRend = nil then errorFatal;
    SDL_GetRendererInfo(fRend,@rendInfo);
    Debug('Renderer: '+ string(rendInfo.name));
    updateRenderSize;
  end;
  //Load
  fOnLoad;
  //run applicaiton
  fMainLoop;
end;

procedure Tsdl.errorFatal;
begin
  finalizeAll;
  debug('ERROR: '+ string(SDL_GetError) );
  SDL_Delay(2000);
  Halt;
end;

procedure Tsdl.errorMsg(s:string);
begin
  writeln('Error: '+ s);
end;

procedure Tsdl.debug(s: string);
begin
  writeln(s);
end;

procedure Tsdl.SetMainLoop(aMainLoop: TProc);
begin
  if Assigned(aMainLoop) then fMainLoop := aMainLoop;
end;

procedure Tsdl.SetOnDraw(AValue: TProc);
begin
  if Assigned(AValue) then fOnDraw:=AValue;
end;

procedure Tsdl.SetonFinalize(const Value: TProc);
begin
  if Assigned(Value) then fOnFinalize := Value;
end;

procedure Tsdl.SetonLoad(AValue: TProc);
begin
  if Assigned(AValue) then fOnLoad:=AValue;
end;

procedure Tsdl.SetonUpdate(AValue: TProc);
begin
  if Assigned(AValue) then FonUpdate:=AValue;
end;

procedure Tsdl.updateRenderSize;
begin
  SDL_GetRendererOutputSize(fRend, @fPixelWidth, @fPixelHeight);
end;

procedure Tsdl.setColor(r, g, b: UInt8; a: UInt8);
begin
  SDL_SetRenderDrawColor(fRend, r, g, b, a);
end;


procedure Tsdl.drawRect(x, y, w, h: SInt32 );
begin
  fTempRect.x := x;
  fTempRect.y := y;
  fTempRect.w := w;
  fTempRect.h := h;
  SDL_RenderDrawRect(fRend, @fTempRect);
end;

procedure Tsdl.drawSprite(var sprite: TSprite; ax, ay: integer; angle: single);
begin
  with sprite do
  begin
    //TODO use the pivot here
    dstRect.x := ax - center.x;
    dstRect.y := ay - center.y;
    SDL_RenderCopyEx(fRend, srcTex, srcRectPtr, @dstRect, angle, @sprite.center, SDL_FLIP_NONE );
  end;
end;

procedure Tsdl.drawSprite(var sprite:TSprite; ax, ay: integer );
begin
  sprite := Default(TSprite);
  with sprite do
  begin
    dstRect.x := ax - center.x;;
    dstRect.y := ay - center.x;;
    SDL_RenderCopy(fRend, srcTex, srcRectPtr, @dstRect);
  end;
end;

function Tsdl.loadTexture(filename: string): PSDL_Texture;
begin
  //TODO: Check if the texture is already loaded, reuse pointer.
  Result := IMG_LoadTexture(fRend, PAnsiChar(AnsiString( fBasePath + filename )));
  if Result<>nil then
  begin
    fTextures.add(Result);
  end else errorMsg('Problem loading texture: '+ fBasePath + filename);
end;

function Tsdl.loadTexture(filename: string; out w, h: LongInt): PSDL_Texture;
begin
  Result := loadTexture(filename); //IMG_LoadTexture(fRend, PAnsiChar(AnsiString(filename)) );
  if Result<>nil then
  begin
    fTextures.add(Result);
    SDL_QueryTexture(Result, nil, nil, @w, @h);
  end;
end;

function Tsdl.newSprite(srcTex: PSDL_Texture; x, y, w, h: SInt32): TSprite;
var
  r :TSDL_Rect;
begin
  r := Rect(x,y,w,h);
  result := newSprite(srcTex, @r);
end;

function Tsdl.newSprite(srcTex: PSDL_Texture; srcRectPtr: PSDL_Rect): TSprite;
begin
  result := Default(TSprite);
  result.srcTex := srcTex;
  if srcRectPtr = nil then
  begin
    //get the whole texture we need the dimensions
    SDL_QueryTexture(srcTex, nil, nil, @result.dstRect.w, @result.dstRect.h);
    result.srcRect.w := result.dstRect.w;
    result.srcRect.h := result.dstRect.h;
  end else
  begin
    result.srcRect := srcRectPtr^;
    result.srcRectPtr := @result.srcRect
  end;
  result.center.x := result.dstRect.w div 2;
  result.center.y := result.dstRect.h div 2;
end;

function Tsdl.Rect(ax, ay, aw, ah: integer): TSDL_Rect;
begin
  with result do
  begin
    x := ax;
    y := ay;
    w := aw;
    h := ah;
  end;
end;

initialization
  sdl := Tsdl.create;
finalization
  sdl.free;
end.

