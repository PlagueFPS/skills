---
name: effect
description: Use when writing or reviewing Effect-TS code.
---

# Effect code guidelines

## Discriminate tagged errors by tag property

To inspect or catch a tagged error, discriminate on the `_tag` property or use `Effect.catchTag`. Do not use `instanceof` checks. `instanceof` checks fail across package boundaries, module realms, and deserialized error boundaries.

```ts
// Wrong
const program = effect.pipe(
	Effect.catchIf(
		(error): error is NotFoundError => error instanceof NotFoundError,
		(error) => Effect.succeed(`Default value for ${error.id}`),
	),
)

if (error instanceof NotFoundError) {
	console.error(error.message)
}

// Right
const program = effect.pipe(
	Effect.catchTag("NotFoundError", (error) =>
		Effect.succeed(`Default value for ${error.id}`),
	),
)

if (error._tag === "NotFoundError") {
	console.error(error.message)
}
```

## Use built-in predicates for module types

When a module provides predicate functions, use them to inspect instances of that module's types. Do not inspect internal discriminant properties manually when a dedicated predicate exists.

```ts
// Wrong
if (result._tag === "Failure") {
	handleFailure(result.failure)
}

if (exit._tag === "Success") {
	handleSuccess(exit.value)
}

// Right
import { Exit, Result } from "effect"

if (Result.isFailure(result)) {
	handleFailure(result.failure)
}

if (Exit.isSuccess(exit)) {
	handleSuccess(exit.value)
}
```

## Use the Predicate module for type guards

To test types or verify object properties, use functions from the `Predicate` module instead of raw equality comparisons or ad-hoc checks.

```ts
// Wrong
function getLength(value: unknown): number {
	if (typeof value === "object" && value !== null && "length" in value) {
		const target = value as { length: unknown }
		if (target.length !== undefined && typeof target.length === "number") {
			return target.length
		}
	}
	return 0
}

// Right
import { Predicate } from "effect"

function getLength(value: unknown): number {
	if (
		Predicate.isNotNullish(value) &&
		Predicate.hasProperty(value, "length") &&
		Predicate.isNumber(value.length)
	) {
		return value.length
	}
	return 0
}
```

## Validate unknown data with Schema

Do not validate input data manually without `Schema`. Use `Schema.Struct` or other schema combinators to define the expected model. Validate against that model using `Schema.decodeUnknownEffect`.

```ts
// Wrong
interface Input {
	value: string
	label: string
}

function processInput(input: Input) {
	if (input.value.trim().length === 0) {
		return Effect.fail("Expected input value to exist.")
	}
}

// Right
import { Effect, Schema } from "effect"

const InputSchema = Schema.Struct({
	value: Schema.NonEmptyString,
	label: Schema.NonEmptyString,
})
type Input = Schema.Schema.Type<typeof InputSchema>

const processInput = Effect.fnUntraced(function*(input: unknown) {
	const validInput = yield* Schema.decodeUnknownEffect(InputSchema)(input)
	return validInput
})
```

## Decode duration properties to Duration values

When you define schema properties that represent time or duration values, decode the numeric input into a `Duration` value. This lets callers use the `Duration` module APIs directly instead of handling raw numbers and time-unit conversions manually.

```ts
// Wrong
import { Duration, Effect, Schema } from "effect"

const ServiceConfigSchema = Schema.Struct({
	retryIntervalMs: Schema.Number,
	timeoutMs: Schema.Number,
})

const waitTimeout = Effect.fnUntraced(function*(
	config: typeof ServiceConfigSchema.Type,
) {
	// Callers must manually convert numbers to Duration values
	yield* Effect.sleep(Duration.millis(config.retryIntervalMs))
})

// Right
import { Duration, Effect, Schema } from "effect"

const ServiceConfigSchema = Schema.Struct({
	// Can also be `Schema.DurationFromNanos`, `Schema.DurationFromString`, check available APIs to find the best match
	retryInterval: Schema.DurationFromMillis,
	timeout: Schema.DurationFromMillis,
})

const waitTimeout = Effect.fnUntraced(function*(
	config: typeof ServiceConfigSchema.Type,
) {
	// Callers receive Duration instances and use Duration APIs directly
	yield* Effect.sleep(config.retryInterval)
})
```

## Use Match for multiple consecutive branches

When you evaluate multiple consecutive branches on the same value or property, use the `Match` module. Use `Match.type` to build a reusable matcher function. Use `Match.value` to match against an existing value in scope. Use `.match()` methods for simple two-branch types like `Exit` or `Option`.

```ts
// Wrong
function getStatusLabel(status: Status): string {
	if (status._tag === "Idle") {
		return "Ready"
	} else if (status._tag === "Pending") {
		return `Loading: ${status.progress}%`
	} else if (status._tag === "Success") {
		return `Completed in ${status.duration}ms`
	} else if (status._tag === "Failure") {
		return `Error: ${status.reason}`
	}
	throw new Error("Unhandled status")
}

// Right: Match.type for a reusable matcher function
import { Match } from "effect"

const getStatusLabel = Match.type<Status>().pipe(
	Match.tag("Idle", () => "Ready"),
	Match.tag("Pending", (s) => `Loading: ${s.progress}%`),
	Match.tag("Success", (s) => `Completed in ${s.duration}ms`),
	Match.tag("Failure", (s) => `Error: ${s.reason}`),
	Match.exhaustive,
)

// Right: Match.value for an existing value in scope
const message = Match.value(status).pipe(
	Match.tag("Idle", () => "Ready"),
	Match.tag("Pending", (s) => `Loading: ${s.progress}%`),
	Match.tag("Success", (s) => `Completed in ${s.duration}ms`),
	Match.tag("Failure", (s) => `Error: ${s.reason}`),
	Match.exhaustive,
)

// Right: Two-branch container matching
const resultText = Exit.match(decodedExit, {
	onSuccess: (value) => `Success: ${value.id}`,
	onFailure: (cause) => `Failure: ${cause}`,
})
```
