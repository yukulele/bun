var symbolFor = Symbol.for;

const lazy = globalThis[symbolFor("Bun.lazy")];
if (!lazy || typeof lazy !== "function") {
  throw new Error(
    "Something went wrong while loading Bun. Expected 'Bun.lazy' to be defined.",
  );
}
