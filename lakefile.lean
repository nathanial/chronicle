import Lake
open Lake DSL

package chronicle where
  version := v!"0.1.0"

require crucible from git "https://github.com/nathanial/crucible" @ "v0.0.7"
-- Note: Loom integration is provided via Loom.Chronicle (in loom package)

@[default_target]
lean_lib Chronicle where
  roots := #[`Chronicle]

lean_lib Tests where
  roots := #[`Tests]

@[test_driver]
lean_exe chronicle_tests where
  root := `Tests.Main
