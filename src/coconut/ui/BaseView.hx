package coconut.ui;

import vdom.*;

class BaseView extends coconut.ui.Renderable {
  
  @:noCompletion var cache = new coconut.ui.tools.ViewCache();

  public function new<Data>(data:Data, render:Data->coconut.ui.RenderResult) {
    super(tink.state.Observable.auto(function () { 
      var ret = render(data); 
      cache.purge();
      return ret;
    }));
  }
}