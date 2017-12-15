package coconut.ui.tools;

import tink.state.*;
import tink.state.Observable;

using tink.CoreApi;

class Slot<T> implements ObservableObject<T> {
  var data:Observable<T>;
  var last:Pair<T, FutureTrigger<Noise>>;
  var link:CallbackLink;

  public function new() {}
  
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

  public function setData(data) {
    this.data = data;
    if (last != null) {
      link.dissolve();
      var m = data.measure();
      if (m.value != last.a)
        last.b.trigger(Noise);
      else
        link = m.becameInvalid.handle(last.b.trigger);
    }
  }
}