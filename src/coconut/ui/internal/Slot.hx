package coconut.ui.internal;

import tink.state.*;
import tink.state.Observable;

using tink.CoreApi;

class Slot<T, Container:ObservableObject<T>>
  extends Invalidator implements Invalidatable implements ObservableObject<T> {

  var data:Container;
  var link:CallbackLink;

  final defaultData:Container;//TODO: this should be lazy
  final owner:{};
  final comparator:Comparator<T>;

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
    return last =
      switch data {
        case null: null;
        case data:
          switch data.getValue() {
            case null if (data != defaultData && defaultData != null):
              defaultData.getValue();
            case v: v;
          }
      }

  public function isValid()
    return this.data == null || this.data.isValid();

  public function setData(data:Container) {
    if (data == null)
      data = defaultData;
    if (data == this.data) return;

    this.data = data;
    link.cancel();

    if (data != defaultData)
      link = data.onInvalidate(this);

    fire();// TODO: when isValid, poll the value and skip firing if its the same
  }
  #if debug @:keep #end
  function toString()
    return 'Slot($owner)';
}