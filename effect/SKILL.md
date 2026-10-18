---
name: effect
description: Guidelines for writing Effect-TS code. Apply when editing or reviewing Effect code.
---

# Effect code guidelines

## Consolidate module imports

When you import multiple symbols from the same module, combine them into one import statement. Do not create separate import statements for the same module.

```typescript
// Wrong
import { Effect } from "effect"
import { pipe } from "effect"
import type { Scope } from "effect"
import { Duration } from "effect"

// Right
import { Duration, Effect, pipe, type Scope } from "effect"
```

## Create effectful functions

Use `Effect.fnUntraced` instead of `Effect.gen` for untraced function construction. Use `Effect.fn` for traced construction when observability is required and maximum performance is not needed.

```typescript
// Wrong
const foo = (input: string) =>
	Effect.gen(function*() {
		const myService = yield* Service
		const result = yield* myService.doWork(input)
		return result
	})

// Right: Untraced construction
const foo = Effect.fnUntraced(function*(input: string) {
	const myService = yield* Service
	const result = yield* myService.doWork(input)
	return result
})

// Right: Traced construction
const foo = Effect.fn("foo")(function*(input: string) {
	const myService = yield* Service
	const result = yield* myService.doWork(input)
	return result
})
```

### When to use Effect.gen

Use `Effect.gen` for service constructors that take no parameters.

```typescript
class MyService extends Context.Service<MyService>()("UniqueServiceKey") {
	make: Effect.gen(function*() {
		// Default implementation
	}),
}
```

## Yield tagged errors directly

Do not wrap tagged errors in `Effect.fail`. `Schema.TaggedError` instances implement Effect's yieldable failure protocol. Yield or return them directly.

### Inside generators

```typescript
// Wrong
if (args.preview && args.map) {
	return yield* Effect.fail(
		new ImageOptimizationError({
			message: "Cannot use --preview and --map together.",
			cause: args,
		}),
	)
}

// Right
if (args.preview && args.map) {
	return yield* new ImageOptimizationError({
		message: "Cannot use --preview and --map together.",
		cause: args,
	})
}
```

### Returning effects from plain functions

Avoid returning effect values from plain functions. Write the function itself as an effect generator.

```typescript
// Wrong
function requireText(value: string, label: string) {
	if (value.trim().length === 0) {
		return Effect.fail(
			new BroadcastInputError({
				message: `${label} is required.`,
				cause: value,
			}),
		)
	}
	return Effect.succeed(value)
}

// Right
const requireText = Effect.fnUntraced(function*(value: string, label: string) {
	if (value.trim().length === 0) {
		return yield* new BroadcastInputError({
			message: `${label} is required.`,
			cause: value,
		})
	}
	return value
})
```

### In catch callbacks

Construct the tagged error and return it directly. Do not wrap the error with `Effect.fail`.

```typescript
// Right
catch: (cause) =>
	new ImageOptimizationError({
		message: `Failed to read image metadata: ${relativeAsset}`,
		cause,
	}),
```

When the callback must return an `Effect`, yield the error inside a generator or return the instance directly.

## Define tagged errors

Use `Schema.TaggedError` with a `cause` field and an optional `message` field when the error faces users:

```typescript
export class ImageOptimizationError extends Schema.TaggedError<ImageOptimizationError>()(
	"ImageOptimizationError",
	{
		message: Schema.String,
		cause: Schema.Defect(),
	},
) {}
```

Export error classes that belong to the public failure channel of a module.

## When to use Effect.fail

Use `Effect.fail` only for untagged failure values, such as strings, defects, or ad-hoc values:

```typescript
if (!exists) return yield* Effect.fail(`Public directory does not exist: ${publicDir}`)
```

For domain errors, define and yield a tagged error schema instead.

## Discriminate tagged errors by tag property

To inspect or catch a tagged error, discriminate on the `_tag` property or use `Effect.catchTag`. Do not use `instanceof` checks. `instanceof` checks fail across package boundaries, module realms, and deserialized error boundaries.

```typescript
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

```typescript
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

```typescript
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

if (value !== undefined && value !== null) {
	processValue(value)
}

// Right
import { Predicate } from "effect"

function getLength(value: unknown): number {
	if (
		Predicate.hasProperty(value, "length") &&
		Predicate.isNumber(value.length)
	) {
		return value.length
	}
	return 0
}

if (Predicate.isNotNullable(value)) {
	processValue(value)
}
```

## Validate unknown data with Schema

Do not validate input data manually without `Schema`. Use `Schema.Struct` or other schema combinators to define the expected model. Validate against that model using `Schema.decodeUnknownEffect`.

```typescript
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

When you define schema properties that represent time or duration values, decode the numeric input into a `Duration` value. This lets callers use the `Duration` module APIs directly instead of handling raw numbers and unit conversions manually.

```typescript
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

## Use HttpClient instead of raw fetch

Use the `HttpClient` module from `effect` for HTTP requests instead of global `fetch`. `HttpClient` provides typed error channels, tracing integration, scoped lifecycle management, and test layer substitution.

```typescript
// Wrong
const fetchUser = (id: string) =>
	Effect.tryPromise({
		try: async () => {
			const res = await fetch(`https://api.example.com/users/${id}`)
			if (!res.ok) {
				throw new Error(`HTTP error: ${res.status}`)
			}
			return await res.json()
		},
		catch: (cause) => new FetchError({ cause }),
	})

// Right
import { Effect, HttpClient, HttpClientResponse } from "effect"

const fetchUser = (id: string) =>
	HttpClient.get(`https://api.example.com/users/${id}`).pipe(
		Effect.andThen(HttpClientResponse.json),
		Effect.scoped,
	)
```

## Use Match for multiple consecutive branches

When you evaluate multiple consecutive branches on the same value or property, use the `Match` module. Use `Match.type` to build a reusable matcher function. Use `Match.value` to match against an existing value in scope. Use `.match()` methods for simple two-branch types like `Exit` or `Option`.

```typescript
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
