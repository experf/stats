#!/usr/bin/env node

const traverse = require("json-schema-traverse");
const SCHEMA = require("../../__tests__/schemas/ogp.me.schema.json");

const results = [];

traverse(
  SCHEMA,
  (
    schema,
    jsonPointer,
    _rootSchema, // This is always SCHEMA
    parentJSONPointer,
    parentKeyword,
    parentSchema,
    indexOrProperty
  ) =>
    // results.push({
    //   jsonPointer,
    //   schema,
    //   parentJSONPointer,
    //   parentKeyword,
    //   parentSchema: (parentSchema === SCHEMA ? "ROOT_SCHEMA" : parentSchema),
    //   indexOrProperty,
    // })
    console.log(jsonPointer)
);

// console.log(JSON.stringify(results, null, 2));
