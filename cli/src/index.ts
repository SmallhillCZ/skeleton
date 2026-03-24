import { Command, OptionValues } from "commander";
import pc from "picocolors";
import { DEFAULTS } from "./lib/config";
import { addCommand } from "./commands/add";
import { updateCommand } from "./commands/update";

declare const __VERSION__: string;

const program = new Command();

program
	.name("skeleton")
	.version(__VERSION__, "-v, --version")
	.description("@smallhillcz/skeleton")
	.option("-r, --repo <repo>", "Custom skeleton origin repo", DEFAULTS.repo)
	.option("-b, --branch <branch>", "Custom skeleton branch name", DEFAULTS.branch)
	.option("-c, --commit-prefix <prefix>", "Custom commit prefix", DEFAULTS.commitPrefix)
	.option("-f, --force", "Force: allows add when target exists or update when target does not exist");

program
	.command("add")
	.description("Add a skeleton to the project")
	.argument("<skeleton>", "Skeleton name")
	.argument("[target]", "Target directory (default: same as skeleton name)")
	.action(async (skeleton: string, target: string | undefined, _: OptionValues, command: Command) => {
		const parentOpts = command.parent!.opts();
		await addCommand(skeleton, target, {
			repo: parentOpts.repo,
			branch: parentOpts.branch,
			commitPrefix: parentOpts.commitPrefix,
			force: parentOpts.force ?? false,
		}).catch((err: Error) => {
			console.error(pc.red(`Error: ${err.message}`));
			process.exit(1);
		});
	});

program
	.command("update")
	.description("Update an existing skeleton in the project")
	.argument("<skeleton>", "Skeleton name")
	.argument("[target]", "Target directory (default: same as skeleton name)")
	.action(async (skeleton: string, target: string | undefined, _: OptionValues, command: Command) => {
		const parentOpts = command.parent!.opts();
		await updateCommand(skeleton, target, {
			repo: parentOpts.repo,
			branch: parentOpts.branch,
			commitPrefix: parentOpts.commitPrefix,
			force: parentOpts.force ?? false,
		}).catch((err: Error) => {
			console.error(pc.red(`Error: ${err.message}`));
			process.exit(1);
		});
	});

program
	.command("help", { isDefault: false, hidden: true })
	.description("Display help information")
	.action(() => {
		program.help();
	});

program.action(() => {
	program.help({ error: true });
});

program.parse(process.argv);
