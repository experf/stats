import {
  get,
  keys,
  isObject,
  has,
  isBoolean,
  isNumber,
  isInteger,
} from "lodash-es";
import JSONEditor, { JSONEditorOptions } from "jsoneditor";

import { dig } from "json-schema-tools";

type Options = null | string[] | { startFrom: number; options: string[] };

export function getOptions(
  text: string,
  path: string[],
  input: string,
  editor: JSONEditor
): Options | Promise<Options> {
  console.log("-> getOptions()", { text, path, input });
  const options = (get(editor, "options") as any) as JSONEditorOptions;
  const schema = options.schema as any;

  if (schema === undefined) {
    return null;
  }

  const digPath = path.slice(0, path.length - 1);
  const targets = dig(schema, ...digPath);

  console.log("DUG UP", { digPath, targets });

  const matched = targets.reduce((acc, target) => {
    if (target.properties) {
      return acc.concat(
        Object.keys(target.properties)
          .filter((k) => k.startsWith(text))
      );
    }
    return acc;
  }, [] as string[]);

  console.log("MATCHED", matched);

  return matched;
}
