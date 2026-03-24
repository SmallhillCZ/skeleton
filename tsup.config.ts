import { defineConfig } from "tsup";
import { readFileSync } from "fs";

const pkg = JSON.parse(readFileSync("./package.json", "utf8"));

export default defineConfig({
	entry: { index: "cli/src/index.ts" },
	outDir: "cli/dist",
	format: ["cjs"],
	clean: true,
	banner: { js: "#!/usr/bin/env node" },
	define: {
		__VERSION__: JSON.stringify(pkg.version),
	},
});
