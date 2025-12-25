import Lake
open Lake DSL

package chronicle where
  version := v!"0.1.0"

require crucible from ".." / "crucible"
require loom from ".." / "loom"

@[default_target]
lean_lib Chronicle where
  roots := #[`Chronicle]

lean_lib Tests where
  roots := #[`Tests]

@[test_driver]
lean_exe chronicle_tests where
  root := `Tests.Main
