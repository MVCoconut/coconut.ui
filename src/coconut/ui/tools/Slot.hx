package coconut.ui.tools;

import tink.state.*;
import tink.state.Observable;

using tink.CoreApi;

class Slot<T> implements ObservableObject<T> {
  
  var data:Observable<T>;
  var last:Pair<T, FutureTrigger<Noise>>;
  var link:CallbackLink;
  var owner:{};
  var compare:T->T->Bool;
  var cache = new ViewCache();//TODO: maybe having every slot cached is a bit overkill

  public var value(get, never):T;
    inline function get_value()
      return observe().value;

  public function new(owner, ?compare) {
    this.owner = owner;
    this.compare = switch compare {
      case null: function (a, b) return a == b;
      case v: v;
    }
  }
  
  public function poll() {
    if (last == null) {
      if (data == null) {
        last = new Pair(null, Future.trigger());
      }
      else {
        var m = measure();
        last = new Pair(m.value, Future.trigger());
        link = m.becameInvalid.handle(last.b.trigger);
      }
      last.b.handle(function () last = null);
    }
    return new Measurement(last.a, last.b);
  }

  function measure()
    return cache.cached(data.measure);

  public function observe():Observable<T>
    return this;

  public function setData(data:Observable<T>) {
    this.data = data;
    if (last != null) {
      link.dissolve();
      if (data != null) {
        var m = Observable.untracked(measure);
        
        if (compare(m.value, last.a))
          link = m.becameInvalid.handle(last.b.trigger);
        else
          last.b.trigger(Noise);
      }      
    }
  }
  #if debug @:keep #end
  function toString() 
    return 'Slot($owner)';
}