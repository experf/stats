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
import JSONEditor from "jsoneditor"

// https://github.com/josdejong/jsoneditor/blob/develop/README.md#use

function onLoad() {
  console.log("JSONEditor", JSONEditor);

  document.querySelectorAll(".JSONEditor").forEach(container => {
    console.log(container);

    const schema_url = container.getAttribute("data-schema");
    if (schema_url) {
      fetch(schema_url)
        .then(rsp => rsp.json())
        .then(schema => {
          new JSONEditor(
            container,
            {
              schema: schema,
              mode: 'tree',
              modes: ['code', 'text', 'tree', 'preview'],
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
