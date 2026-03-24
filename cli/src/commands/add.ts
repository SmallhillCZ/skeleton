import * as fs from "fs";
import pc from "picocolors";
import { SkeletonOptions } from "../lib/config";
import { runSkeleton } from "../lib/skeleton";

export async function addCommand(skeleton: string, target: string | undefined, opts: SkeletonOptions): Promise<void> {
	const targetDir = target ?? skeleton;

	console.log(
		`Adding skeleton ${pc.yellow(`${opts.repo}#${skeleton}`)} as ${pc.yellow(`./${targetDir}`)} to ${pc.yellow(`origin/${opts.branch}`)} branch`,
	);

	let action: "add" | "update" = "add";

	if (fs.existsSync(`./${targetDir}`)) {
		if (opts.force) {
			console.log("Target already exists, updating...");
			action = "update";
		} else {
			console.error(pc.red(`Error: Cannot add, target ${targetDir} already exists`));
			process.exit(1);
		}
	}

	await runSkeleton(skeleton, targetDir, action, opts);
}
