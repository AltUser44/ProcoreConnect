/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{ts,tsx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: [
          "Inter",
          "ui-sans-serif",
          "system-ui",
          "-apple-system",
          "Segoe UI",
          "Roboto",
          "Helvetica Neue",
          "Arial",
          "sans-serif",
        ],
      },
      colors: {
        // Procore-inspired orange
        brand: {
          50: "#fff4ec",
          100: "#ffe4d3",
          200: "#ffc4a3",
          300: "#ff9b66",
          400: "#ff7a3d",
          500: "#ff5a14",
          600: "#f24f00",
          700: "#c93d00",
          800: "#9a2f00",
          900: "#7a2500",
        },
        // Procore-ish deep navy / charcoal for text and surfaces
        ink: {
          50: "#f6f7f9",
          100: "#eceef2",
          200: "#d4d8e0",
          300: "#aab0bc",
          400: "#7c8497",
          500: "#525a6e",
          600: "#3a4256",
          700: "#2a3145",
          800: "#1c2233",
          900: "#0f1422",
        },
      },
      boxShadow: {
        card: "0 1px 2px rgb(15 20 34 / 0.04), 0 1px 3px rgb(15 20 34 / 0.06)",
      },
    },
  },
  plugins: [],
};
