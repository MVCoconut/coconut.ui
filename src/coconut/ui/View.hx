package coconut.ui;

import tink.state.Observable;

@:autoBuild(coconut.ui.macros.ViewBuilder.build())
class View extends Renderer {
  
  @:noCompletion var __coco__cache = new coconut.ui.tools.ViewCache();
  
  @:keep public var id(default, null):Int = idCounter++; static var idCounter = 0;

  public function new(render:Void->coconut.ui.RenderResult, ?pos:haxe.PosInfos) {
    super(Observable.auto(function () { 
      return __coco__cache.cached(render);
    }));
  }
}