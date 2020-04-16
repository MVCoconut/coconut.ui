package models;

class Foo implements Model {
  @:editable var foo:Int;
  @:computed var bar:Int = foo;
  @:skipCheck @:computed var blub:Array<Int> = [foo];
}