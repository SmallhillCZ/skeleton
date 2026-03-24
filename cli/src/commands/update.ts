import * as fs from "fs";
import pc from "picocolors";
import { SkeletonOptions } from "../lib/config";
import { runSkeleton } from "../lib/skeleton";

export async function updateCommand(skeleton: string, target: string | undefined, opts: SkeletonOptions): Promise<void> {
	const targetDir = target ?? skeleton;

	console.log(
		`Updating ${pc.yellow(`./${targetDir}`)} in ${pc.yellow(`origin/${opts.branch}`)} branch using skeleton ${pc.yellow(`${opts.repo}#${skeleton}`)}`,
	);

	let action: "add" | "update" = "update";

	if (!fs.existsSync(`./${targetDir}`)) {
		if (opts.force) {
			console.log("Target does not exist, adding...");
			action = "add";
		} else {
			console.error(pc.red(`Error: Cannot update, target ${targetDir} does not exist`));
			process.exit(1);
		}
	}

	await runSkeleton(skeleton, targetDir, action, opts);
}
