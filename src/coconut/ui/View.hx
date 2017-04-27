package coconut.ui;

@:autoBuild(coconut.ui.macros.ViewBuilder.build())
class View<T> extends BaseView {
  
  function render(data:T):RenderResult throw 'abstract';

}