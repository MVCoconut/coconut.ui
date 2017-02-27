package coconut.ui.tools;

import tink.state.Observable;
import tink.state.*;
using tink.CoreApi;

class Compare {
  
  static var END = Future.sync(Noise);

  static public function stabilize<T>(o:Observable<T>, ?comparator:T->T->Bool) {

    if (comparator == null) 
      comparator = Type.enumEq;

    return Observable.create(function () {
      
      var m = o.measure();

      function check(f:Future<Noise>)
        return f.flatMap(
          function (_) {
            var next = o.measure();
            return 
              if (comparator(m.value, next.value)) check(next.becameInvalid)
              else END;
          }
        );
        
      return new Measurement(m.value, check(m.becameInvalid));
    });
  }

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