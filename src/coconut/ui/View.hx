package coconut.ui;

import tink.state.Observable;

using tink.CoreApi;

@:autoBuild(coconut.ui.macros.ViewBuilder.build())
@:observable
class View extends Renderer implements Renderable {
  
  @:noCompletion var __coco__cache = new coconut.ui.tools.ViewCache();
  
  @:keep public var viewId(default, null):Int = idCounter++; static var idCounter = 0;

  public function new(render:Void->coconut.ui.RenderResult) {
    var last:Option<RenderResult> = None;
    super(Observable.auto(function () return { 
      if (!shouldViewUpdate() && last != None) {
        last.force();
      }
      else {
        var res = __coco__cache.cached(render);
        last = Some(res);
        res;
      }
    }));
  }
  
  @:noCompletion function shouldViewUpdate():Bool return true;

  @:noCompletion inline public function getRenderResult():RenderResult 
    return this;
}
