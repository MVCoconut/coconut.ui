package cases;

@:asserts
class Base {
  public function new() {}

  inline function mount(o) {
    Wrapper.mount(o);
  }

  @:after function teardown() {
    Wrapper.clear();
  }
}