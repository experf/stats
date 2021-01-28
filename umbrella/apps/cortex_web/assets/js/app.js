// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import JSONEditor from "../vendor/jsoneditor/src/js/JSONEditor"

import { getOptions } from "@/json_editor";

// https://github.com/josdejong/jsoneditor/blob/develop/README.md#use

function loadSchema(uri) {
  return fetch(uri).then(rsp => rsp.json())
}

function onLoad() {
  document.querySelectorAll(".JSONEditor").forEach(container => {

    const schema_url = container.getAttribute("data-schema");
    if (schema_url) {
      fetch(schema_url)
        .then(rsp => rsp.json())
        .then(schema => {
          // https://github.com/josdejong/jsoneditor/blob/master/docs/api.md
          //  getOptions(
          //    text: string,
          //    path: string[],
          //    input: string,
          //    editor: JSONEditor
          //  ): (
          //    null |
          //    string[] |
          //    {startFrom: number, options: string[]} |
          //    Promise<any of those ↑>
          //  )
          // const getOptions = (text, path, input, editor) => {
          //   console.log("getOptions", {
          //     text,
          //     path,
          //     input,
          //     schema: editor.options.schema,
          //   });

          //   if (path.length === 1) {
          //     return Object.keys(schema.properties)
          //       .filter(key => key.startsWith(text));
          //   }

          //   return null;
          // }
          new JSONEditor(
            container,
            {
              name: schema.title,
              schema,
              mode: 'tree',
              modes: ['code', 'text', 'tree', 'preview'],
              autocomplete: {
                getOptions,
              },
            },
            {}
          );
        })
    } else {
      const editor = new JSONEditor(container, {});
    }
  });
}

window.onload = onLoad;
