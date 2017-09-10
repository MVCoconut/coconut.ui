class Example4 extends coconut.ui.View<{ value: String }> {
  static public var redraws(default, null) = 0;
  function render() {
    redraws++;
    return @hxx '
      <div class="example4" data-id={""+id}>{value}</div>
    ';
  }
}
