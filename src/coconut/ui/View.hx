package coconut.ui;

import tink.state.Observable;

using tink.CoreApi;

@:autoBuild(coconut.ui.macros.ViewBuilder.build())
@:observable
class View extends Renderer implements Renderable {
    
  @:keep public var viewId(default, null):Int = idCounter++; static var idCounter = 0;

  public function new(render:Void->coconut.ui.RenderResult) {
    var last:Option<RenderResult> = None;
    super(Observable.auto(function () return { 
      if (!shouldUpdate() && last != None) {
        last.force();
      }
      else {
        var res = render();
        last = Some(res);
        res;
      }
    }));
  }
  
  @:noCompletion function shouldUpdate():Bool return true;

  @:noCompletion inline public function getRenderResult():RenderResult 
    return this;
}
