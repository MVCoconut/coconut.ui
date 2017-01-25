package coconut.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;

class ModelMacro { 
  static function process(c:ClassBuilder) {
    switch c.target.superClass.params {
      case [_.reduce() => TAnonymous(_.get().fields => fields)]:  
        
        var isWritable:String->Bool =
          switch c.target.meta.extract(':writable') {
            case [{ params: [] }]: 
              function (_) return true;
            case [{ params: args }]:
              [for (a in args) a.getName().sure() => true].get;
            case []:
              function (_) return false;
            case v: 
              v[1].pos.error('no more than one @:writable directive allowed');
          }

        function add(td:TypeDefinition)
          for (f in td.fields)
            c.addMember(f);
        
        var nuFields = [];
        
        for (f in fields)
          switch c.memberByName(f.name) {
            case Success(m):
              
              switch m.kind {
                case FFun(f): 
                                    
                default:
                  m.pos.error('field ${f.name} is conflicting with model data');
              }
              var name = f.name;
              nuFields.push({ field: f.name, expr: macro this.$name });
              
            default:
              
              switch f.kind {
                case FVar(_, AccNormal | AccCall):
                  f.pos.error('Field must be readonly');
                default:
              }

              var name = f.name,
                  getter = 'get_' + f.name,
                  setter = 'set_' + f.name,
                  ct = f.type.toComplex();
              
              nuFields.push({ field: f.name, expr: macro data.$name });
              
              add(
                if (isWritable(name))
                  macro class {
                    public var $name(get, set):$ct;
                    inline function $getter() return this.__state__.value.$name;
                    inline function $setter(param:$ct) {
                      modify($i{name} = param);
                      return param;
                    }
                  }
                else
                  macro class {
                    public var $name(get, never):$ct;
                    inline function $getter() return this.__state__.value.$name;
                  }
              );
          }
        
        var constr = c.getConstructor((macro function (data) super(data)).getFunction().sure());
        constr.publish();
        constr.onGenerate(function (f) {
          f.expr = macro {
            var data = ${EObjectDecl(nuFields).at()};
            ${f.expr};
          }
        });
          
      case [t]:
        //nothing to be done ... at least for now
      default:
        throw 'invalid usage';
    }
  }
  static function build() {
    return ClassBuilder.run([process]);
  }
  
}