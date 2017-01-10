package coconut.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;

class ModelBuilder { 
  static function process(c:ClassBuilder) {
    switch c.target.superClass.params {
      case [_.reduce() => TAnonymous(_.get().fields => fields)]:  
        
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
                  m.pos.error('fields are currently not allowed');
              }
              var name = f.name;
              nuFields.push({ field: f.name, expr: macro this.$name });
              
            default:
              
              var name = f.name,
                  getter = 'get_' + f.name,
                  ct = f.type.toComplex();
              
              nuFields.push({ field: f.name, expr: macro data.$name });
              
              add(macro class {
                public var $name(get, never):$ct;
                inline function $getter() return this.__state__.value.$name;
              });
          }
          
        c.getConstructor().onGenerate(function (f) {
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