import simpleGit from "simple-git";
import * as fs from "fs";
import * as os from "os";
import * as path from "path";
import pc from "picocolors";
import { SkeletonOptions } from "./config";

export async function runSkeleton(skeleton: string, target: string, action: "add" | "update", opts: SkeletonOptions): Promise<void> {
	const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "skeleton-"));

	try {
		// 1. Detect the target project's git root, current branch, and origin URL
		const projectGit = simpleGit(process.cwd());

		const targetRoot = (await projectGit.raw(["rev-parse", "--show-toplevel"])).trim();
		const targetBranch = (await projectGit.raw(["branch", "--show-current"])).trim();
		const remotes = await projectGit.getRemotes(true);
		const originRemote = remotes.find((r) => r.name === "origin");

		if (!originRemote || !originRemote.refs.fetch) {
			console.error(pc.red("Error: No origin URL found"));
			process.exit(1);
		}

		const targetOrigin = originRemote.refs.fetch;

		// 2. Warn if current branch equals skeleton branch
		if (targetBranch === opts.branch) {
			console.warn(`${pc.yellow("Warning:")} current branch (${targetBranch}) is equal to skeleton branch (${opts.branch})`);
		}

		// 3. Clone the skeleton origin repo (shallow) into temp dir
		const skeletonRepoDir = path.join(tempDir, "skeleton");
		await simpleGit().clone(opts.repo, skeletonRepoDir, ["--depth=1", "--quiet"]);

		// 4. Validate the requested skeleton exists in the cloned repo
		const skeletonSourceDir = path.join(skeletonRepoDir, skeleton);
		if (!fs.existsSync(skeletonSourceDir)) {
			console.error(`Skeleton ${skeleton} not found in ${opts.repo}`);
			process.exit(1);
		}

		console.log("");

		// 5. Clone (or initialize) the skeleton branch from the target's origin
		const targetBranchDir = path.join(tempDir, "target");
		let targetBranchGit: ReturnType<typeof simpleGit>;

		try {
			await simpleGit().clone(targetOrigin, targetBranchDir, ["-b", opts.branch, "--depth=1", "--quiet"]);
			targetBranchGit = simpleGit(targetBranchDir);
		} catch {
			console.log(`Branch ${pc.yellow(opts.branch)} not found in ${pc.yellow(targetOrigin)}, initializing...`);
			fs.mkdirSync(targetBranchDir, { recursive: true });
			targetBranchGit = simpleGit(targetBranchDir);
			await targetBranchGit.raw(["init", "-b", opts.branch]);
			await targetBranchGit.raw(["commit", "-m", `${opts.commitPrefix}init`, "--allow-empty"]);
			await targetBranchGit.addRemote("origin", targetOrigin);
		}

		// 6. Remove old target files, copy new skeleton files into the skeleton branch
		const targetInBranch = path.join(targetBranchDir, target);
		if (fs.existsSync(targetInBranch)) {
			fs.rmSync(targetInBranch, { recursive: true, force: true });
		}

		// Create parent directory if needed
		fs.mkdirSync(path.dirname(targetInBranch), { recursive: true });

		// Copy skeleton to target
		fs.cpSync(skeletonSourceDir, targetInBranch, { recursive: true });

		await targetBranchGit.add(target);

		// Check if there are staged changes
		const diff = await targetBranchGit.diff(["--cached"]);
		if (!diff.trim()) {
			console.log("No changes");
			return;
		}

		// 7. Commit with appropriate message
		const commitMsg =
			action === "update"
				? `${opts.commitPrefix}update ./${target} from ${opts.repo}#${skeleton}`
				: `${opts.commitPrefix}add ./${target} from ${opts.repo}#${skeleton}`;

		await targetBranchGit.commit(commitMsg);

		// 8. Push the skeleton branch
		await targetBranchGit.raw(["push", "-u", "origin", opts.branch]);

		// 9. Fetch and merge the skeleton branch into the user's current working branch
		const mainProjectGit = simpleGit(targetRoot);
		await mainProjectGit.fetch("origin", opts.branch);

		console.log(`Merging changes from ${pc.yellow(opts.branch)} to ${pc.yellow(targetBranch)}...`);

		await mainProjectGit.checkout(targetBranch);
		await mainProjectGit.raw(["merge", "--no-ff", "--no-edit", "--allow-unrelated-histories", `origin/${opts.branch}`]);
	} finally {
		// 10. Clean up temp directories
		fs.rmSync(tempDir, { recursive: true, force: true });
	}
}
