package coconut.ui.tools;

import tink.state.*;
import tink.state.Observable;

using tink.CoreApi;

class Slot<T> implements ObservableObject<T> {
  
  var data:Observable<T>;
  var last:Pair<T, FutureTrigger<Noise>>;
  var link:CallbackLink;
  var owner:{};

  public var value(get, never):T;
    inline function get_value()
      return observe().value;

  public function new(owner) 
    this.owner = owner;
  
  public function poll() {
    if (last == null) {
      if (data == null) {
        last = new Pair(null, Future.trigger());
      }
      else {
        var m = data.measure();
        last = new Pair(m.value, Future.trigger());
        link = m.becameInvalid.handle(last.b.trigger);
      }
      last.b.handle(function () last = null);
    }
    return new Measurement(last.a, last.b);
  }

  public function observe():Observable<T>
    return this;

  public function setData(data:Observable<T>) {
    this.data = data;
    if (last != null) {
      link.dissolve();
      @:privateAccess Observable.stack.push(null);
      var m = data.measure();
      @:privateAccess Observable.stack.pop();
      function compare<A>(after:A, before:A) 
        if (before != after) 
          last.b.trigger(Noise);
        else 
          link = m.becameInvalid.handle(last.b.trigger);

      if (Std.is(m.value, ObservableObject)) {//TODO: this is a bit too late to avoid such effects
        var nu:Observable<Any> = cast m.value,
            old:Observable<Any> = cast last.a;
        compare(nu.value, old.value);
      }
      else compare(m.value, last.a);
    }
  }

  @:keep function toString() {
    return 'Slot($owner)';
  }
}