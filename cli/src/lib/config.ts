export interface SkeletonOptions {
	repo: string;
	branch: string;
	commitPrefix: string;
	force: boolean;
}

export const DEFAULTS = {
	repo: "https://github.com/smallhillcz/skeletons",
	branch: "skeleton",
	commitPrefix: "chore(skeleton): ",
};
