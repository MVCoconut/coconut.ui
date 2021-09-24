package coconut.ui.internal;

import tink.state.*;
import tink.state.internal.*;

using tink.CoreApi;

class Slot<T, Container:ObservableObject<T>>
  extends Invalidatable.Invalidator implements Invalidatable implements ObservableObject<T> {

  var data:Container;
  var link:CallbackLink;

  final defaultData:Container;//TODO: this should be lazy
  #if tink_state.debug
  final owner:{};
  #end
  final comparator:Comparator<T>;

  public var value(get, never):T;
    inline function get_value()
      return observe().value;

  public function new(owner:{}, ?comparator, ?defaultData, ?toString) {
    #if tink_state.debug
      super(toString);
      this.owner = owner;
    #else
      super();
    #end
    this.comparator = comparator;
    this.data = this.defaultData = defaultData;
    list.ondrain = () -> link.cancel();
    list.onfill = () -> heatup();
  }

  function heatup()
    if (data != null) link = data.onInvalidate(this);

  public inline function observe():Observable<T>
    return this;

  public function invalidate()
    fire();

  public function getComparator():Comparator<T>
    return comparator;

  override public function getRevision() {
    var ret = revision;
    if (data != null) ret *= data.getRevision();
    if (defaultData != null) ret *= defaultData.getRevision();
    return ret;
  }

  public function getValue()
    return switch [data, defaultData] {
      case [null, null]: null;
      case [v, null] | [null, v]: v.getValue();
      case [_.getValue() => ret, v]:
        if (ret == null) v.getValue();
        else ret;
    }

  public function isValid()
    return this.data == null || this.data.isValid();

  public function setData(data:Container) {
    if (data == null)
      data = defaultData;
    if (data == this.data) return;

    this.data = data;
    if (list.length > 0) {
      link.cancel();
      heatup();
    }
    fire();
  }

  #if tink_state.debug
  public function getDependencies() {
    var ret = new Array<Observable<Any>>();
    if (data != null)
      ret.push(cast data);
    if (defaultData != data && defaultData != null)
      ret.push(cast defaultData);
    return ret.iterator();
  }
  #end
}