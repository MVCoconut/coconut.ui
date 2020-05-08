package coconut.ui.tools;

import tink.state.*;
import tink.state.Observable;

using tink.CoreApi;

class Slot<T, Container:ObservableObject<T>>
  extends Invalidator implements Invalidatable implements ObservableObject<T> {

  var defaultData:Container;
  var data:Container;
  var link:CallbackLink;
  var owner:{};
  var comparator:Comparator<T>;

  public var value(get, never):T;
    inline function get_value()
      return observe().value;

  public function new(owner, ?comparator, ?defaultData) {
    super();
    this.owner = owner;
    this.comparator = switch comparator {
      case null: function (a, b) return a == b;
      case v: v;
    }
    this.data = this.defaultData = defaultData;
    if (defaultData != null)
      defaultData.onInvalidate(this);
  }

  public inline function observe():Observable<T>
    return this;

  public function invalidate()
    fire();

  public function getComparator():Comparator<T>
    return comparator;

  var last:T;
  public function getValue()
    return last = switch data.getValue() {
      case null if (data != defaultData && defaultData != null):
        defaultData.getValue();
      case v: v;
    }

  public function setData(data:Container) {
    if (data == null)
      data = defaultData;
    if (data == this.data) return;

    this.data = data;
    link.dissolve();

    if (data != defaultData)
      link = data.onInvalidate(this);

    fire();
  }
  #if debug @:keep #end
  function toString()
    return 'Slot($owner)';
}