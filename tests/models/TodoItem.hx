package models;

class TodoItem implements Model {
  @:editable var completed:Bool = false;
  @:editable var description:String;
}