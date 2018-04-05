# px.sdl

*px.sdl.pas* is a single Delphi unit to help with a quick **start** of Delphi+SDL 2.0 projects. Once it's up you keep full control, but
with some help if needed and shouldn't be too late to see if it works or not, so this is the minimal example program:

```pascal
program minimal;
{$APPTYPE CONSOLE}
uses
  px.sdl;
begin
  sdl.start;
end.
```


![Animated gif minimal demo](https://github.com/piXelicidio/px.sdl/blob/master/examples/minimal_SDL2delphi.gif)

With *sdl.start* we have a default SDL app with: A window, renderer, default loop, update, FPS calc, and animated bouncing box.

## The basic texture loading and animated sprite

```pascal
program simpleDraw;
{$APPTYPE CONSOLE}
uses
  px.sdl, sdl2;
var
    angle :single;
    img :PSDL_Texture;
    spriteRect :TSDL_Rect;

procedure GameInit; //your game init/loading textures
begin
  angle := 0;
  img := sdl.loadTexture('isabella.png', spriteRect.w, spriteRect.h);
end;

procedure GameUpdate; //game logic update
begin
  angle := angle + 0.06;
  spriteRect.x:=round( 200 + sin(angle)*80);
  spriteRect.y:=round( 120 + cos(angle)*80);
end;

procedure GameDraw; //game draw sprites
begin
  SDL_RenderClear(sdl.rend);  //do your own direct SDL function calls
  SDL_RenderCopy(sdl.rend, img, nil, @spriteRect);
  SDL_Delay(15);
end;

begin
  sdl.cfg.window.w := 480; //config Window size
  sdl.cfg.window.h := 320;
  sdl.onLoad := gameInit;  //callbacks events
  sdl.onDraw := gameDraw;
  sdl.onUpdate := gameUpdate;
  sdl.start;               //start game
end.
``` 

![Animated gif minimal demo](https://github.com/piXelicidio/px.sdl/blob/master/examples/simpleDraw_SDL2delphi.gif)

Replacing the default behavoir we get our own simple animated sprite app. 

## prerequisits

- My fork of [Pascal-SDL-2-Headers](https://github.com/piXelicidio/Pascal-SDL-2-Headers/tree/updates2) with the last updates (update2 branch).
- [SDL 2.0 libraries](https://www.libsdl.org/download-2.0.php), [SDL2 Image](https://www.libsdl.org/projects/SDL_image/), [SDL2 ttf](https://www.libsdl.org/projects/SDL_ttf/), and others binaries that you may need later.

**On Windows** the DLLs that should go next to your .EXE looks like this:

    SDL2.dll
    SDL2_image.dll
    SDL2_ttf.dll
    zlib1.dll
    libfreetype-6.dll
    libpng16-16.dll

## tested on:
- Delphi XE3 - Windows 7 
