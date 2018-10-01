package coconut.ui;

import tink.state.*;

using tink.CoreApi;

#if !macro
@:autoBuild(coconut.ui.macros.ViewBuilder.build())
@:observable
class View extends Renderer {
    
  @:keep public var viewId(default, null):Int = idCounter++; static var idCounter = 0;
  
  var __revisionCounter = new State(0);

  public function new(
      render:Void->RenderResult, 
      shouldUpdate:Void->Bool, 
      track:Void->Void, 
      beforeRerender:Void->Void,
      mounted:Void->Void,
      updated:Void->Void
    ) {
    
    var firstTime = true,
        last = null,
        hasBeforeRerender = beforeRerender != null,
        hasUpdated = updated != null,
        lastRev = __revisionCounter.value; 

    super(
      Observable.auto(
        function renderView() {
          var curRev = __revisionCounter.value;
          if (track != null) track();

          if (firstTime) firstTime = false;
          else {
            if (curRev == lastRev && shouldUpdate != null && !shouldUpdate()) 
              return last;
            var hasCallbacks = __bc.length > 0;
            if (hasBeforeRerender || hasCallbacks)
              Observable.untracked(function () {
                if (hasBeforeRerender) beforeRerender();
                if (hasCallbacks) for (c in __bc.splice(0, __bc.length)) c.invoke(false);
              });
          }
          lastRev = curRev;
          return last = render();
        }
      ),
      mounted, 
      function () {
        var hasCallbacks = __au.length > 0;
        if (hasUpdated || hasCallbacks) 
          Observable.untracked(function () {
            if (hasUpdated) updated();
            if (hasCallbacks) for (c in __au.splice(0, __au.length)) c.invoke(Noise);              
          });
      }, 
      __beforeUnmount
    );
  }

  @:noCompletion var __bu:Array<CallbackLink> = [];
  @:noCompletion function __beforeUnmount() {
    for (c in __bu.splice(0, __bu.length)) c.dissolve();
    for (c in __bc.splice(0, __bu.length)) c.invoke(true);
  }

  @:extern inline function untilUnmounted(c:CallbackLink):Void __bu.push(c);
  @:extern inline function beforeUnmounting(c:CallbackLink):Void __bu.push(c);

  @:noCompletion var __bc:Array<Callback<Bool>> = [];

  @:extern inline function untilNextChange(c:Callback<Bool>):Void __bc.push(c);
  @:extern inline function beforeNextChange(c:Callback<Bool>):Void __bc.push(c);
  
  @:noCompletion var __au:Array<Callback<Noise>> = [];

  @:extern inline function afterUpdating(callback:Void->Void) __au.push(callback);

  override function forceUpdate(?callback) {
    __revisionCounter.set(__revisionCounter.value + 1);
    if (callback != null) afterUpdating(callback);
  }

  macro function hxx(e);

}
#else
class View {
  static function hxx(_, e)
    return coconut.ui.macros.HXX.parse(e);
}
#end