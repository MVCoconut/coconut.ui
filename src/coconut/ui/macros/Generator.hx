package coconut.ui.macros;

#if macro
import tink.hxx.Node;
import tink.hxx.StringAt;
import tink.hxx.Attribute;
import tink.hxx.Generator;
import haxe.macro.Expr;
import haxe.macro.Type;

using tink.CoreApi;
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

  function makeAttribute(name:StringAt, value:Expr)
    return {
      name: switch name.value {
        case 'class': 'className';
        case 'for': 'htmlFor';
        case v: v;
      },
      pos: name.pos,
      getValue: function (_) 
        return 
          if (!value.typeof().isSuccess() && (macro function (event) $value).typeof().isSuccess()) 
            macro function (event) $value
          else
            value
    };

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
      
      var fields = [for (f in attr.getFields().orUse([])) if (tink.Anon.isPublicField(f)) f.name => f];

      var splats = [
        for (a in n.attributes) switch a {
          case Splat(e): e;
          default: continue;
        }
      ];

      
      var key = None,
          custom = [];

      var attributes = {
        
        var ret = [];

        function set(name, value) {
          if (name.value == 'key') 
            key = Some(value);
          else if (name.value.indexOf('-') == -1) 
            ret.push(makeAttribute(name, value));
          else 
            custom.push(new NamedWith(name, value));
        }
        
        for (a in n.attributes) switch a {
          case Regular(name, value): set(name, value);
          case Empty(name): set(name, macro @:pos(name.pos) true);
          default: continue;
        }

        ret;
      }

      var obj = 
        switch [attributes, splats] {
          case [[], [v]] if (!(attr.reduce().match(TAnonymous(_)))):
            v;
          default:
            tink.Anon.mergeParts(
              attributes, 
              splats,
              function (name) return switch fields[name] {
                case null: Failure(new Error('Superflous field `$name`'));
                case f: Success(Some(f.type));
              },
              attr.toComplex()
            );
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
      case CNode(n): node.bind(n, c.pos).bounce(c.pos);
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

  function instantiate(key:Option<Expr>, attributes:Expr, children:Option<Expr>) {

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