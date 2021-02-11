// import { get, keys, isObject, has, isBoolean, isNumber, isInteger } from "lodash-es";
import Ajv, { JSONSchemaType } from "ajv";
import { PartialSchema } from "ajv/dist/types/json-schema";
import log from "roarr";

const ajv = new Ajv();

export type Schema = PartialSchema<any>;

export type RefSchema = Schema & { $ref: string };
export type AnyOfSchema = Schema & { anyOf: Schema[] };
export type AllOfSchema = Schema & { allOf: Schema[] };
export type OneOfSchema = Schema & { oneOf: Schema[] };

export function isSchema(x: any): x is Schema {
  return typeof x === "object" && !!ajv.validateSchema(x);
}

export function asSchema(x: any): Schema {
  if (isSchema(x)) {
    return x;
  }
  throw new Error(`Not a JSON schema: ${x}`);
}

export function isRefSchema(schema: Schema): schema is RefSchema {
  return typeof schema.$ref === "string";
}

export function isAnyOfSchema(schema: Schema): schema is AnyOfSchema {
  return Array.isArray(schema.anyOf);
}

export function isAllOfSchema(schema: Schema): schema is AllOfSchema {
  return Array.isArray(schema.allOf);
}

export function isOneOfSchema(schema: Schema): schema is OneOfSchema {
  return Array.isArray(schema.oneOf);
}

export function resolveRef(rootSchema: Schema, schema: Schema): Schema {
  if (!isRefSchema(schema)) {
    return schema;
  }

  const ref = schema.$ref;

  log.debug(`Resolving $ref "%s"`, ref);

  if (ref === "#") {
    return rootSchema;
  }

  if (!ref.startsWith("#/")) {
    throw new Error(`Can only resolve local $ref ("#..."), given "${ref}"`);
  }

  let keyPath = ref.slice(2).split("/");
  let resolved: Schema = rootSchema;

  while (keyPath.length > 0) {
    resolved = resolved[keyPath[0]];
    keyPath = keyPath.slice(1);
  }

  log.debug({ ref, resolved }, `RESOLVED`);

  return mergeOmit("$ref", schema, resolved);
}

function mergeOmit(omit: string, omitFrom: Schema, ...merge: Schema[]): Schema {
  const merged = {} as any;
  for (const [k, v] of Object.entries(omitFrom)) {
    if (k !== omit) {
      merged[k] = v;
    }
  }
  for (const schema of merge) {
    for (const [k, v] of Object.entries(schema)) {
      merged[k] = v;
    }
  }
  return merged as Schema;
}

export function dig(schema: Schema, ...path: Array<string | number>): Schema[] {
  return Array.from(_dig(schema, schema, path));
}

function* _dig(
  rootSchema: Schema,
  schema: Schema,
  path: Array<string | number>
): Generator<Schema> {
  schema = resolveRef(rootSchema, schema);

  if (isAllOfSchema(schema)) {
    schema = mergeOmit(
      "allOf",
      schema,
      // Before merging we need to resolve any `$ref`, least they clobber
      // each other in `{$ref: ...}` form instead of merging their dereferenced
      // objects.
      ...schema.allOf.map((sch) => resolveRef(rootSchema, sch))
    );
  }

  if (isAnyOfSchema(schema)) {
    for (let i = 0; i < schema.anyOf.length; i++) {
      const merged = mergeOmit("anyOf", schema, schema.anyOf[i]);
      log.debug(merged, "Digging `anyOf` item %s", i);
      yield* _dig(rootSchema, merged, path);
    }
    return;
  }

  if (path.length === 0) {
    yield schema;
    return;
  }

  if (typeof schema === "boolean") {
    return;
  }

  const [key, ...rest] = path;

  if (
    typeof key === "number" &&
    Number.isInteger(key) &&
    key >= 0 &&
    schema.type === "array"
  ) {
    yield* _dig(rootSchema, schema.items, rest);
  } else if (
    schema.type === "object" &&
    schema.properties.hasOwnProperty(key)
  ) {
    yield* _dig(rootSchema, schema.properties[key], rest);
  }
}
