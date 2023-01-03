import { expect, it, describe } from "bun:test";
import { database } from "bun:sql";

it("database", () => {
  database({
    host: "localhost",
    database: "test123",
    port: 8023,
  });
});
