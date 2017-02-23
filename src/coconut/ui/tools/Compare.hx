package coconut.ui.tools;

import tink.state.Observable;

class Compare {
  static public function shallow<A:{}>(old:A, nu:A) {
    if (nu == old) return true;

    for (f in Reflect.fields(nu)) {
      var nu = Reflect.field(nu, f),
          old = Reflect.field(old, f);

      if (old != nu) 
        switch [Std.instance(old, ConstObservable), Std.instance(nu, ConstObservable)] {
          case [null, _] | [_, null]: 
            return false;
          case [a, b]: 
            if (a.m.value != b.m.value)
              return false;
        }
    }
    return true;    
  }
}