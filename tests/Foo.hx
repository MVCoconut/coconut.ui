class Foo implements coconut.data.Model {
  @:editable var foo:Int;
  @:computed var bar:Int = foo;
}