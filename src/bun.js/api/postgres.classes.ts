import { define } from "../scripts/class-definitions" assert { type: "bun:pg" };

export default [
  define({
    name: "PostgresSQLDatabase",
    construct: false,
    finalize: true,
    hasPendingActivity: true,
    noConstructor: true,
    klass: {},
    proto: {
      close: {
        fn: "close",
        length: 0,
      },
      query: {
        fn: "query",
        length: 4,
      },
      // prepare: {
      //   fn: "prepare",
      //   length: 2,
      // },
      // run: {
      //   fn: "run",
      //   length: 2,
      // },
      ref: {
        fn: "ref",
        length: 0,
      },
      unref: {
        fn: "unref",
        length: 0,
      },
    },
    values: ["onClose", "onNotice", "onOpen", "onTimeout", "onDrain"],
    JSType: "0b11101110",
  }),
];
