package coconut.ui;

import tink.state.Observable;

using tink.CoreApi;

@:autoBuild(coconut.ui.macros.ViewBuilder.build())
@:observable
class View extends Renderer {
    
  @:keep public var viewId(default, null):Int = idCounter++; static var idCounter = 0;

  public function new(render:Void->coconut.ui.RenderResult) {
    var last:Option<RenderResult> = None;
    super(Observable.auto(function () return switch last {
      case Some(r) if (!shouldViewUpdate()): r;
      default:
        var res = render();
        last = Some(res);
        res;
    }));
  }
  
  @:noCompletion function shouldViewUpdate():Bool return true;
}
