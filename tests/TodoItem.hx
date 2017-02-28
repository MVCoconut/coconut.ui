package ;

class TodoItem implements coconut.data.Model {
  @:editable var completed:Bool = false;
  @:editable var description:String;
}