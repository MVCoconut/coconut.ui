package coconut.ui;

import vdom.*;

class BaseView extends coconut.vdom.Renderable {
  
  var cache = new coconut.ui.tools.ViewCache();

  public function new<Data>(data:Data, render:Data->VNode) {
    super(tink.state.Observable.auto(function () { 
      var ret = render(data); 
      cache.purge();
      return ret;
    }));
  }
}