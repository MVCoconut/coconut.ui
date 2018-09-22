package coconut.ui;

import tink.state.Observable;

using tink.CoreApi;

#if !macro
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
  macro function hxx(e);
  @:noCompletion function shouldViewUpdate():Bool return true;
}
#else
class View {
  static function hxx(_, e)
    return coconut.ui.macros.HXX.parse(e);
}
#end