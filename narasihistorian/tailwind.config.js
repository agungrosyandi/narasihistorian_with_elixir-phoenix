// tailwind.config.js (project root)
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./lib/narasihistorian_web/**/*.heex",
    "./lib/narasihistorian_web/**/*.ex",
  ],
  theme: {
    extend: {},
  },
  plugins: [require("./assets/vendor/daisyui.js")],
};
