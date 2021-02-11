import JSONEditor, {
  JSONEditorOptions,
  AutoCompleteElementType,
  JSONPath,
} from "jsoneditor";

import { dig } from "json-schema-tools";

type Options = null | string[] | { startFrom: number; options: string[] };

const CLASS_NAME = "form-json-editor";
const ELEMENT_SELECTOR = `.${CLASS_NAME}`;
const INPUT_SELECTOR = `input.${CLASS_NAME}-input`;
const CONTAINER_SELECTOR = `div.${CLASS_NAME}-container`;

const BASE_OPTIONS: JSONEditorOptions = {
  mode: "tree",
  modes: ["code", "text", "tree", "preview"],
};

function needSelector(element: Element, selector: string) {
  const selected = element.querySelector(selector);
  if (selected === null) {
    throw new Error(`Failed to select ${element}[${selector}]`);
  }
  return selected;
}

/**
 * Instantiate a [[JSONEditor]] in each element having the [[CLASS_NAME]] class.
 */
export function onLoad() {
  console.log(`LOADING...`);
  document.querySelectorAll(ELEMENT_SELECTOR).forEach((element) => {
    console.log(`FOUND`, { element });
    init(element);
  });
}

export async function init(element: Element) {
  const schemaUrl = element.getAttribute("data-schema");
  const input = needSelector(element, INPUT_SELECTOR);
  const container = needSelector(element, CONTAINER_SELECTOR) as HTMLElement;

  const options: JSONEditorOptions = {
    ...BASE_OPTIONS,

    onChangeText(jsonString) {
      input.setAttribute("value", jsonString);
    },
  };

  if (schemaUrl) {
    const response = await fetch(schemaUrl);
    const schema = await response.json();

    options.name = schema.title;
    options.schema = schema;
    options.autocomplete = { getOptions };
  }
  
  let json, jsonString;
  if (jsonString = input.getAttribute("value")) {
    json = JSON.parse(jsonString);
  }
  
  const editor = new JSONEditor(container, options, json);

  return { element, editor };
}

/**
 * Find auto-complete options.
 *
 * @param text
 * @param path
 * @param _input
 * @param editor
 *
 * @returns A list of `string` complete options, or `null` when no options are
 *          found.
 */
export function getOptions(
  text: string,
  path: JSONPath,
  _input: AutoCompleteElementType,
  editor: JSONEditor
): null | string[] {
  // console.log("-> getOptions()", { text, path, input });

  const options = (editor as any).options as JSONEditorOptions;
  const schema = options.schema as any;

  if (schema === undefined) {
    return null;
  }

  const digPath = path.slice(0, path.length - 1);
  const targets = dig(schema, ...digPath);

  // console.log("DUG UP", { digPath, targets });

  const matched = targets.reduce((acc, target) => {
    if (target.properties) {
      return acc.concat(
        Object.keys(target.properties).filter((k) => k.startsWith(text))
      );
    }
    return acc;
  }, [] as string[]);

  // console.log("MATCHED", matched);

  return matched;
}
