// Pi owns the animation timer and runs it only while the working indicator is visible.
const glyphs = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const palette = ["116;199;236", "137;180;250", "180;190;254", "203;166;247"];
const frames = glyphs.map((glyph, frame) =>
  Array.from(`${glyph} Working`).map((letter, column) =>
    `\x1b[38;2;${palette[(frame + column) % palette.length]}m${letter}`
  ).join("") + "\x1b[39m"
);

export default function (pi) {
  let enabled = true;
  const apply = (ctx) => {
    ctx.ui.setWorkingMessage(enabled ? " " : undefined);
    ctx.ui.setWorkingIndicator(enabled ? { frames, intervalMs: 120 } : undefined);
  };
  pi.on("session_start", (_event, ctx) => apply(ctx));
  pi.registerCommand("flair", {
    description: "Toggle the animated cyan/purple working text: on or off",
    handler: async (args, ctx) => {
      if (args.trim() && !["on", "off"].includes(args.trim())) {
        ctx.ui.notify("Usage: /flair [on|off]", "error");
        return;
      }
      enabled = args.trim() ? args.trim() === "on" : !enabled;
      apply(ctx);
      ctx.ui.notify(`Working animation ${enabled ? "on" : "off"}`, "info");
    }
  });
}
