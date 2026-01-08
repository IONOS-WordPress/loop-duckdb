#!/usr/bin/env node

import { mdToPdf } from "md-to-pdf";
import path from "node:path";
import fs from "node:fs";

/*
  this script is called by generate-report/generate-report-md-to-pdf.sh
  It converts the markdown report to PDF using md-to-pdf with custom settings
  to ensure Mermaid diagrams are rendered correctly and do not split across pages.

  its not intended to be run manually
*/

// Path to your local Chrome (Adjust for your OS)
const CHROME_PATH = "/usr/bin/google-chrome-stable";

const markdownFilePath = path.resolve(process.argv[2] || "./generate-report/generate-report.md");

// Extract time period from frontmatter
const markdownContent = fs.readFileSync(markdownFilePath, "utf-8");
const timePeriodMatch = markdownContent.match(/time period:\s*(.+)/);
const timePeriod = timePeriodMatch ? timePeriodMatch[1].trim() : "time period N/A";

const settings = {
  launch_options: {
    executablePath: CHROME_PATH,
    args: ["--no-sandbox", "--allow-file-access-from-files"],
  },

  // 2. Wait for Mermaid JS to finish rendering
  wait_until: "networkidle0",

  // 3. CSS to prevent diagrams from cutting in half
  css: `
        /* Ensure Mermaid containers don't split across pages */
        .mermaid, pre, code {
          page-break-inside: avoid;
          break-inside: avoid;
        }

        /* Force a page break before every H1 (except the first one) */
        h1 {
          page-break-before: always;
          break-before: always;
          page-break-after: avoid;
          break-after: avoid;
        }
        
        h1:first-of-type {
            page-break-before: auto;
            break-before: auto;
        }

        /* Center the diagrams */
        .mermaid {
          display: flex;
          justify-content: center;
          margin: 20px 0;
        }
      `,

  pdf_options: {
    format: "A4",
    margin: { top: "20mm", right: "20mm", bottom: "20mm", left: "20mm" },
    landscape: true,
    //printBackground: true,
    displayHeaderFooter: true,
    outline: true,
    headerTemplate: `<span style="font-size: 10px; margin-left: 20px;">IONOS Loop Usage Report (${timePeriod}) - WordPress Hosting Team</span>`,
    footerTemplate:
      '<div style="font-size: 10px; margin: 0 auto;"><span class="pageNumber"></span> / <span class="totalPages"></span></div>',
  },

  script: [
    {
      content: `
          ${fs.readFileSync(path.resolve("./node_modules/mermaid/dist/mermaid.min.js"), "utf-8")}

          mermaid.initialize({ 
            startOnLoad: false,
            theme: 'default',
            securityLevel: 'loose' 
          });
          (async () => { await mermaid.run(); })();
        `,
    },
  ],
};

try {
  const pdf = await mdToPdf({ content: markdownContent }, settings);
  const pdfFilePath = path.resolve(markdownFilePath.replace(".md", ".pdf"));

  fs.writeFileSync(pdfFilePath, pdf.content);
  console.log(`${pdfFilePath} created successfully.`);
} catch (err) {
  console.error("Error:", err);
}
