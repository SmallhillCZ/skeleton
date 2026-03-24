import esbuild from "esbuild";
import { createRequire } from "module";

const require = createRequire(import.meta.url);
const pkg = require("./package.json");

const watch = process.argv.includes("--watch");

const ctx = await esbuild.context({
	entryPoints: ["cli/src/index.ts"],
	outfile: "cli/dist/index.js",
	bundle: true,
	packages: "external",
	platform: "node",
	target: "es2020",
	format: "cjs",
	banner: { js: "#!/usr/bin/env node" },
	define: { __VERSION__: JSON.stringify(pkg.version) },
});

if (watch) {
	await ctx.watch();
	console.log("Watching for changes...");
} else {
	await ctx.rebuild();
	await ctx.dispose();
	console.log("Build complete");
}
