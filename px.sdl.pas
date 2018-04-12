unit px.sdl;

interface

uses
  sdl2, sdl2_image, sdl2_ttf,
  sysutils, generics.collections;

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
    imgFlags :SInt32;
    defaultFont :string;
    defaultFontSize :integer;
    basePath :string;
    savePath_org :string;
    savePath_app :string;
  end;



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

  PBitmapFont = ^TBitmapFont;
  TBitmapFont = record
    srcTex        :PSDL_Texture;
    srcFont       :PTTF_Font;
    asciiSprites  :array[0..255] of TSDL_Rect;
    texW, texH :integer;
    maxW, maxH :integer;
  end;


type

  Tsdl = class
    type
      //TODO: textures in StringList? and check to no reload same texturet twice?
      TTextureList = TList<PSDL_Texture>;
      TFontList = TList<PTTF_Font>;
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
      fFonts    : TFontList;
      fDefaultFont  :PTTF_Font;

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
      fFont: TBitmapFont;

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
      procedure SetFont(const Value: TBitmapFont);

    public  //graphics
      procedure setColor( r, g, b:UInt8; a :UInt8 = 255 );inline;
      procedure drawRect( x, y, w, h :SInt32; fill:boolean = false );inline;
      procedure drawSprite(var sprite :TSprite; ax, ay :integer  );overload;//inline;
      procedure drawSprite(var sprite :TSprite; ax, ay :integer; angle :single);overload;//inline;
      function loadTexture( filename: string  ):PSDL_Texture;overload;
      function loadTexture( filename: string; out w,h:LongInt ):PSDL_Texture;overload;
      function newSprite( srcTex :PSDL_Texture; srcRectPtr:PSDL_Rect = nil):TSprite;overload;
      function newSprite( srcTex :PSDL_Texture; x, y, w, h :SInt32 ):TSprite;overload;
      procedure setCenterToMiddle(var aSprite:TSprite);
      function Rect( ax, ay, aw, ah :integer ):TSDL_Rect;

    public //fonts
      function createBitmapFont( ttf_FileName:string; fontSize :integer ):TBitmapFont;
      function drawText(s:string; x, y :integer; color :cardinal = $ffffff; alpha :byte = 255 ):TSDL_Rect;
      property Font:TBitmapFont read FFont write SetFont;
      property DefaultFont:PTTF_Font read fDefaultFont;
    public //misc utils
      procedure convertGrayscaleToAlpha( surf :PSDL_Surface );
    public  //application
      cfg :TSdlConfig;    //modify values of this record before start, optionally.
      procedure Start;  {***}
      procedure finalizeAll;
      procedure errorFatal;
      procedure errorMsg( s:string );
      procedure debug( s:string );

      constructor create;
      destructor Destroy;override;

      property window:PSDL_Window read fWindow;
      property pixelWidth:LongInt read fPixelWidth;
      property pixelHeight:LongInt read fPixelHeight;
      property rend:PSDL_Renderer read fRend;
      property basePath:string read fBasePath write fBasePath;

      property MainLoop:TProc read fMainLoop write SetMainLoop;
      property frameCounter:cardinal read fFrameCounter;
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

procedure Tsdl.convertGrayscaleToAlpha(surf: PSDL_Surface);
var
  x, y: integer;
  pixel :^cardinal;
  newcolor :cardinal;
begin
  SDL_LockSurface( surf );
  for y := 0 to surf.h-1 do
  begin
    pixel := surf.pixels;
    inc(pixel, y * (surf.pitch div 4) );
    for x := 0 to surf.w-1 do
    begin
      newcolor := SDL_mapRGBA(surf.format, 255, 255, 255, (pixel^ and $ff));
      pixel^ := newcolor;
      inc(pixel)
    end;
  end;
  SDL_UnlockSurface( surf );
end;

constructor Tsdl.create;
begin

  fTitleFPS := true;
  fFrameCounter := 0;
  mainLoop:=appMainLoop;
  onLoad := defaultLoad;
  onDraw := defaultDraw;
  onUpdate := defaultUpdate;

  fTextures := TTextureList.Create;
  fFonts := TFontList.Create;
end;

{
  Creates a bitmap font on the fly from a loaded TTF font file.
  Rasterize all the ASCII characters to a texture,
  for faster text drawing later.
}
function Tsdl.createBitmapFont(ttf_FileName: string;
  fontSize: integer): TBitmapFont;
var
  w  :integer;
  charWidth :array[0..255] of integer;
  i,j: Integer;
  c:byte;
  surf :PSDL_Surface;
  surfChar :PSDL_Surface;
  color :TSDL_Color;
  destRect :TSDL_Rect;
  sdlFont :PTTF_Font;
begin
  Result.maxW := 0;
  sdlFont := TTF_OpenFont(StrToSdl( ttf_FileName ), fontSize );
  if sdlFont = nil then
  begin
    errorMsg('Can''t open font '+ttf_FileName + ' ' + string( TTF_GetError ) );
    exit;
  end;
  Result.srcFont := sdlFont;
  for c := 0 to 255 do
  begin
    //storing char widths and finding the max width
    TTF_SizeText(sdlFont, strToSDL(string(char(c))), @w, nil);
    if w > Result.maxW then Result.maxW := w;
    charWidth[c] := w;
  end;
  Result.maxH := TTF_FontHeight(sdlFont);
  Result.texW := Result.maxW * 16;
  Result.texH := Result.maxH * 16;
  //creating the surface to draw the char matrix of 16 x 16
  surf := SDL_CreateRGBSurfaceWithFormat(0, Result.texW, Result.texH, 32, SDL_PIXELFORMAT_RGBA8888);
  SDL_FillRect(surf, nil, $0 );
  c:= 0;
  color.r := 255;
  color.g := 255;
  color.b := 255;
  color.a := 0;
  for j := 0 to 15 do
    for i := 0 to 15 do
      begin
        if c > 0 then
        begin
          //Rendering a single character to a temporary Surface
          surfChar := TTF_RenderText_Blended(sdlFont, strToSDL(string(char(c))), color );
          destRect := sdl.Rect(i*Result.maxW, j*Result.maxH, charWidth[c], Result.maxH);
          Result.asciiSprites[c] := destRect;
          //bliting the character to our big surface matrix
          SDL_BlitSurface(surfChar, nil, surf,  @destRect  );
          SDL_FreeSurface(surfChar);
        end;
        inc(c);
      end;
  //to fix the problem with alpha premultiplied od TTF_RenderText_Blended
  //we get the image as a grayscale mask and convert the intensity to alpha channel
  sdl.ConvertGrayscaleToAlpha( surf );
  //convert to texture;
  Result.srcTex := SDL_CreateTextureFromSurface(sdl.rend, surf);
  SDL_FreeSurface(surf);
end;

destructor Tsdl.destroy;
begin

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
  for i:=0 to fFonts.Count-1 do
  begin
    TTF_CloseFont(fFonts.Items[i] );
  end;
  fFonts.Free;
  SDL_DestroyRenderer(fRend);
  SDL_DestroyWindow(fWindow);

  TTF_Quit;
  IMG_Quit;
  SDL_Quit;
end;

procedure Tsdl.Start;
var
  rendInfo :TSDL_RendererInfo;
begin
  //initializaitons
  fStarted := true;
  //fBasePath := string(PAnsiChar(SDL_GetBasePath));
  if cfg.basePath='' then  fBasePath := string( SDL_GetBasePath ) else fBasePath := cfg.basePath;
  fPrefPath := string( SDL_GetPrefPath(StrToSdl(cfg.savePath_org), StrToSdl(cfg.savePath_app)) );
  if fPrefPath='' then ;

  if SDL_Init(cfg.subsystems) < 0 then
  begin
    errorFatal;
    exit;
  end else
  begin
    if IMG_Init(cfg.imgFlags) <> cfg.imgFlags then
        errorMsg('Failed to init image format support');

    if TTF_Init()<>0 then
        errorMsg('Failed font support: ' + string( TTF_GetError() ) );

    fDefaultFont := TTF_OpenFont(StrToSDL(fBasePath + cfg.defaultFont), cfg.defaultFontSize );
    if fDefaultFont = nil then
    begin
      errorMsg('TTF_OpenFont : ' + string(TTF_GetError()) );
    end else fFonts.Add( fDefaultFont );

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
  //finalize app
  finalizeAll;
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
  debug('Error: '+ s);
end;

procedure Tsdl.debug(s: string);
begin
  {$IFDEF DEBUG}
    {$IFDEF CONSOLE}
    writeln(s);
    {$ENDIF}
  {$ENDIF}
end;

procedure Tsdl.SetFont(const Value: TBitmapFont);
begin
  FFont := Value;
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

procedure Tsdl.setCenterToMiddle(var aSprite: TSprite);
begin
  aSprite.center.x := aSprite.dstRect.w div 2;
  aSprite.center.y := aSprite.dstRect.h div 2;
end;

procedure Tsdl.setColor(r, g, b: UInt8; a: UInt8);
begin
  SDL_SetRenderDrawColor(fRend, r, g, b, a);
end;


procedure Tsdl.drawRect(x, y, w, h: SInt32; fill:boolean = false );
begin
  fTempRect.x := x;
  fTempRect.y := y;
  fTempRect.w := w;
  fTempRect.h := h;
  if fill then SDL_RenderFillRect(fRend, @fTempRect) else   SDL_RenderDrawRect(fRend, @fTempRect);;
end;

procedure Tsdl.drawSprite(var sprite: TSprite; ax, ay: integer; angle: single);
begin
  with sprite do
  begin
    //TODO use the pivot here
    dstRect.x := ax - center.x;
    dstRect.y := ay - center.y;
    {$IFDEF DEBUG}
    if SDL_RenderCopyEx(fRend, srcTex, srcRectPtr, @dstRect, angle, @sprite.center, SDL_FLIP_NONE )<>0
     then ErrorMsg(string(SDL_GetError));
    {$ELSE}
    SDL_RenderCopyEx(fRend, srcTex, srcRectPtr, @dstRect, angle, @sprite.center, SDL_FLIP_NONE )
    {$ENDIF}
  end;
end;


function Tsdl.drawText(s: string; x, y: integer; color: cardinal;  alpha: byte): TSDL_Rect;
var
  i :integer;
  b :byte;
  srcRect :PSDL_Rect;
  dstRect :TSDL_Rect;
  sc : PSDL_Color;
begin
  sc := @color;
  SDL_SetTextureColorMod(fFont.srcTex, sc.r, sc.g, sc.b);
  SDL_SetTextureAlphaMod(fFont.srcTex, alpha);
  dstRect := sdl.Rect(x,y, fFont.maxW, fFont.maxH);
  for i:=1 to length(s) do
  begin
    b := ord( s[i] );
    srcRect := @fFont.asciiSprites[b];
    dstRect.w := srcRect.w;
    dstRect.h := srcRect.h;
    SDL_RenderCopy(fRend, fFont.srcTex, srcRect, @dstRect);
    dstRect.x := dstRect.x + dstRect.w;
  end;
  result.x := x;
  result.y := y;
  result.h := fFont.maxH;
  result.w := dstRect.x - x;
end;

procedure Tsdl.drawSprite(var sprite:TSprite; ax, ay: integer  );
begin
  with sprite do
  begin
    dstRect.x := ax - center.x;;
    dstRect.y := ay - center.x;;
    {$IFDEF DEBUG}
    if SDL_RenderCopy(fRend, srcTex, srcRectPtr, @dstRect)<>0 then ErrorMsg(string(SDL_GetError));
    {$ELSE}
    SDL_RenderCopy(fRend, srcTex, srcRectPtr, @dstRect);
    {$ENDIF}
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
  //result.center.x := result.dstRect.w div 2;
  //result.center.y := result.dstRect.h div 2;
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
  with sdl.cfg do
  begin
    window.w :=640;
    window.h :=480;
    window.flags := SDL_WINDOW_OPENGL;
    subsystems := SDL_INIT_VIDEO or SDL_INIT_AUDIO or SDL_INIT_TIMER or SDL_INIT_EVENTS ;
    RenderDriverIndex := -1;
    RenderFlags := 0;
    imgFlags := IMG_INIT_PNG;
    defaultFont := 'vera.ttf';
    defaultFontSize := 24;
    basePath := '';
    savePath_org := 'myCompany';
    savePath_app := 'myApp';
  end;
finalization
  sdl.free;
end.

