package coconut.data;

import tink.pure.List;
using tink.CoreApi;

interface Selection<T, R> extends Model {
  
  var options(get, never):List<Named<T>>;
  var selected(get, never):R;

  function isActive(option:T):Bool;
  function isEnabled(option:T):Bool;
  function toggle(option:T):Bool;

}

abstract SingleSelection<T>(SelectionBase<T, T>) {
  public function new(args:{ options: List<Named<T>>,  }) {
    super({
      options: args.options,
      reduce: function (l) return l.iterator().next(),
      toggler: function () {},
    });
  }
}

class MultipleSelection<T> extends SelectionBase<T, T> {
  
}

enum OptionKind {
  
}

class SelectionBase<T, R> implements Selection<T, R> {
  
  @:observable private var active:List<T>;

  @:observable var options:List<Named<T>>;
  @:observable var reduce:List<T>->R;
  @:observable var toggler:List<T>->T->List<T>;
  @:observable var comparator:T->T->Bool = function (x, y) return x == y;
  
  @:computed var selected:R = reduce(active);

  public function isActive(option:T)
    return active.exists(comparator.bind(option));

  public function isEnabled(option:T):Bool
    return true;

  @:transition public function toggle(option:T):Bool {

    this.active = toggle(this.active, option);

    return isActive(option);
  }
}