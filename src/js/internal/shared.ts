class NotImplementedError extends Error {
  code: string;
  constructor(feature: string, issue?: number) {
    super(
      feature +
        " is not yet implemented in Bun." +
        (issue ? " Track the status & thumbs up the issue: https://github.com/oven-sh/bun/issues/" + issue : ""),
    );
    this.name = "NotImplementedError";
    this.code = "ERR_NOT_IMPLEMENTED";

    // in the definition so that it isn't bundled unless used
    hideFromStack(NotImplementedError);
  }
}

function throwNotImplemented(feature: string, issue?: number): never {
  // in the definition so that it isn't bundled unless used
  hideFromStack(throwNotImplemented);

  throw new NotImplementedError(feature, issue);
}

function hideFromStack(...fns) {
  for (const fn of fns) {
    Object.defineProperty(fn, "name", {
      value: "::bunternal::",
    });
  }
}

/**
 * This utility ensures that old JS code that uses functions for classes still works.
 * Taken from https://github.com/microsoft/vscode/blob/main/src/vs/workbench/api/common/extHostTypes.ts
 */
function es5ClassCompat(target: Function): any {
  const interceptFunctions = {
    apply: function () {
      const args = arguments.length === 1 ? [] : arguments[1];
      return Reflect.construct(target, args, arguments[0].constructor);
    },
    call: function () {
      if (arguments.length === 0) {
        return Reflect.construct(target, []);
      } else {
        const [thisArg, ...restArgs] = arguments;
        return Reflect.construct(target, restArgs, thisArg.constructor);
      }
    },
  };
  return Object.assign(target, interceptFunctions);
}

export default {
  NotImplementedError,
  throwNotImplemented,
  hideFromStack,
  es5ClassCompat,
};
