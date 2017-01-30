package todomvc.data;

import coconut.data.*;
import tink.pure.List;
using tink.CoreApi;

class TodoFilter implements Model {
  @:constant var options:List<Named<TodoItem->Bool>> = [
    new Named('All', _ => true),
    new Named('Active', TodoItem.isActive),
    new Named('Completed', TodoItem.isCompleted),
  ];

  @:observable var currentFilter:TodoItem->Bool = options.iterator().next().value;

  public function matches(item:TodoItem):Bool 
    return currentFilter(item);

  @:transition function toggle(filter:TodoItem->Bool) {
    for (o in options)
      if (o.value == filter) currentFilter = filter;
  }
  
  public function isActive(filter:TodoItem->Bool)
    return filter == currentFilter;
}