package coconut.ui.macros;

#if macro
import haxe.macro.Context;

class ViewBase {
  static var added = macro class {
    public var viewId(default, null):Int = idCounter++; static var idCounter = 0;

    @:noCompletion var _coco_revision = new tink.state.State(0);

    public function new(
        render:Void->RenderResult,
        shouldUpdate:Void->Bool,
        track:Void->Void,
        beforeRerender:Void->Void,
        rendered:Bool->Void
      ) {

      var mounted = if (rendered != null) rendered.bind(true) else null,
          updated = if (rendered != null) rendered.bind(false) else null;

      var firstTime = true,
          last = null,
          hasBeforeRerender = beforeRerender != null,
          hasUpdated = updated != null,
          lastRev = _coco_revision.value;

      super(
        tink.state.Observable.auto(
          function renderView() {
            var curRev = _coco_revision.value;
            if (track != null) track();

            if (firstTime) firstTime = false;
            else {
              if (curRev == lastRev && shouldUpdate != null && !shouldUpdate())
                return last;
              var hasCallbacks = __bc.length > 0;
              if (hasBeforeRerender || hasCallbacks)
                tink.state.Observable.untracked(function () {
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
            tink.state.Observable.untracked(function () {
              if (hasUpdated) updated();
              if (hasCallbacks) for (c in __au.splice(0, __au.length)) c.invoke(Noise);
            });
        },
        function () {
          last = null;
          firstTime = true;
          __beforeUnmount();
        }
      );
    }

    @:noCompletion var __bu:Array<tink.core.Callback.CallbackLink> = [];
    @:noCompletion function __beforeUnmount() {
      for (c in __bu.splice(0, __bu.length)) c.dissolve();
      for (c in __bc.splice(0, __bu.length)) c.invoke(true);
    }

    @:extern inline function untilUnmounted(c:tink.core.Callback.CallbackLink):Void __bu.push(c);
    @:extern inline function beforeUnmounting(c:tink.core.Callback.CallbackLink):Void __bu.push(c);

    @:noCompletion var __bc:Array<tink.core.Callback<Bool>> = [];

    @:extern inline function untilNextChange(c:tink.core.Callback<Bool>):Void __bc.push(c);
    @:extern inline function beforeNextChange(c:tink.core.Callback<Bool>):Void __bc.push(c);

    @:noCompletion var __au:Array<tink.core.Callback<tink.core.Noise>> = [];

    @:extern inline function afterUpdating(callback:Void->Void) __au.push(callback);

    function forceUpdate(?callback) {
      _coco_revision.set(_coco_revision.value + 1);
      if (callback != null) afterUpdating(callback);
    }
  }
  static function build() {
    var cls = Context.getLocalClass().get();
    cls.meta.add(':observable', [], (macro null).pos);
    cls.meta.add(':coconut.viewbase', [], (macro null).pos);
    cls.meta.add(':autoBuild', [macro coconut.ui.macros.ViewBuilder.build()], (macro null).pos);
    return Context.getBuildFields().concat(added.fields);
  }
}
#end
