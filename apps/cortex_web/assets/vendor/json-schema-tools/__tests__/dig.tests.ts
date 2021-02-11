import OGP_SCHEMA_JSON from "./schemas/ogp.me.schema.json";
import { asSchema, dig } from "../src";
// import { setupLogging, teardownLogging } from "./test_helpers";

// beforeAll(setupLogging);
// afterAll(teardownLogging);

const OGP_SCHEMA = asSchema(OGP_SCHEMA_JSON);

describe(`dig()`, () => {
  it(`gets the zero-level object property`, () => {
    expect(dig(OGP_SCHEMA)).toEqual([OGP_SCHEMA]);
  });
  
  it(`gets a first-level object property`, () => {
    expect(dig(OGP_SCHEMA, "og:title")).toEqual([
      {
        description:
          'The title of your object as it should appear within the graph, e.g., "The Rock".',
        type: "string",
      },
    ]);
  });

  it(`digs through $ref`, () => {
    expect(dig(OGP_SCHEMA, "og:locale")).toEqual([
      {
        description:
          "The locale these tags are marked up in. Of the format language_TERRITORY. Default is en_US.",
        type: "string",
        default: "en_US",
      },
    ]);
  });

  it(`digs through anyOf and $ref`, () => {
    expect(dig(OGP_SCHEMA, "og:image", "alt")).toEqual([
      {
        description: "A description of what is in the image (not a caption). If the page specifies an og:image it should specify og:image:alt.",
        type: "string",
      },
    ])
  });
  
  it(`digs through *multiple* anyOf and $ref`, () => {
    expect(dig(OGP_SCHEMA, "og:image", 0, "url")).toEqual([
      {
        description:
          "A URL for an image which should represent your object within the graph.",
        type: "string",
        format: "uri",
      },
    ])
  });
});
