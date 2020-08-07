package coconut.ui.internal;


#if macro
  import haxe.macro.Context.*;
  using haxe.macro.Tools;
  using tink.MacroApi;
  using tink.CoreApi;
#end

@:pure
abstract Children<RenderResult>(Array<RenderResult>) from Array<RenderResult> {
  public var length(get, never):Int;
    inline function get_length()
      return if (this == null) 0 else this.length;

  @:arrayAccess public inline function get(index:Int)
    return if (this == null) null else this[index];

  @:from static function ofSingle<RenderResult>(r:RenderResult):Children<RenderResult>
    return [r];

  public function concat(that:Array<RenderResult>):Children<RenderResult>
    return if (this == null) that else this.concat(that);

  public function prepend(r:RenderResult):Children<RenderResult>
    return switch [this, r] {
      case [null, null]: null;
      case [v, null]: v;
      case [null, v]: v;
      case [a, b]: [b].concat(a);
    }

  public function append(r:RenderResult):Children<RenderResult>
    return switch [this, r] {
      case [null, null]: null;
      case [v, null]: v;
      case [null, v]: v;
      case [a, b]: a.concat([b]);
    }

  @:from macro static function ofOther(e:haxe.macro.Expr) {

    function childType(t)
      return switch follow(t) {
        case TAbstract(_.get() => { pack: ['coconut', 'ui', 'internal'], name: 'Children' }, [t]):
          Some(t);
        default:
          None;
      }

    var expected = getExpectedType(),
        found = typeExpr(e).t;

    return
      switch childType(expected) {
        case Some(child):
          if (unify(found, child)) {
            var ct = child.toComplex();
            macro @:pos(e.pos) [($e : $ct)];
          }
          else switch childType(found) {
            case Some(t):
              macro @:pos(e.pos) cast $e;
            default:
              e.pos.error('${follow(found).toString()} should be ${expected.toString()}');
          }
        case v:
          e.pos.error('Something went quite horribly wrong. Please isolate and report issue to https://github.com/MVCoconut/coconut.ui/');
      }
  }
}
