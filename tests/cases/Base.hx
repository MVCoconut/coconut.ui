package cases;

@:asserts
class Base {
  public function new() {}

  inline function mount(o) {
    Wrapper.mount(o);
  }

  @:after public function teardown() {
    Wrapper.clear();
    return Promise.NOISE;
  }
}