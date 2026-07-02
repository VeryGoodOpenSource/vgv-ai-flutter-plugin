import mdx from "@astrojs/mdx";
import react from "@astrojs/react";
import starlight from "@astrojs/starlight";
import tailwindcss from "@tailwindcss/vite";
import iubenda from "astro-iubenda";
import { defineConfig } from "astro/config";
import {
  bestPracticesSidebar,
  toolingSidebar,
} from "./src/generated/sidebar.mjs";

// https://astro.build/config
export default defineConfig({
  site: "https://engineering.verygood.ventures",
  integrations: [
    starlight({
      favicon: "./public/favicon.png",
      title: "VGV Engineering",
      head: [
        {
          // Google Analytics configuration
          tag: "script",
          content: `
              (function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
              new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
              j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
              'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
              })(window,document,'script','dataLayer','GTM-KV94CNJ2');
            `,
        },
        {
          // Fix theme flickering on page load.
          // See https://scottwillsey.com/theme-flicker/
          tag: "script",
          attrs: {
            type: "text/javascript",
          },
          content: `
              theme = localStorage.getItem("theme") || "light";
              document.documentElement.dataset.theme = theme;
            `,
        },
        {
          // HubSpot tracking code
          tag: "script",
          attrs: {
            type: "text/javascript",
            id: "hs-script-loader",
            async: true,
            defer: true,
            src: "//js.hs-scripts.com/39662796.js",
          },
        },
      ],
      customCss: [
        // Add tailwind base styles:
        "./src/styles/global.css",
        "./src/styles/vgv_brand.css",
        "./src/styles/theme.css",
        "@fontsource/poppins/100.css",
        "@fontsource/poppins/200.css",
        "@fontsource/poppins/300.css",
        "@fontsource/poppins/400.css",
        "@fontsource/poppins/500.css",
        "@fontsource/poppins/600.css",
        "@fontsource/poppins/700.css",
        "@fontsource/poppins/800.css",
        "@fontsource/poppins/900.css",
      ],
      logo: {
        light: "./src/assets/logos/logo_light.svg",
        dark: "./src/assets/logos/logo_dark.svg",
      },
      sidebar: [
        {
          label: "General Practices",
          autogenerate: {
            directory: "general-practices",
          },
        },
        bestPracticesSidebar,
        {
          label: "Development",
          items: [
            {
              label: "Architecture",
              autogenerate: { directory: "development/architecture" },
            },
            { slug: "development/ci_cd" },
            { slug: "development/code_style" },
            {
              label: "Documentation",
              autogenerate: { directory: "development/documentation" },
            },
            { slug: "development/error_handling" },
            {
              label: "Internationalization",
              autogenerate: {
                directory: "development/internationalization",
              },
            },
            {
              label: "State Management",
              autogenerate: { directory: "development/state_management" },
            },
            {
              label: "Testing",
              autogenerate: { directory: "development/testing" },
            },
            {
              label: "UI",
              autogenerate: { directory: "development/ui" },
            },
          ],
        },
        toolingSidebar,
        {
          label: "Resources",
          autogenerate: {
            directory: "resources",
          },
        },
      ],
      components: {
        TwoColumnContent:
          "./src/components/vgv_two_column_content/vgv-two-column-content.astro",
        Header: "./src/components/vgv_nav/vgv-nav.astro",
        PageFrame: "./src/components/vgv_page/vgv-page-frame.astro",
      },
    }),
    react(),
    mdx(),
    iubenda({
      documentIds: ["20289303"],
      cookieFooter: {
        iubendaOptions: {
          siteId: "2294409",
          cookiePolicyId: "20289303",
          lang: "en",
          banner: {
            position: "bottom",
            backgroundColor: "#020f30",
            textColor: "#ffffff",
            acceptButtonDisplay: true,
            acceptButtonColor: "#6420c6",
            acceptButtonCaptionColor: "#ffffff",
            customizeButtonDisplay: true,
            customizeButtonColor: "#383c46",
            customizeButtonCaptionColor: "#ffffff",
            rejectButtonDisplay: true,
            rejectButtonColor: "#383c46",
            rejectButtonCaptionColor: "#ffffff",
            closeButtonDisplay: false,
            fontSizeBody: "14px",
          },
        },
        googleTagManagerOptions: true,
      },
    }),
  ],
  vite: {
    plugins: [tailwindcss()],
  },
  redirects: {
    "/engineering/philosophy": "/general-practices/philosophy",
    "/engineering/conventions": "/general-practices/conventions",
    "/engineering/services": "/resources/services",
    "/engineering/credits": "/general-practices/credits",
    "/code_review/code_review": "/general-practices/code_review",
    "/security/security_in_mobile_apps":
      "/general-practices/security_in_mobile_apps",
    "/examples/airplane_entertainment_system":
      "/resources/airplane_entertainment_system",
    "/architecture/architecture": "/development/architecture/architecture",
    "/architecture/backend": "https://dart-frog.dev/getting-started",
    "/architecture/barrel_files": "/development/architecture/barrel_files",
    "/automation/ci_cd": "/development/ci_cd",
    "/code_style/code_style": "/development/code_style",
    "/documentation/code_documentation":
      "/development/documentation/code_documentation",
    "/documentation/documentation": "/development/documentation/documentation",
    "/error_handling/error_handling": "/development/error_handling",
    "/internationalization/localization":
      "/development/internationalization/localization",
    "/internationalization/text_directionality":
      "/development/internationalization/text_directionality",
    "/navigation/navigation": "/development/ui/navigation",
    "/state_management/event_transformers":
      "/development/state_management/bloc_event_transformers",
    "/state_management/state_handling":
      "/development/state_management/bloc_state_handling",
    "/testing/testing_overview": "/development/testing/testing_overview",
    "/testing/best_practices": "/development/testing/testing_best_practices",
    "/testing/golden_file_testing": "/development/testing/testing_golden_file",
    "/theming/theming": "/development/ui/theming",
    "/widgets/layouts": "/development/ui/layouts",
    "/widgets/widgets": "/development/ui/widgets",
  },
});
