import type { Config } from 'tailwindcss';

const config: Config = {
  darkMode: 'class',
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        paper: '#F7F7FB',
        ink: '#15152B',
        indigo: {
          DEFAULT: '#5B4FE8',
          50: '#EEEDFD',
          100: '#DEDBFB',
          400: '#8078F0',
          500: '#5B4FE8',
          600: '#4438D6',
          700: '#352AAE',
        },
        coral: {
          DEFAULT: '#FF6B4A',
          100: '#FFE3DB',
          500: '#FF6B4A',
          600: '#E5502F',
        },
        mint: {
          DEFAULT: '#1FA97D',
          100: '#D6F4E9',
          500: '#1FA97D',
          600: '#178B66',
        },
        amber: {
          DEFAULT: '#F5A623',
          100: '#FEF0D6',
          500: '#F5A623',
        },
        midnight: '#12121F',
      },
      fontFamily: {
        display: ['var(--font-space-grotesk)', 'sans-serif'],
        sans: ['var(--font-inter)', 'sans-serif'],
        mono: ['var(--font-jetbrains)', 'monospace'],
      },
      boxShadow: {
        pop: '4px 4px 0px 0px rgba(21,21,43,1)',
        'pop-sm': '2px 2px 0px 0px rgba(21,21,43,1)',
      },
      keyframes: {
        'ring-fill': {
          '0%': { strokeDashoffset: '283' },
        },
      },
    },
  },
  plugins: [require('@tailwindcss/typography')],
};
export default config;
