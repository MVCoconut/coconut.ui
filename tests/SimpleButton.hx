class SimpleButton extends View {
  @:attribute function onclick():Void;
  @:attribute var children:String;
  
  public var renderCount(default, null) = 0;

  function render() {
    renderCount++;
    return @hxx'
      <button onclick={onclick}>{children}</button>
    ';
  }
}