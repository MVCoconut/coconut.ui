package coconut.ui;

class BaseView extends coconut.ui.Renderable {
  
  @:noCompletion var __coco__cache = new coconut.ui.tools.ViewCache();
  
  @:keep public var id(default, null):Int = idCounter++; static var idCounter = 0;

  public function new<Data>(data:Data, render:Data->coconut.ui.RenderResult) {
    super(tink.state.Observable.auto(function () { 
      return __coco__cache.cached(render.bind(data));
    }));
  }
}