package models;

class ListModel<T> implements Model {
  @:editable var items:List<T>;
}
