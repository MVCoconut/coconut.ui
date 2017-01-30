package todomvc.data;

import coconut.data.*;
import tink.pure.List;

class TodoList implements Model {

  @:observable var items:List<TodoItem> = @byDefault null;

  @:transition function add(description:String) 
    items = items.prepend(TodoItem.create(description));
  
  @:transition function delete(item)
    items = items.filter(i => i != item);

  @:transition function clearCompleted() 
    items = items.filter(i => !i.completed);

}