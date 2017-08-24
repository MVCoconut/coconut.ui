package coconut.ui.macros;

#if macro
import tink.hxx.Node;
import tink.hxx.Generator;
import haxe.macro.Expr;
import haxe.macro.Type;
using tink.MacroApi;
using StringTools;

class Generator {
  
  var gen:tink.hxx.Generator;

  function new(gen)
    this.gen = gen;

  function flatten(c:Children) 
    return 
      if (c == null) null;
      else gen.flatten(c.pos, [for (c in c.value) child(c)]);

  function node(n:Node, pos:Position) {
    function generate(attr:Type, ?children:Type, ?withNew:Bool) {
      var lift =
        withNew && switch attr.reduce() {
          case TAbstract(_.get() => { module: 'tink.state.Observable', name: 'Observable' }, [v]):
            attr = v;
            true;
          default:
            false;
        }

      var placeholder = {
        var ct = attr.toComplex();
        macro (null : $ct);
      }

      var attributes = [],
          custom = [],
          splats = [];

      var obj = EObjectDecl(attributes).at(n.name.pos);

      function add(name:tink.hxx.StringAt, value:Expr) {
        
        var a = switch name.value {
          case 'class': 'className';
          case v: v;
        }

        if (a.indexOf('-') == -1) {
          attributes.push({ 
            field: a, 
            expr: 
              switch placeholder.field(a, name.pos).typeof().sure() {
                case t: 
                  var ct = t.toComplex();
                  if ((macro ($value : $ct)).typeof().isSuccess())
                    value;
                  else if ((macro (function (_) {} : $ct)).typeof().isSuccess())
                    macro @:pos(value.pos) function (event) $value;
                  else 
                    value;
              }
          });
        }
        else custom.push({ name: name, value: value });
      }

      for (a in n.attributes)
        switch a {
          case Splat(e):
            splats.push(e);
          case Empty(name): 
            add(name, macro true);
          case Regular(name, value):
            if (name.value == 'key') continue;
            add(name, value);
        }

      if (children == null && n.children != null) {
        for (c in n.children.value) {
          switch c.value {
            case CNode(n):
              switch [n.attributes, placeholder.field(n.name.value, n.name.pos).typeof().sure()] {
                case [_, TFun(_, _)]: n.name.pos.errorExpr('No support for functions yet');
                case [[], _]:
                  attributes.push({ 
                    field: n.name.value, 
                    expr: switch n.children {
                      // case null: n.name.pos.error('Empty');
                      case v: flatten(v);
                    } 
                  });
                case [v, t]:
                  (switch v[0] {
                    case Splat(e): e.pos;
                    case Empty(n) | Regular(n, _): n.pos; 
                  }).error('Complex attribute of type $t may not have attributes');
              }
            case CText(_.value.trim().length => 0):
            default: 
              c.pos.error('Complex attribute expected');
          }
        }
      }

      switch [attributes, splats] {
        case [[], [v]] if (!attr.reduce().match(TAnonymous(_))): obj = v;
        case [_, []]:
        case [_, v]: 
          var args = [obj].concat(splats);
          obj = macro tink.hxx.Merge.objects($a{args});
      }

      if (lift)
        obj = {
          var ct = attr.toComplex();
          macro @:pos(n.name.pos) tink.state.Observable.auto(function ():$ct return $obj);
        }

      var args = 
        if (children == null)
          [obj];
        else
          [obj].concat(switch flatten(n.children) {
            case null: [];
            case v: [v];
          });

      return 
        if (withNew) 
          n.name.value.instantiate(args, n.name.pos);
        else 
          macro @:pos(n.name.pos) $p{n.name.value.split('.')}($a{args});
    }

    var type = n.name.value.resolve().typeof().sure();
    
    return switch n.name.value.resolve().typeof().sure() {
      case TFun([{ t: attr }, { t: children }], _): 
        generate(attr, children);              
      case TFun([{ t: attr }], _): 
        generate(attr);              
      case v: 
        switch '${n.name.value}.new'.resolve().typeof() {
          case Success(TFun([{ t: attr }, { t: children }], _)):
            generate(attr, children, true);
          case Success(TFun([{ t: attr }], _)):
            generate(attr, true);
          default:
            n.name.pos.error('${n.name.value} has type $v which is unsuitable for HXX');
        }
    }
  }

  function child(c:Child):Expr
    return switch c.value {
      case CExpr(e): e;
      case CText(s): s.value.toExpr(s.pos);
      case CNode(n): node(n, c.pos);
      case CSwitch(target, cases): 
        ESwitch(target, [for (c in cases) {
          values: c.values,
          guard: c.guard,
          expr: flatten(c.children)
        }], null).at(c.pos);
      case CIf(cond, cons, alt): 
        macro @:pos(c.pos) if ($cond) ${flatten(cons)} else ${flatten(alt)};
      case CFor(head, body): 
        gen.flatten(c.pos, [macro @:pos(c.pos) for ($head) ${flatten(body)}]);
    }

  function root(root:Children):Expr
    return switch root.value {
      case []: root.pos.error('Empty HXX');
      case [v]: child(v);
      case v: v[1].pos.error('Only one element allowed here');
    }

  static public function generate(options, root)
    return new Generator(options).root(root);
}
#end