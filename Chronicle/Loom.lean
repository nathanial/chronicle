/-
  Chronicle.Loom - Loom web framework integration

  Provides middleware for HTTP request logging and ActionM helpers.
-/

import Chronicle.Logger
import Loom

namespace Chronicle.Loom

open Chronicle
open Loom

/-- File logging middleware that writes HTTP requests to a log file -/
def fileLogging (logger : Logger) : Citadel.Middleware := fun handler req => do
  let start ← IO.monoNanosNow
  let resp ← handler req
  let elapsed := (← IO.monoNanosNow) - start
  let ms := elapsed.toFloat / 1000000.0

  let entry : LogEntry := {
    timestamp := start
    level := .info
    message := s!"[{req.method}] {req.path} -> {resp.status.code}"
    path := some req.path
    method := some (ToString.toString req.method)
    statusCode := some resp.status.code.toNat
    durationMs := some ms
  }
  logger.logRequest entry
  pure resp

/-- Combined logging middleware that writes to file and optionally stderr -/
def combinedLogging (logger : Logger) : Citadel.Middleware := fun handler req => do
  let start ← IO.monoNanosNow

  -- Log request start to stderr if enabled
  if logger.config.alsoStderr then
    IO.eprintln s!"[{req.method}] {req.path}"

  let resp ← handler req
  let elapsed := (← IO.monoNanosNow) - start
  let ms := elapsed.toFloat / 1000000.0

  -- Log completion to stderr if enabled
  if logger.config.alsoStderr then
    IO.eprintln s!"  -> {resp.status.code} ({ms.toString.take 6}ms)"

  -- Always log to file
  let entry : LogEntry := {
    timestamp := start
    level := .info
    message := s!"[{req.method}] {req.path} -> {resp.status.code}"
    path := some req.path
    method := some (ToString.toString req.method)
    statusCode := some resp.status.code.toNat
    durationMs := some ms
  }
  logger.logRequest entry
  pure resp

/-- Error-aware logging middleware that logs errors at ERROR level -/
def errorLogging (logger : Logger) : Citadel.Middleware := fun handler req => do
  let start ← IO.monoNanosNow
  let resp ← handler req
  let elapsed := (← IO.monoNanosNow) - start
  let ms := elapsed.toFloat / 1000000.0

  let level := if resp.status.code >= 500 then Level.error
               else if resp.status.code >= 400 then Level.warn
               else Level.info

  let entry : LogEntry := {
    timestamp := start
    level := level
    message := s!"[{req.method}] {req.path} -> {resp.status.code}"
    path := some req.path
    method := some (ToString.toString req.method)
    statusCode := some resp.status.code.toNat
    durationMs := some ms
  }
  logger.logRequest entry
  pure resp

/-! ## ActionM Helpers

These helpers allow logging from within Loom actions.
-/

namespace ActionM

/-- Log at a specific level from within an action -/
def logWithLevel (logger : Logger) (level : Level) (msg : String) : Loom.ActionM Unit := do
  _ ← logger.log level msg
  pure ()

/-- Log at INFO level from within an action -/
def logInfo (logger : Logger) (msg : String) : Loom.ActionM Unit :=
  logWithLevel logger .info msg

/-- Log at DEBUG level from within an action -/
def logDebug (logger : Logger) (msg : String) : Loom.ActionM Unit :=
  logWithLevel logger .debug msg

/-- Log at WARN level from within an action -/
def logWarn (logger : Logger) (msg : String) : Loom.ActionM Unit :=
  logWithLevel logger .warn msg

/-- Log at ERROR level from within an action -/
def logError (logger : Logger) (msg : String) : Loom.ActionM Unit :=
  logWithLevel logger .error msg

/-- Log with context key-value pairs from within an action -/
def logWithContext (logger : Logger) (level : Level) (msg : String)
    (ctx : List (String × String)) : Loom.ActionM Unit := do
  _ ← logger.logWithContext level msg ctx
  pure ()

end ActionM

end Chronicle.Loom
