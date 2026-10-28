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

When you evaluate multiple consecutive branches on the same value or property, use the `Match` module. Use `Match.type` to build a reusable matcher function. Use `Match.value` to match against an existing value in scope. Use `.match()` methods for simple pattern matching for types like `Exit`, `Option`, and `Boolean`.

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

const result = condition ? value : otherValue
const messyResult = condition ? value
	: condition2 ? value2
	: condition3 ? value3
	: fallback

// Right: Match.type for a reusable matcher function
import { Match, Exit, Boolean as Bool } from "effect"

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

const result = Bool.match(condition, {
	onFalse: () => otherValue,
	onTrue: () => value
})

const messyResult = Bool.match(condition, {
	onTrue: () => value,
	onFalse: () => Bool.match(condition2, {
		onTrue: () => value2,
		onFalse: () => Bool.match(condition3, {
			onTrue: () => value3,
			onFalse: () => fallback
		})
	})
})
```

## Use combinators when applicable
Effect and its modules ship with powerful combinators that can drastically simplify code making it easier to reason about and write. Before writing a potentially verbose
unit of code, see if certain combinators can help simplify the work you have to do.

```ts
// Wrong - manually implementing retrying with jitter

const withRetries = Effect.fnUntraced(function*(fn, options){
	return yield* Effect.gen(function*(){
		for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      const result = yield* Effect.either(operation(attempt));

      if (Either.isRight(result)) {
        return result.right;
      }

      const error = result.left;

      if (attempt === maxAttempts) {
        return yield* Effect.fail(error);
      }

      const exponentialDelay = baseDelayMs * Math.pow(2, attempt - 1);
      const cappedDelay = Math.min(exponentialDelay, maxDelayMs);
      const jitteredDelay = Math.random() * cappedDelay;

      yield* Effect.logWarning(
        `Attempt ${attempt} failed. Retrying in ${Math.round(jitteredDelay)}ms...`
      );

      // Use Effect's native fiber sleep mechanism
      yield* Effect.sleep(Duration.millis(jitteredDelay));
    }
	})
})
```

```ts
// Right - using built-in combinators to simplify the code

const program = Effect.fnUntraced(function*(userId: string){
	const user = yield* fetchUser(userId)
	return user
}, (effect) => effect.pipe(
	Effect.retry({
		while: Predicate.isTagged("NetworkError"),
		times: 3,
		schedule: Schedule.exponential("200 millis").pipe(
			Schedule.jittered
		)
	})
))
```

## Prefer pipelines over nested functions calls
Always aim to improve code readability and maintainablity by using pipelines for continous transformations instead of nested function calls.

```ts
// Wrong - verbose and hard to read what the function is doing
import { String as Str } from "effect"

const slugify = (text: string) => Str.replace(
		/^-+|-+$/g,
		"",
	)(
		Str.replace(
			/--+/g,
			"-",
		)(
			Str.replace(
				/[\s_]+/g,
				"-",
			)(Str.replace(/[^\w\s-]/g, "")(Str.replace(/&/g, "and")(Str.trim(Str.toLowerCase(text))))),
		),
	)
```

```ts
// Right - less verbose, clear chain of events, and easy to digest
import { String as Str, pipe } from "effect"

const slugify = (text: string) => pipe(
	text,
	Str.toLowerCase,
	Str.trim,
	Str.replace(/&/g, "and"),
	Str.replace(/[^\w\s-]/g, ""),
	Str.replace(/[\s_]+/g, "-"),
	Str.replace(/--+/g, "-"),
	Str.replace(/^-+|-+$/g, "")
)

```

## Prefer Effect native data structures
Instead of using JS globals like `Set`, `Map`, `Object`, or `Boolean`, prefer to use their Effect native equivelent like [`HashSet`](https://effect.website/docs/v4/api/effect/HashSet), [`HashMap`](https://effect.website/docs/v4/api/effect/HashMap), [`Record`](https://effect.website/docs/v4/api/effect/Record), [`Boolean`](https://effect.website/docs/v4/api/effect/Boolean) to take advantage of their powerful APIs/combinators to simplify code, and retain structral equality.

```ts
// Wrong

const map1 = new Map(["a", 1], ["b", 2])
const object1: Record<string, number> = {}

// Returns null or undefined for a missing key and does not have structural equality
const value1 = map1.get("a")
object1["some-key"] = 1
```

```ts
// Right

const map1 = HashMap.make(["a", 1], ["b", 2])
const object1 = Record.empty<string, number>()

// Returns Option.none() for missing values and Option.some(value) for an existing value while retaining structual equality
const value1 = HashMap.get(map1, "a")
// Works with plain JS objects/records as well
const value2 = Record.set(object1, "some-key", 1)
```

> [`MutableHashMap`](https://effect.website/docs/v4/api/effect/MutableHashMap) and [`MutableHashSet`](https://effect.website/docs/v4/api/effect/MutableHashSet) exist but should be avoided unless mutating in place is exactly what is needed for that data for performance or implementation reasons.
