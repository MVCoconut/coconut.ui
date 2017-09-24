package coconut.ui.macros;

#if macro
import tink.hxx.Node;
import tink.hxx.StringAt;
import tink.hxx.Attribute;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import tink.anon.Macro.*;
import tink.anon.Macro.Part;

using tink.CoreApi;
using tink.MacroApi;
using StringTools;

class Generator {
  
  public function new() {}

  function block(pos:Position, statements:Array<Expr>)
    return statements.toArray(pos);

  function flatten(c:Children) 
    return 
      if (c == null) null;
      else block(c.pos, [for (c in normalize(c.value)) child(c, flatten)]);

  function mangle(attrs:Array<Part>, custom:Array<NamedWith<StringAt, Expr>>, children:Option<Expr>, fields:Map<String, ClassField>) {
    switch custom {
      case []:
      default:
        var pos = custom[0].name.pos;
        attrs = attrs.concat([
          makeAttribute({ value: 'attributes', pos: pos }, EObjectDecl([for (a in custom) { field: a.name.value, expr: a.value }]).at(pos)) 
        ]);
    }

    return {
      attrs: attrs,
      children: children, 
    }
  }

  function liftAsFunction(value:Expr, expected:Type) {
    var ct = expected.toComplex();
    ct = macro : $ct->Void;
    return (
      function () return
        if (!value.is(ct) && (macro function (event) $value).is(ct)) 
          macro function (event) $value
        else value
    ).bounce();
  }

  function makeAttribute(name:StringAt, value:Expr):Part
    return {
      name: switch name.value {
        case 'class': 'className';
        case 'for': 'htmlFor';
        case v: v;
      },
      pos: name.pos,
      getValue: function (expected:Option<Type>) 
        return 
          switch expected {
            case Some(_.getID() => 'tink.state.Observable'):
              (function () return
                if ((macro {
                  function fake<T>(o:tink.state.Observable.ObservableObject<T>) {}
                  fake($value);
                }).typeof().isSuccess())
                  value;
                else 
                  macro @:pos(value.pos) tink.state.Observable.auto(function () return $value)
              ).bounce();
            case Some(_.reduce() => TAbstract(_.get() => { pack: ['tink', 'core'], name: 'Callback' }, [t])):
              liftAsFunction(value, t);
            case Some(_.reduce() => TFun([{ t: t }], _.getID() => 'Void')):
              liftAsFunction(value, t);
            default: 
              value;
          }
    };

  function instantiate(name:StringAt, isClass:Bool, key:Option<Expr>, attr:Expr, children:Option<Expr>)
    return switch key {
      case None:
        invoke(name, isClass, [attr].concat(children.toArray()), name.pos);
      case Some(key):
        if (children != None)
          name.pos.error('Key handling for views with children not yet implemented');

        [name.value, 'forKey'].drill(key.pos).call([key, attr], key.pos);  
    }

  function invoke(name:StringAt, isClass:Bool, args:Array<Expr>, pos:Position)
    return 
      if (isClass)
        name.value.instantiate(args, pos);
      else
        name.value.resolve(pos).call(args, pos);  

  function node(n:Node, pos:Position) 
    return tag(n, getTag(n.name), pos);

  function plain(name:StringAt, isClass:Bool, arg:Expr, pos:Position)
    return 
      switch [isClass, '${name.value}.forData'] {
        case [true, factory] if (factory.resolve().typeof().isSuccess()):
          invoke({ value: factory, pos: name.pos }, false, [arg], pos);
        default:
          invoke(name, isClass, [arg], pos);
      }

  function tag(n:Node, tag:Tag, pos:Position) {
    var lift = false,
        children = null,
        fields = null,
        fieldsType = null;

    switch tag.args {
      case PlainArg(t):
        if (n.children != null) 
          n.name.pos.error('children not allowed on <${n.name.value}/>');
        switch n.attributes {
          case [Splat(e)]:
            return plain(n.name, tag.isClass, e, pos);
          default: 
            n.name.pos.error('<${n.name.value}/> must have exactly one spread and no other attributes');
        }
        
      case JustAttributes(a, t, l):

        lift = l;
        fieldsType = t;
        fields = a;

      case Full(a, t, l, c):

        lift = l;
        fields = a;
        fieldsType = t;
        children = c;      
    }
    
    var splats = [
      for (a in n.attributes) switch a {
        case Splat(e): e;
        default: continue;
      }
    ];
    
    var key = None,
        custom = [];
    
    var attributes = {
      
      var ret:Array<Part> = [];

      function set(name, value) {
        if (name.value == 'key' && !fields.exists('key')) 
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
    var childList = n.children;
    if (children == null && childList != null) {
      for (c in n.children.value)
        switch c.value {
          case CText(_.value.trim() => ''):
          case CNode(n):
            attributes.push({
              pos: n.name.pos,
              name: n.name.value,
              getValue: function (t) return switch t {
                case Some(TFun(requiredArgs, _)):
                  var declaredArgs = [for (a in n.attributes) switch a {
                    case Splat(e): 
                      e.reject(
                        if (e.getIdent().isSuccess())
                          'Use empty attribute instead of spread operator on ident to define argument name'
                        else
                          'Invalid spread on complex property'
                      );
                    case Empty(name):
                      name;
                    case Regular(name, _):
                      name.pos.error('Invalid attribute on complex property');
                  }];
                  var body = flatten(n.children);
                  switch [requiredArgs.length, declaredArgs.length] {
                    case [1, 0]:
                      var ct = requiredArgs[0].t.toComplex();
                      macro function (__data__:$ct) {
                        tink.Anon.splat(__data__);
                        return $body;
                      }
                    case [l, l2] if (l == l2):
                      body.func([for (i in 0...l) { 
                        name: declaredArgs[i].value, 
                        type: requiredArgs[0].t.toComplex(),
                      }]).asExpr();
                      //throw 'not implemented';
                    case [l1, l2]:
                      if (l2 > l1) declaredArgs[l1].pos.error('too many arguments');
                      else n.name.pos.error('not enough arguments');
                  }
                  
                default: 
                  flatten(n.children);
              },
            });
            
          default: 
            c.pos.error('Only named tags allowed here');
        }
      childList = null;
    }

    var mangled = mangle(attributes, custom, switch childList {
      case null: None;
      case v: Some(flatten(v));
    }, fields);

    var attrType = fieldsType.toComplex();

    var obj = 
      mergeParts(
        mangled.attrs, 
        splats,
        function (name) return switch fields[name] {
          case null: Failure(new Error('Superflous field `$name`'));
          case f: Success(Some(f.type));
        },
        attrType
      );

    if (lift)
      obj = macro @:pos(n.name.pos) tink.state.Observable.auto(function ():$attrType return $obj);

    return instantiate(n.name, tag.isClass, key, obj, mangled.children);
  }

  function getTag(name:StringAt) {

    function anon(anon:AnonType, t, lift:Bool, children:Type) {
      var fields = [for (f in anon.fields) f.name => f];
      return 
        if (children == null)
          JustAttributes(fields, t, lift);
        else
          Full(fields, t, lift, children);
    }

    function mk(t:Type, ?children:Type, isClass:Bool)
      return {
        isClass: isClass,
        args: switch t.reduce() {
          case TAbstract(_.get() => { pack: ['tink', 'state'], name: 'Observable'}, [t]):
            switch t.reduce() {
              case TAnonymous(a):
                anon(a.get(), t, true, children);
              default:
                throw 'assert';
            }
          case TAnonymous(a):
            anon(a.get(), t, false, children);
          default:
            PlainArg(t);
        }
      }

    return 
      if (name.value == 'super')
        switch Context.getLocalClass() {
          case null:
            name.pos.error('not a class');
          case cl:
            switch cl.get().superClass {
              case null: 
                name.pos.error('no super class');
              case _.t.get().constructor => c:
                switch c {
                  case null: 
                    name.pos.error('super class has no constructor');
                  case r:
                    switch r.get().type.reduce() {
                      case TFun([{ t: a }, { t: c }], _): 
                        mk(a, c, false);
                      case TFun([{ t: a }], _): 
                        mk(a, false);              
                      case v: 
                        name.pos.error('super class constructor has HXX-incompatible type $v');              
                    }
                }
            }
        }      
      else switch name.value.resolve(name.pos).typeof().sure() {
        case TFun([{ t: a }, { t: c }], _): 
          mk(a, c, false);
        case TFun([{ t: a }], _): 
          mk(a, false);              
        case v: 
          switch '${name.value}.new'.resolve(name.pos).typeof() {
            case Success(TFun([{ t: a }, { t: c }], _)):
              mk(a, c, true);
            case Success(TFun([{ t: a }], _)):
              mk(a, true);
            default:
              name.pos.error('${name.value} has type $v which is unsuitable for HXX');
          }
      }    
  }

  function child(c:Child, flatten:Children->Expr):Expr
    return switch c.value {
      case CExpr(e): e;
      case CText(s): s.value.toExpr(s.pos);
      // case CNode(n): node.bind(n, c.pos).bounce(c.pos);
      case CNode(n): node(n, c.pos);
      case CSwitch(target, cases): 
        ESwitch(target, [for (c in cases) {
          values: c.values,
          guard: c.guard,
          expr: flatten(c.children)
        }], null).at(c.pos);
      case CIf(cond, cons, alt): 
        macro @:pos(c.pos) if ($cond) ${flatten(cons)} else ${if (alt == null) emptyElse() else flatten(alt)};
      case CFor(head, body): 
        flatten({ 
          pos: c.pos, 
          value: [{ pos: c.pos, value: CExpr(macro @:pos(c.pos) for ($head) ${flatten(body)})}] 
        });
    }

  function emptyElse()
    return macro null;

  function normalize(children:Array<Child>) 
    return switch children {
      case null: [];
      default:
        [for (c in children) switch c.value {
          case CText(s):
            switch trimString(s.value) {
              case '': continue;
              case v: { value: CText({ pos: s.pos, value: v }), pos: c.pos };
            }
          default: c;
        }];
    }

  static public function trimString(s:String) {
    
    var pos = 0,
        max = s.length,
        leftNewline = false,
        rightNewline = false;

    while (pos < max) {
      switch s.charCodeAt(pos) {
        case '\n'.code | '\r'.code: leftNewline = true;
        case v:
          if (v > 32) break;
      }
      pos++;
    }
    
    while (max > pos) {
      switch s.charCodeAt(max-1) {
        case '\n'.code | '\r'.code: rightNewline = true;
        case v:
          if (v > 32) break;
      }
      max--;
    }
        
    if (!leftNewline) 
      pos = 0;
    if (!rightNewline)
      max = s.length;
      
    return s.substring(pos, max);
  }  

  public function root(root:Children):Expr
    return switch root.value {
      case []: root.pos.error('Empty HXX');
      case [v]: child(v, this.root);
      case v: v[1].pos.error('Only one element allowed here');
    }

}

enum TagArgs {
  PlainArg(t:Type);
  JustAttributes(fields:Map<String, ClassField>, fieldsType:Type, lift:Bool);
  Full(fields:Map<String, ClassField>, fieldsType:Type, lift:Bool, children:Type);
}

typedef Tag = {
  var isClass(default, never):Bool;
  var args(default, never):TagArgs;
}
#end